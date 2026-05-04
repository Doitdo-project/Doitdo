# Redis 캐싱 도입 (S14P31D107-490) — 실행 계획

> 본 문서는 Codex 위임의 SSOT. 구현 / 테스트 / 문서까지 본 문서 기준으로 진행한다.

---

## 0. 배경

- 운영 docker-compose 에 `redis:7-alpine` 컨테이너가 이미 떠 있고 (`doitdo-redis`, AOF 영속화, 6379 포트, app 의 `depends_on` 와이어링 완료) `.env.dev` 에 `REDIS_HOST=redis` `REDIS_PORT=6379` `SPRING_DATA_REDIS_HOST=redis` `SPRING_DATA_REDIS_PORT=6379` 가 박혀 있다.
- BE 코드 / 설정 / 의존성에는 redis 흔적 0건. 본 작업은 그 갭을 채운다.
- 이슈 본문이 단문이라 정책은 본 plan 에서 확정한다.

## 1. 목표 (인수 기준)

홈 화면 사용자 동선 (다마고치 + 오늘의 할 일 + 언젠가 할 일) 의 응답 시간이 redis cache hit 시 DB 조회 없이 반환되어야 한다. 변경(mutation) 발생 시 cache 가 즉시 evict 되어 stale data 가 노출되지 않아야 한다.

구체 합격 조건:

- (A) `GET /api/todos?view=today`, `GET /api/todos?type=SOMEDAY`, `GET /api/characters/me` 가 두 번째 호출 시 cache hit (DB SQL 미발행).
- (B) TODO mutation 6종 (`create / update / delete / changeStatus / changePriority / snooze`) 호출 후 다음 조회는 fresh data.
- (C) `changeStatus(→DONE)` 호출 후 다음 `GET /api/characters/me` 는 EXP 변동 반영된 fresh data.
- (D) 카테고리 CUD 후 `GET /api/categories` + `GET /api/todos?view=today` 둘 다 fresh data.
- (E) `RecurrenceMaterializeScheduler` 자정 배치 실행 후 영향받은 사용자 `todos:list` cache 가 evict 됨.
- (F) SOMEDAY DONE 자동 만료 (491 정책) 가 자정 넘어 정상 적용 — 키에 날짜 포함 패턴으로 자연 처리.
- (G) 사용자 A 의 mutation 이 사용자 B 의 cache 를 건드리지 않음 (격리).

---

## 2. 캐시 키 / TTL 디자인

### 2.1 캐시 키 (날짜 포함 패턴)

| Cache name | 키 (Spring SpEL) | 예시 redis 키 | TTL |
|---|---|---|---|
| `todos:list` | `#userId + ':today:' + (#req.date ?: T(java.time.LocalDate).now(T(java.time.ZoneId).of('Asia/Seoul')))` | `todos:list::123:today:2026-05-04` | 1h |
| `todos:list` | `#userId + ':someday:' + (#req.date ?: T(java.time.LocalDate).now(...))` | `todos:list::123:someday:2026-05-04` | 1h |
| `todos:list` | `#userId + ':' + #req.hashCode() + ':' + effectiveDate` (그 외 view/필터 조합) | `todos:list::123:abcd1234:2026-05-04` | 1h |
| `todos:item` | `#userId + ':' + #todoId` | `todos:item::123:42` | 5min |
| `tamagotchi:current` | `#userId` | `tamagotchi:current::123` | 30min |
| `categories` | `#userId` | `categories::123` | 1h |

> **날짜 포함 패턴의 효과**: 자정 지나면 키가 자동으로 새 날짜로 옮겨가서 SOMEDAY DONE 자동 만료 정책(491)이 별도 evict 없이 자연 적용. 어제 키는 TTL 1h 후 자연 삭제.

### 2.2 직렬화 / 정책

- **Value serializer**: `GenericJackson2JsonRedisSerializer` — 스키마 변경 내성 + 운영 inspect 가능 + JavaTimeModule 등록 (LocalDate / Instant 직렬화).
- **Key serializer**: `StringRedisSerializer`.
- **Null caching**: 비활성 (`disableCachingNullValues()`).
- **Cache name prefix**: `RedisCacheConfiguration.computePrefixWith(name -> name + "::")` — 각 cache name 별로 namespace 분리.
- **Use key prefix**: enable.

