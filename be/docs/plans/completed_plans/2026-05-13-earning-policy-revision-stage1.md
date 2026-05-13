# 뚜레딧 보상 정책 개정 — Stage 1 (단순 상수 변경 + cap 조정)

- **작성일:** 2026-05-13
- **MR 단위:** Stage 1 단독 MR (`[BE : feat] 뚜레딧 보상 정책 1차 개정`)
- **선행:** `2026-05-07-doredit-earning-system-design.md`
- **후속:** Stage 2 (일일 출석 신규 구현), Stage 3 (캐릭터 EXP DB 변경)

---

## 1. 변경 정책 요약

| # | 항목 | 현재값 | 신규값 |
|---|------|------|------|
| 1 | 7일 Streak 보상 | 200 뚜레딧 | **500 뚜레딧** |
| 4 | TODO 완료 단가 | 10 뚜레딧 / 3개당 1회 | **20 뚜레딧 / 1개당 1회** |
| 4 | TODO 일일 한도 | 3회 (=30뚜레딧) | **5회 (=100뚜레딧)** |
| 5 | 캐릭터 터치 단가 | 10 뚜레딧 | **50 뚜레딧** |
| 5 | 캐릭터 터치 쿨타임 | 1시간 | **2시간** |
| 5 | 캐릭터 터치 일일 한도 | 3회 (=30뚜레딧) | **2회 (=100뚜레딧)** |
| 공통 | `SOURCE_DAILY_CAP` | 30 | **100** |
| 공통 | `COMBINED_DAILY_CAP` | 60 | **200** |

> **횟수 판별 방식:** 별도 칼럼 추가 없이 기존 `wallet_earn_logs` 테이블의 `source` × 당일 `earned_at` SUM 쿼리로 판별. 터치는 기존 `user_characters.daily_touch_count` / `daily_touch_date` 칼럼 그대로 활용.

---

## 2. 변경 명세

### 2.1 7일 Streak 보상 — 200 → 500

**파일:** `src/main/java/com/doitdo/domain/streak/application/impl/UserStreakServiceImpl.java`

```java
// 라인 26
private static final int SEVEN_DAY_REWARD_AMOUNT = 500; // 200 → 500
```

- `REWARD_INTERVAL_DAYS = 7` 유지
- `StreakRewardLog` UNIQUE 제약(중복 방지) 유지
- `bypassDailyCap=true` 호출 유지 (cap 무관)

### 2.2 TODO 완료 보상 — 20뚜레딧/1개당, 일일 5회

**파일:** `src/main/java/com/doitdo/domain/user/application/listener/TodoCompletionCreditListener.java`

```java
// 라인 29-30
private static final int TODO_COMPLETION_CREDIT = 20;        // 10 → 20
private static final int REQUIRED_COMPLETION_COUNT = 1;      // 3 → 1 (1개당 즉시 적립)
```

**임계값 판정 로직 재작성** (라인 ~70 부근):

기존:
```java
if ((todayEarnCount + 1) * REQUIRED_COMPLETION_COUNT <= todayDistinctFirstCompleted) {
    creditEarnService.tryEarn(..., TODO_COMPLETION, TODO_COMPLETION_CREDIT, ...);
}
```

신규:
```java
// 1개당 즉시 적립이지만, 일일 5회 한도는 CreditEarnServiceImpl 의 SOURCE_DAILY_CAP=100 으로 자동 차단됨
// REQUIRED_COMPLETION_COUNT=1 이므로 todayDistinctFirstCompleted 가 todayEarnCount 보다 크면 적립 시도
if (todayDistinctFirstCompleted > todayEarnCount) {
    creditEarnService.tryEarn(..., TODO_COMPLETION, TODO_COMPLETION_CREDIT, ..., false);
}
```

> Codex 가 더 단순한 표현이 가능하다고 판단하면 그쪽을 채택해도 좋다. 핵심: **REQUIRED_COMPLETION_COUNT=1, 단가 20, cap 은 CreditEarnServiceImpl 에 위임**.

### 2.3 캐릭터 터치 — 50뚜레딧, 쿨타임 2시간, 일일 2회

**파일:** `src/main/java/com/doitdo/domain/tamagotchi/application/impl/TamagotchiServiceImpl.java`

```java
// 라인 483-484 — hardcoded 10 제거, 상수화
// (클래스 상단)
private static final int PET_TOUCH_CREDIT = 50;             // 신규 상수
private static final int PET_TOUCH_DAILY_LIMIT = 2;         // 신규 상수
private static final int PET_TOUCH_COOLDOWN_HOURS = 2;      // 신규 상수

// 라인 483-484 호출부
creditEarnService.tryEarn(userId, PET_TOUCH, PET_TOUCH_CREDIT, characterId, false);

// 라인 503, 521 — 일일 한도
userCharacter.getDailyTouchCount() < PET_TOUCH_DAILY_LIMIT  // < 3 → < PET_TOUCH_DAILY_LIMIT

// 라인 505, 525 — 쿨타임
lastTouchedAt.plusHours(PET_TOUCH_COOLDOWN_HOURS)           // plusHours(1) → plusHours(PET_TOUCH_COOLDOWN_HOURS)
```

- `nextAvailableAt()` 의 자정 리셋 로직(`today.plusDays(1).atStartOfDay()`)은 그대로 유지
- `PESSIMISTIC_WRITE` 락도 그대로 유지

