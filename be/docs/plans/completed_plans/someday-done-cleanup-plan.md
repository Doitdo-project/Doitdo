# SOMEDAY DONE 당일 노출 정책 — 구현 plan

## 배경
- `type=SOMEDAY` ("언젠가 할 일") TODO 가 `status=DONE` 으로 처리돼도 BE 응답에 영구 누적되어 화면에 계속 노출되는 문제.
- 일반 날짜 기반 TODO 는 FE 측 client-side 필터로 DONE 이 가려지지만, SOMEDAY 는 그 필터에서 빠져 항상 노출됨.
- 사용자 결정: **BE 측에서 일관되게 처리**한다. 다만 정책은 **SOMEDAY 한정** 으로 적용하고, 다른 TODO 의 응답 동작은 변경하지 않는다.

## 결정된 정책

| # | 항목 | 값 |
|---|---|---|
| 1 | 신규 컬럼 | `done_date DATE NULL` (Todo 엔티티 필드명: `doneDate`) |
| 2 | 세팅 시점 | `changeStatus()` 에서 `before != DONE && after == DONE` 일 때 `LocalDate.now(ZoneId.of("Asia/Seoul"))` 세팅 |
| 3 | 되돌리기 | `before == DONE && after != DONE` 일 때 `done_date = NULL` 로 클리어 |
| 4 | 필터 조건 | `NOT (type=SOMEDAY AND status=DONE AND done_date < today_kst)` <br/>(NULL 은 통과 — 기존 데이터 자연 노출 유지) |
| 5 | 적용 범위 | **`GET /api/todos` 만**. `GET /api/todos/search`, `GET /api/todos/calendar` 는 미적용 (검색/캘린더는 의도된 회수) |
| 6 | 기존 데이터 백필 | **안 함**. 기존 SOMEDAY DONE 들은 `done_date=NULL` 로 남고 필터 통과 → 영구 노출 유지 (정책 적용 전 데이터는 줬다 뺐지 않음) |

## 구현 범위

### 1) 마이그레이션 (DDL)
파일: `docs/ops/migrations/2026-04-someday-done-date.sql`
```sql
ALTER TABLE todos
  ADD COLUMN done_date DATE NULL;
```
- 인덱스: 추가 안 함 (필터 조합조건이 selective 하지 않음, 우선 미적용)
- 컬럼명: `done_date` (snake_case)

### 2) 엔티티 (Todo.java)
- 필드 추가:
  ```java
  @Column(name = "done_date")
  private LocalDate doneDate;
  ```
- `changeStatus(TodoStatus next)` 시그니처 유지하되 내부 로직 추가:
  - `next == DONE && this.status != DONE` → `this.doneDate = LocalDate.now(ZoneId.of("Asia/Seoul"))`
  - `next != DONE && this.status == DONE` → `this.doneDate = null`
  - 그 외 → `doneDate` 변경 없음

> **이유**: changeStatus 호출자는 이미 service 단에 흩어져 있으므로 내부 가드가 가장 안전.

### 3) Specification (TodoSpecifications.java)
- 새 메서드:
  ```java
  /**
   * SOMEDAY DONE 의 노출 만료 처리.
   * NOT (type=SOMEDAY AND status=DONE AND done_date < today)
   * NULL 은 통과 (기존 데이터 노출 유지).
   */
  public static Specification<Todo> excludeExpiredSomedayDone(LocalDate today) { ... }
  ```
- 적용은 service 단에서 추가 (spec 자체에 today 주입).

### 4) 서비스 (TodoServiceImpl.list)
- `list(...)` 의 spec 체인에만 추가:
  ```java
  Specification<Todo> spec = TodoSpecifications.ownerAndActive(userId)
      .and(TodoSpecifications.byView(req.view(), baseDate))
      .and(TodoSpecifications.byStatus(req.status()))
      .and(TodoSpecifications.byCategoryId(categoryId))
      .and(TodoSpecifications.byType(req.type()))
      .and(TodoSpecifications.byKeyword(req.q()))
      .and(TodoSpecifications.excludeExpiredSomedayDone(LocalDate.now(ZoneId.of("Asia/Seoul"))));  // ← NEW
  ```
- `search(...)`, `calendar(...)` 는 변경 없음.

### 5) 테스트
파일: `src/test/java/com/doitdo/domain/todo/.../TodoSpecificationsTest.java` 또는 통합 테스트
- 케이스:
  - SOMEDAY + DONE + done_date == today → **노출**
  - SOMEDAY + DONE + done_date < today (어제) → **제외**
  - SOMEDAY + DONE + done_date IS NULL → **노출** (기존 데이터)
  - SOMEDAY + TODO → 노출
  - SOMEDAY + IN_PROGRESS → 노출
  - NORMAL + DONE + done_date < today → **노출** (정책 미적용)
  - PERIOD + DONE + done_date < today → **노출** (정책 미적용)
- changeStatus 테스트:
  - TODO → DONE → doneDate = today
  - IN_PROGRESS → DONE → doneDate = today
  - DONE → TODO → doneDate = null
  - DONE → DONE → doneDate 유지 (no-op)

### 6) 문서 갱신 (CLAUDE.md 의 "docs/ 갱신 규칙" 적용)
- `docs/architecture/overview.md` — 정책 한 줄 명시 (선택)
- `docs/api/swagger.md` — TODO 리스트 응답이 SOMEDAY 만료분 제외함을 주석으로 명시
- 신규 정책 문서 1장 권장: `docs/policies/someday-done-cleanup.md` (간단)

### 7) Notion SSOT
- TODO 도메인 정책 페이지가 노션에 있다면 같은 PR 안에서 갱신.
- 없으면 사용자에게 어느 페이지에 추가할지 물음 (추가 후속).

## 검증

### 로컬 검증
1. `./gradlew test` — 단위/통합 테스트 PASS
2. 로컬 부팅 후 curl:
   ```bash
   # 어제 DONE 한 SOMEDAY 가 어제 응답엔 보이지만 오늘 응답엔 안 보이는지
   ```
3. 기존 SOMEDAY DONE (done_date=NULL) 이 여전히 응답에 보이는지

### 6축 평가
- 기능 / 정책 일치 / 마이그레이션 안전성 / 테스트 / 코드 품질 / 문서 갱신

## 작업 단계
1. `dev` 에서 신규 브랜치 `be/feat/someday-done-cleanup` 생성
2. 마이그레이션 SQL 추가
3. Entity 변경 (Todo.java)
4. Specification 추가
5. Service 수정
6. 테스트 추가
7. 문서 갱신
8. 로컬 부팅 + curl 검증
9. 커밋(들) 후 MR

## 위험 / 주의사항
- `changeStatus` 호출 경로가 여러 곳일 수 있음 — entity 메서드 내부에서 가드해 누락 방지
- 시간대: 서버가 UTC 환경이면 `LocalDate.now()` 는 UTC 기준 → 반드시 `ZoneId.of("Asia/Seoul")` 명시
- 백필 안 함 → 기존 데이터는 일부러 영구 노출 유지 (정책 적용 전 데이터 보호)
- 관련 인덱스 영향 없음 (필터 추가 조건은 row 수 작은 SOMEDAY+DONE 만 영향)