---

## 3. Evict 매트릭스

| Mutation | Evict 대상 | 도구 |
|---|---|---|
| TODO `create` / `update` / `delete` / `changePriority` / `snooze` | `todos:list:{userId}:*` (사용자 단위 패턴 evict) + (해당 todoId 있으면) `todos:item:{userId}:{todoId}` | `CacheEvictHelper.evictUserTodos(userId)` + `CacheEvictHelper.evictTodoItem(userId, todoId)` |
| TODO `changeStatus` | 위 + `tamagotchi:current:{userId}` (DONE 전이 시 EXP 변동) | helper 추가 호출 |
| 카테고리 `create` / `update` / `delete` | `categories:{userId}` + `todos:list:{userId}:*` (categoryName 필터 영향) | `CacheEvictHelper.evictCategories(userId)` + `CacheEvictHelper.evictUserTodos(userId)` |
| 다마고치 `updateName` / `hatch` / `evolve` / `farewell` | `tamagotchi:current:{userId}` | `CacheEvictHelper.evictTamagotchiCurrent(userId)` |
| `RecurrenceMaterializeScheduler.run()` | 영향받은 사용자 `todos:list:{userId}:*` (대량) | helper batch evict |
| `TodoCompletionExpListener` (DONE 후속 EXP 가산) | `tamagotchi:current:{userId}` (단, `changeStatus` 단계에서 이미 evict 했다면 중복 무해) | helper |

### 3.1 Wildcard evict — `CacheEvictHelper`

Spring `@CacheEvict(allEntries=true)` 는 cache name 전체를 비워 다른 사용자 키까지 날아간다. 사용자 단위 패턴 evict 는 별도 헬퍼가 필요.

```java
@Component
@RequiredArgsConstructor
public class CacheEvictHelper {
    private final StringRedisTemplate redisTemplate;

    public void evictUserTodos(Long userId) {
        evictByPattern("todos:list::" + userId + ":*");
    }

    public void evictTodoItem(Long userId, Long todoId) {
        redisTemplate.delete("todos:item::" + userId + ":" + todoId);
    }

    public void evictTamagotchiCurrent(Long userId) {
        redisTemplate.delete("tamagotchi:current::" + userId);
    }

    public void evictCategories(Long userId) {
        redisTemplate.delete("categories::" + userId);
    }

    private void evictByPattern(String pattern) {
        try (Cursor<String> cursor = redisTemplate.scan(
                ScanOptions.scanOptions().match(pattern).count(100).build())) {
            cursor.forEachRemaining(redisTemplate::delete);
        }
    }
}
```

> `KEYS` 명령은 운영에서 블로킹 — `SCAN` 사용 필수.
> `redisTemplate.delete(key)` 는 단건. 패턴 evict 만 SCAN + delete 루프.

---

## 4. 단계별 작업 (S1~S6)

### S1. 인프라 정합성 (env / docker / docs)

- `be/env/.env.dev.example`, `be/env/.env.prod.example`, `be/env/.env.local` 에 다음 4줄 추가:
  ```
  REDIS_HOST=redis
  REDIS_PORT=6379
  SPRING_DATA_REDIS_HOST=redis
  SPRING_DATA_REDIS_PORT=6379
  ```
  - `.env.local` 의 경우 host 는 `localhost` 로 (로컬 직접 띄울 때).

> 운영 `docker-compose.local.yml` 자체는 `.gitignore` 처리되어 있음. 이번 작업에서는 BE 만 손대고 인프라 파일은 건드리지 않는다 (인프라 담당 영역).

### S2. Gradle 의존성 + Spring 설정

- `build.gradle` (be 디렉토리):
  ```gradle
  implementation 'org.springframework.boot:spring-boot-starter-data-redis'
  implementation 'org.springframework.boot:spring-boot-starter-cache'
  ```
- `src/main/resources/application.yml` 공통:
  ```yaml
  spring:
    data:
      redis:
        host: ${SPRING_DATA_REDIS_HOST:localhost}
        port: ${SPRING_DATA_REDIS_PORT:6379}
        timeout: 2s
    cache:
      type: redis
  ```