### 2.4 공통 — CreditEarnServiceImpl cap 조정

**파일:** `src/main/java/com/doitdo/domain/user/application/impl/CreditEarnServiceImpl.java`

```java
// 라인 22-23
private static final int SOURCE_DAILY_CAP = 100;     // 30 → 100
private static final int COMBINED_DAILY_CAP = 200;   // 60 → 200
```

- `DAILY_CAPPED_SOURCES = List.of(PET_TOUCH, TODO_COMPLETION)` 유지
- `SIGNUP_BONUS`, `STREAK_7DAY` 의 `bypassDailyCap=true` 처리 유지
- TimeZone 일관성: `LocalDate.now()` 호출부에 **`ZoneId.of("Asia/Seoul")` 명시** (현 코드가 시스템 TimeZone 의존)
- 함께 `TodoCompletionCreditListener` 의 날짜 계산도 `Asia/Seoul` 통일

---

## 3. 통합 테스트 갱신

**파일:** `src/test/java/com/doitdo/integration/DoreditEarningSystemIntegrationTest.java`

| Case | 기존 | 신규 |
|------|------|------|
| Case 2 (7일 Streak) | +200 검증 | **+500 검증** |
| Case 3 (IDLE 3회 → +30, 4회째 → 0) | 10 × 3회 = 30, 4회 차단 | **50 × 2회 = 100, 3회 차단** |
| Case 4 (1시간 쿨타임) | `plusHours(1)` 후 가능 | **`plusHours(2)` 후 가능** |
| Case 5 (24시간 후 재적립) | 동일 시나리오 | **새 정책에 맞춰 카운트·금액 갱신** |
| Case 6 (TODO 9개 → +30, 10번째 → 0) | 3개당 10, 9개=+30, 10번째=차단 | **1개당 20, 5개=+100, 6번째=차단** |
| Case 6-1 (과거 TODO 제외) | 동일 시나리오 | 시나리오 유지, 금액만 갱신 |
| Case 8 (합산 cap 60 = 30+30) | PET_TOUCH 30 + TODO 30 = 60 | **PET_TOUCH 100 + TODO 100 = 200** |
| Case 10 (동시 IDLE 5회) | 락 검증 + 한도 3회 | **한도 2회로 갱신** |

> Case 1 (회원가입 +100), Case 7 (undo/redo 1회 적립), Case 9 (구매·잔액부족) 은 정책 변경 영향 없음 → 그대로 유지.

---

## 4. docs 갱신 (CLAUDE.md 규칙: 같은 PR 안에서 무조건)

| 문서 | 갱신 내용 |
|------|---------|
| `docs/api/error-codes.md` | 신규 에러코드 없음, 기존 코드 설명만 정책값 갱신 |
| `docs/architecture/erd.md` | 보상 정책 표·예시 금액 갱신 (있으면) |
| `docs/plans/2026-05-07-doredit-earning-system-design.md` | 정책 표 갱신 또는 "Stage 1 개정 반영" 주석 |
| 노션 SSOT | 정책 변경 페이지 갱신 — Codex 작업 후 사용자가 수동 확인 |

> 노션 갱신은 Codex 의 책임 범위 밖. Codex 는 git 내 docs 만 갱신.

---

## 5. 영향 파일 전체 목록

### 코드
- `src/main/java/com/doitdo/domain/streak/application/impl/UserStreakServiceImpl.java`
- `src/main/java/com/doitdo/domain/user/application/listener/TodoCompletionCreditListener.java`
- `src/main/java/com/doitdo/domain/tamagotchi/application/impl/TamagotchiServiceImpl.java`
- `src/main/java/com/doitdo/domain/user/application/impl/CreditEarnServiceImpl.java`

### 테스트
- `src/test/java/com/doitdo/integration/DoreditEarningSystemIntegrationTest.java`

### 문서
- `docs/api/error-codes.md` (필요 시)
- `docs/architecture/erd.md` (필요 시)
- `docs/plans/2026-05-07-doredit-earning-system-design.md`

### 마이그레이션
- **없음** (cap·단가 변경은 Java 상수만 수정, DB 스키마/데이터 변경 없음)

---

## 6. 완료 기준 (Definition of Done)

1. 4개 코드 파일의 상수·로직 수정 완료
2. `DoreditEarningSystemIntegrationTest` 8개 Case 갱신 후 **전부 통과**
3. `./gradlew test` 전체 통과
4. `./gradlew build` 통과 (compile + checkstyle 통과)
5. docs 동시 갱신
6. MR 본문은 `~/.claude/.../templates/mr-body.md` 템플릿 그대로 사용
7. 커밋 메시지: `feat: 뚜레딧 보상 정책 1차 개정 (단가·cap·쿨타임)`

---

## 7. 작업하지 않는 것 (Out of Scope)

- 일일 출석 신규 구현 → **Stage 2 별도 plan**
- 캐릭터 EXP DB 변경 (75/100/125) + 자동 승급 마이그레이션 → **Stage 3 별도 plan**
- 보상 정책 어드민 화면, 정책값 외부화(yaml/DB), TimeZone 전역 Bean 화 → 추후 별도 작업

---

## 8. 제약 (Codex 위임 시 필수)

CDP MCP(Chrome DevTools Protocol MCP)는 절대 사용하지 않는다. 브라우저 자동화, DOM 접근, 스크린샷 등 CDP 관련 도구 일체 금지.
