# Plan: GET /api/todos 쿼리 최적화 (P0)

## 목표
GET `/api/todos` 의 cache miss 경로 latency 를 약 195ms → **100ms 이하** 로 끌어내린다.

## 컨텍스트 (왜 하는지)

- TODO 생성 직후 사용자가 "버벅임" 보고. 분석 결과:
  - POST `/api/todos` 자체는 정상 (로컬 BE → dev DB+Redis 측정 p50 143ms / max 168ms / Prometheus max 165ms).
  - POST 1건당 후속 GET 4건 (`/api/todos`, `/api/todos/calendar`, `/api/characters/me`, `/api/users/me/streak`) 가 ~500ms 간격으로 호출 → 누적 체감 ~2초.
  - 그 중 GET `/api/todos` 만 cache evict 의 직접 영향. cache hit 시 75ms, cache miss 시 195ms (2.5배).
  - Redis cache hit 비율 약 48% (로컬 측정). 운영 측정은 `P0-pre` sub-task 에서 별도 검증 중.
- write-through / cache 전략 변경은 **거부 결정**. 시니어 표준 (cache-aside + invalidate) 유지.
- 진짜 가치는 사용자 체감 1초 절감이 아니라 **DB 부하 절감 + p95 안정화**.

## 환경

- 로컬 BE 부팅: `set -a && source env/.env.dev && set +a && ./gradlew bootRun`
  - port 8080
  - dev MariaDB 연동 (env/.env.dev 의 DB_HOST/USER/PASSWORD)
  - dev Redis 연동 (168.107.48.80:6379)
- 토큰: 만료 시 사용자에게 새 토큰 요청. 또는 `POST /api/auth/login` 으로 자체 발급 가능 (test 계정이 dev DB 에 있는 경우).
- dev DB 직접 접속: env/.env.dev 의 DB credential 로 mariadb client 가능

## 작업 단계

### S1 — SQL 캡처
다음 중 택 1:
- 로컬 `application-local.yml` 또는 ENV 로 `JPA_SHOW_SQL=true` `LOG_HIBERNATE_SQL=DEBUG` 임시 활성 (P3 가 PR1 에서 머지되면 ENV 한 줄로 가능)
- 또는 testRuntimeOnly 로 p6spy 일시 도입 (운영 영향 0)

GET `/api/todos` 1회 호출 → 발생 SQL 모두 캡처.

### S2 — EXPLAIN
캡처된 각 SQL 에 대해 dev DB MariaDB EXPLAIN 실행:
- 인덱스 사용 / 풀스캔 / 임시테이블 / filesort 여부
- WHERE 절 후보 컬럼: `user_id`, `is_deleted`, `status`, `type`, `start_date`, `end_date`
- 정렬 / GROUP BY 컬럼

### S3 — N+1 진단
`spring.jpa.open-in-view=true` 환경에서 응답 직렬화 중 lazy 관계 추가 쿼리 발생 여부 확인.
후보 lazy 관계: `Category`, `Alert`, `MasterTodo`, snooze count.
`TodoListResp.from(...)` / `TodoDetailResp.from(...)` 등 매핑 코드 점검.

### S4 — 변경 적용
가장 작은 변경으로 가장 큰 효과를 노린다:
- 인덱스 누락 → 추가 (DDL 마이그레이션. 본 프로젝트는 Flyway/Liquibase 미사용. `JPA_DDL_AUTO=update` 로 운영 중. 인덱스만 별도 SQL 파일로 두거나, Entity `@Table(indexes=...)` 로 자동 생성)
- N+1 발견 → fetch join (`@Query("SELECT t FROM Todo t JOIN FETCH t.category ...")`) 또는 `@EntityGraph`
- 응답 데이터 과도 → DTO projection (interface 또는 record-based)
- snooze count 가 별도 query 면 left join + count 로 통합 가능한지 검토

### S5 — 측정
1. BE 재시작 → Redis 캐시 비우기 (`redis-cli -h 168.107.48.80 FLUSHDB` 또는 `DEL` 패턴 — **운영 영향 주의**, 가능하면 user 21 의 키만)
2. GET `/api/todos` 5회 측정 (curl `%{time_total}`)
3. **목표**: p95 100ms 이하 (로컬 BE → dev DB 환경 기준 — 네트워크 RTT 약 30~40ms 포함이므로 SQL 단독 60~70ms)
4. Prometheus `http_server_requests_seconds_max` 비교

### S6 — PR 생성
- 브랜치: `be/perf/get-todos-query-optimization` (또는 jira 키 포함 `be/perf/<jira>/...`)
- MR 제목: `[BE : perf] GET /api/todos 쿼리 최적화 (P0)`
- MR 본문: `~/.claude/projects/-home-cbkjh0225-project-ssafyTodo-S14P31D107/templates/mr-body.md` 양식
- 커밋 컨벤션: 기존 형식 (`docs : ...`, `feat : ...`, `test : ...`, `chore : ...` + JIRA 키)
- 작업 후 plan 파일을 `docs/plans/completed_plans/2026-05-06-get-todos-query-optimization.md` 로 이동 (Codex 가 직접 또는 Claude head agent 가)

## 작업 범위 밖 (절대 금지)

- ❌ `@CacheEvict` → `@CachePut` / write-through 변경 (의사결정 끝남)
- ❌ `spring.jpa.open-in-view=false` 변경 (회귀 위험. 별도 작업으로 분리)
- ❌ FE 코드 수정
- ❌ 134초 hang 추적 (BE 무관 확정: Prometheus max=165ms 가 증거)
- ❌ POST `/api/todos` 응답 스키마 변경 (이미 풍부함, FE 활용 합의는 별도 P4)

## 산출물

1. PR (변경 코드 + 회귀 테스트)
2. EXPLAIN 결과 (변경 전 / 후) — PR 본문에 포함
3. 측정 비교 (p50 / p95 변경 전·후) — PR 본문
4. 발견한 부수 이슈는 별도 sub-task 후보로 보고:
   - 후보: SCAN-based evict 비용 (DEL 1회당 SCAN 5.8회 관측) — `CacheEvictHelper` 의 SCAN 패턴 → KEYS 또는 user-scoped 캐시 키 구조 재검토

## docs 갱신

본 변경이 다음 docs 에 영향 → 같은 PR 에 갱신 (CLAUDE.md 규칙):
- `docs/architecture/caching.md` (cache miss 경로 latency 변화)
- 필요 시 `docs/api/` 의 응답 형식 (DTO projection 도입 시)

## 관련 메모리 / 컨벤션

- 응답 포맷: `docs/api/response-format.md`
- 에러 코드: `docs/api/error-codes.md`
- DDL 변경 정책: 현재 Flyway/Liquibase 없음 → JPA `ddl-auto=update` 로 자동. 인덱스 추가는 entity `@Table(indexes=@Index(...))` 가 가장 안전.

## 변경 이력

- 2026-05-06: 작성 (Claude head agent)