- `application-test.yml`: 캐시 무효화 — `spring.cache.type: none` (기존 단위 테스트가 캐시 영향 받지 않도록).

### S3. RedisConfig + CacheEvictHelper

- `com.doitdo.global.config.RedisConfig`:
  - `@Configuration`, `@EnableCaching`
  - `RedisCacheManager` 빈 — cache name 별 TTL 매핑 (`todos:list`=1h, `todos:item`=5min, `tamagotchi:current`=30min, `categories`=1h).
  - `RedisCacheConfiguration` 디폴트 + `JavaTimeModule` 등록된 `ObjectMapper` 기반 `GenericJackson2JsonRedisSerializer`.
  - prefix: `name -> name + "::"`.
  - null caching disable.
- `com.doitdo.global.cache.CacheEvictHelper` (위 § 3.1 참고).

### S4. `@Cacheable` 적용

- `TodoServiceImpl.list(Long userId, TodoListReq req)`:
  - cache name `todos:list`, key SpEL: `#userId + ':' + (#req.view ?: 'all') + ':' + (#req.type ?: 'X') + ':' + (#req.status ?: 'X') + ':' + (#req.category ?: 'X') + ':' + (#req.sort ?: 'X') + ':' + (#req.q != null ? #req.q.hashCode() : 'X') + ':' + (#req.date != null ? #req.date : T(java.time.LocalDate).now(T(java.time.ZoneId).of('Asia/Seoul')))`.
  - `unless = "#result == null"`.
- `TodoServiceImpl.getOne(Long userId, Long todoId)` (시그니처 확인 후 적용): cache `todos:item`, key `#userId + ':' + #todoId`.
- `TamagotchiServiceImpl.getCurrentCharacter(...)` 또는 동등 메서드: cache `tamagotchi:current`, key `#userId`.
- `CategoryServiceImpl.list(Long userId)`: cache `categories`, key `#userId`.

### S5. Evict 와이어링

- TODO 6 mutation 메서드 끝부분 (또는 `@Transactional` AFTER_COMMIT 훅 권장) 에서 `cacheEvictHelper.evictUserTodos(userId)` 호출.
  - `update`/`delete` 는 단건 `todos:item` 도 같이 evict.
  - `changeStatus` 는 추가로 `evictTamagotchiCurrent(userId)`.
- 카테고리 CUD 메서드: `evictCategories(userId)` + `evictUserTodos(userId)`.
- 다마고치 updateName / hatch / evolve / farewell: `evictTamagotchiCurrent(userId)`.
- `RecurrenceMaterializeScheduler.materialize(...)`: 인스턴스가 생성된 사용자 set 모아 batch evict.
- `TodoCompletionExpListener` 의 EXP 가산 후: `evictTamagotchiCurrent(userId)` (changeStatus 에서 이미 evict 했어도 중복 무해).

> **Self-invocation 함정 주의**: 같은 클래스 내 메서드를 직접 호출하면 Spring AOP 프록시 안 타서 `@Cacheable`/`@CacheEvict` 가 동작 안 함. helper 는 별도 빈이라 안전. 내부 호출 패턴 있으면 self-injection or 분리.

### S6. 테스트 + 문서

#### 통합 테스트 (`@SpringBootTest` + `embedded-redis` 또는 testcontainers-redis)

옵션:
- (a) `it.ozimov:embedded-redis` (Java 21 호환 확인 필요)
- (b) `org.testcontainers:redis` (가장 안전, CI 에서도 동작)
- (c) `application-test.yml` 에서 `spring.cache.type=none` 으로 캐시 비활성 → 캐시 통합 테스트 불가능 → **(b) 권장**

테스트 시나리오:

1. **Cache hit 검증** — TODO list 두 번 호출 후 SQL log 또는 mock repository 호출 횟수 1회 확인.
2. **Mutation evict 검증** — list → create → list (fresh data 포함).
3. **격리 검증** — userA mutation 후 userB cache 유지.
4. **다마고치 evict 검증** — DONE 전이 후 다마고치 응답 EXP 변동.
5. **카테고리 → todos 전파** — 카테고리 update 후 list fresh.
6. **자정 배치 evict** — `RecurrenceMaterializeScheduler.run()` 호출 후 영향 사용자 list fresh.
7. **날짜 키 분리** — 같은 사용자 다른 날짜 cache 키가 분리됨 (시간 mocking 또는 직접 redis inspect).

testcontainers 추가:
```gradle
testImplementation 'org.testcontainers:testcontainers'
testImplementation 'org.testcontainers:junit-jupiter'
testImplementation 'com.redis:testcontainers-redis:2.2.2'
```

#### 문서

- 신규: `docs/architecture/caching.md` — 본 plan 의 § 2~5 핵심 정리 + 운영 inspect 명령 예시 (`redis-cli KEYS 'todos:*'` 등).
- 갱신: `docs/architecture/overview.md` — Redis 의존성 추가 명시.
- 갱신: `docs/ops/run-local.md` — 로컬에서 redis 컨테이너 띄우는 절차 (`docker compose -f docker-compose.local.yml up -d redis`).
- 갱신: `docs/ops/env-setup.md` — Redis 환경변수 추가.
- 갱신: `AGENTS.md` § 1 (스택 설명) — Redis 추가.

---

## 5. 비범위 (NON-GOALS)

- 카테고리 색상 팔레트 (`palette:colors`) 글로벌 캐싱 — 별도 sub-task 분리.
- 다마고치 캐릭터 액션 URL (M09, `tamagotchi:actions:all`) 글로벌 캐싱 — 별도 sub-task 분리.
- 정교 evict (쿼리 파라미터 단위) — 운영 hit 률 측정 후 도입.
- TODO 검색 (`q` 파라미터) 캐싱 — hit 률 낮음, 키 폭발 방지로 제외.
- 알림 / EXP 게이지 등 실시간성 도메인 — 의도적 제외.

---

## 6. 작업 순서 (Codex 실행 시)

1. S1 (env 템플릿 3개 갱신) — 가장 작고 독립적.
2. S2 (gradle + application.yml).
3. S3 (RedisConfig + CacheEvictHelper).
4. S4 (`@Cacheable` 4 메서드).
5. S5 (Evict 와이어링 — TODO mutation 6 + 카테고리 3 + 다마고치 3 + scheduler + listener).
6. S6 (testcontainers-redis 통합 테스트 7 시나리오 + 문서).
7. 빌드 / 테스트 통과 확인 후 보고.

각 단계 마치고 `git status` / `git diff --stat` 한 줄씩 남겨 진척 보이게 한다.

## 7. 위험 / 주의

- **Self-invocation**: 같은 서비스 클래스 내 직접 호출은 프록시 우회 → `@Cacheable` 미적용. 발견 시 별도 빈으로 분리하거나 `AopContext.currentProxy()` 사용.
- **`@Transactional` 트랜잭션 외 evict 시점**: mutation 트랜잭션 커밋 전에 evict 하면 다른 요청이 cache miss 후 *아직 커밋 안 된* DB 를 읽을 위험 → `TransactionSynchronizationManager.registerSynchronization` AFTER_COMMIT 권장.
- **SCAN 비용**: 사용자 단위 패턴 evict 는 키 수에 비례. 키 폭발 방지 위해 키 설계 단순 유지.
- **테스트 격리**: testcontainer redis 는 클래스 단위 1개 사용 후 매 테스트 `flushDb` 필수.
- **JSON 역직렬화 type info**: `GenericJackson2JsonRedisSerializer` 는 `@class` type info 를 포함시킨다 → DTO 패키지 이동 시 cache miss. 운영 배포 시 `KEYS *` 비우기 필요. 본 plan 은 첫 도입이라 상관없음.

---

## 8. 인수 / 보고

Codex 완료 시 다음을 한 번에 보고:
1. 변경 파일 목록 (`git status` + `git diff --stat`).
2. 빌드 결과 (`./gradlew build` 결과 또는 `--tests` 실행 로그 끝 부분).
3. § 1 합격 조건 (A~G) 별 충족 여부 self-check.
4. 추가 발견된 issue / 후속 작업 후보.
