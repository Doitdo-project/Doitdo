# 뚜레딧 적립 시스템 설계

> 변경 이력: 2026-05-08 `AnimationAction` enum 전환 설계에 맞춰 다마고치 액션 적립 정책을 `EYE` 제외 블랙리스트에서 "모든 enum 액션 호출 적립" 화이트리스트로 갱신.
> 변경 이력: 2026-05-13 Stage 1 개정 반영. 7일 스트릭 500, TODO 완료 20/1개당(일일 5회), 캐릭터 터치 50/2시간/일일 2회, cap 100/200 정책으로 갱신.
> 변경 이력: 2026-05-13 Stage 2 attendance 추가 반영. 출석 보상은 `DAILY_ATTENDANCE` source 로 100 뚜레딧 / 일 1회 지급하며, `PET_TOUCH` + `TODO_COMPLETION` 합산 cap 에 포함하지 않는다.
> 변경 이력: 2026-05-13 Stage 5 자동 적립 전환. 별도 `POST /api/users/me/attendance` 없이 `GET /api/users/me` 첫 호출에서 출석 보상을 lazy claim 한다.

## 배경

뚜레딧(`user_wallets.balance`, Integer 단위)은 인프라가 갖춰져 있다. 신규 가입 100, 잔액 조회 API, 상점 구매 차감, 스트릭 7일 보상 지급은 구현 완료다. 그러나 **다마고치 터치 적립**, **TODO 완료 적립**, **일일 한도(200) enforcement**, **출처별 적립 이력 통합 감사**가 없다. 이번 작업은 이 네 갭을 메운다.

## 확정된 요구사항

### 적립 규칙

- 신규 가입 시 1회 100 뚜레딧 (이미 구현 — 단, Stage 1 에서 `wallet_earn_logs` 에 `SIGNUP_BONUS` 로 기록되도록 retrofit).
- 스트릭 7일 달성 시 500 뚜레딧 (Stage 1 개정. `STREAK_7DAY` 로 `wallet_earn_logs` 기록).
- 다마고치 "터치"(아래 정의) 1회당 50 뚜레딧 적립. 쿨다운 2시간, 하루 최대 2회.
- TODO 완료 1개당 20 뚜레딧 적립. 하루 최대 5회 / 100 뚜레딧. 같은 TODO 의 취소·재완료는 카운트 변동 없음 (중요: 아래 §"TODO 적립 트리거 정밀 정의" 참고).
- 하루 적립 합산 한도 200 뚜레딧 (`PET_TOUCH` 100 + `TODO_COMPLETION` 100). 가입·스트릭 보너스는 cap 대상 외 (`bypassDailyCap=true`).
- 출석 보상은 앱 진입 시 `GET /api/users/me` 첫 호출에서 하루 1회 100 뚜레딧을 자동 적립한다. `wallet_earn_logs` 의 `DAILY_ATTENDANCE` 당일 SUM 으로 중복 수령을 차단하고, 일일 cap 은 우회한다.

### "다마고치 터치" 정의

- FE 는 다마고치 캐릭터 탭 시 `GET /api/characters/me/actions/{actionType}` 를 호출한다.
- 현재 FE 구현상 탭으로 호출되는 actionType 은 `IDLE` 만. `EYE` 는 로컬 에셋(자동 깜빡임)이라 BE 도달 안 함.
- 적립 트리거: **`AnimationAction` enum 에 포함되고 `character_actions` row 가 등록된 모든 액션 호출**. `EYE` 제외 블랙리스트는 폐기한다.
- 응답에서 actionUrl 은 **무조건** 정상 반환 (애니메이션은 보여줘야 함). 쿨다운/일일 한도 미충족 시 적립만 silent skip — `earnedAmount: 0` + `nextAvailableAt` 으로 신호.

### TODO 적립 트리거 정밀 정의

- `Todo` 엔티티에 `firstCompletedDate DATE NULL` 컬럼 추가. 처음 DONE 으로 전이될 때 단 1회 세팅, 이후 보존 (취소·재완료 영향 없음).
- 그날 적립 가능 횟수: `today_distinct_first_completed = COUNT(Todo WHERE userId=? AND firstCompletedDate=today)`.
- 그날 이미 지급한 적립 횟수: `today_earn_count = SUM(WalletEarnLog.amount WHERE userId=? AND source=TODO_COMPLETION AND DATE(earnedAt)=today) / 20` (= `WalletEarnLogRepository.sumAmountByUserIdAndSourceAndDate(...)` 재사용 후 20으로 나눔. 이 쿼리는 `tryEarn` 내 cap 합산에도 동일하게 사용됨).
- 적립 조건: `today_distinct_first_completed > today_earn_count` 일 때 +20 (source cap 100 안에서). 즉, 당일 보상 대상 TODO 1개 완료마다 1회 적립을 시도하고 일일 5회 한도는 `CreditEarnServiceImpl` 의 cap 으로 차단한다. 이렇게 하면 (a) 같은 todo 의 undo→redo 가 카운트에 영향 없음, (b) 이미 지급된 적립은 그대로 보존 (회수 없음).
  - 예: distinct=1, earn_count=0 → 적립. distinct=1, earn_count=1 → 스킵. distinct=6, earn_count=5 → 적립 시도 후 source cap 100 에서 스킵.

### 한도 enforcement 구조

- 통합 적립 이력 테이블 `wallet_earn_logs` 신설 (감사 + 합산 cap 계산).
- 출처별 일일 카운터는 각 도메인이 보유 (다마고치는 `UserCharacter.dailyTouchCount`/`dailyTouchDate`, TODO 는 위 §정밀 정의대로 역산).
- 적립 진입점: `CreditEarnService.tryEarn(userId, source, amount, refId, bypassDailyCap)` 단일.
  - PESSIMISTIC_WRITE 로 `UserWallet` 락. (`PET_TOUCH` 의 경우 `UserCharacter` 락도 같이 잡고 들어옴 — Stage 3 §동시성 섹션 참고)
  - `bypassDailyCap=false` 면 출처별 일일 cap 100 → 합산 200 cap 순으로 체크.
  - cap 초과 시 silent skip (예외 X). 비즈니스 의미상 "더 못 받음" 이지 에러 아님.
  - 통과 시 `wallet.addBalance(amount)` + `wallet_earn_logs` 행 추가.
  - `bypassDailyCap=true` (가입·스트릭) 는 cap 검사 우회하고 무조건 지급 + 로그.

### 도메인 위치 일관성

- `WalletEarnLog`, `CreditEarnService` 는 **`com.doitdo.domain.user`** 패키지 안에 둔다 (`UserWallet` 과 같은 도메인). 신규 `domain/wallet` 패키지 만들지 않음. `UserWallet` 분리는 향후 별도 작업.

## 단계 분리

### Stage 0 — 스트릭 보상 금액 정정

- `UserWallet.SEVEN_DAY_REWARD_AMOUNT` 100 → 200. 이후 2026-05-13 Stage 1 개정으로 최종 정책은 500.
- 관련 단위·통합 테스트 갱신.
- `docs/legal/terms-of-service-{ko,en}.md` 의 보상 금액 명시 영역 정정 (있을 때).
- 과거 `StreakRewardLog` 행 보정 없음.
- 커밋: `feat : 스트릭 7일 보상 100 → 200 으로 정정`.

### Stage 1 — 적립 이력 인프라 + 기존 적립 경로 retrofit

- 신규 엔티티 `WalletEarnLog (logId, userId, source ENUM, amount, refId BIGINT NULL, earnedAt)` + Repository.
  - source ENUM: `SIGNUP_BONUS`, `STREAK_7DAY`, `PET_TOUCH`, `TODO_COMPLETION`, `DAILY_ATTENDANCE`(Stage 2 추가).
- `CreditEarnService` 인터페이스 + 구현. 시그니처 `tryEarn(userId, source, amount, refId, bypassDailyCap)`. 락·cap·로그·잔액 갱신을 한 트랜잭션.
- `WalletErrorCode` (필요 시) + `ErrorCodeRegistry.SOURCES` 등록.
- 마이그레이션 SQL: `docs/ops/migrations/2026-05-07-wallet-earn-log.sql`.
- **기존 적립 경로 retrofit (audit 완전성)**:
  - `AuthServiceImpl.signup()` 에서 `wallet_earn_logs` 에 `SIGNUP_BONUS` 100 기록되도록 `tryEarn(..., bypassDailyCap=true)` 경유로 변경.
  - 스트릭 보상 (`UserStreakService.claimReward()` 또는 동급 위치) 도 `tryEarn(..., bypassDailyCap=true)` 경유로 변경.
- docs 갱신: `docs/architecture/erd.md`, `docs/architecture/package-layout.md` (필요 시), `docs/api/error-codes.md`.

### Stage 2 — TODO 완료 적립 훅

- `Todo` 엔티티에 `firstCompletedDate DATE NULL` 컬럼 추가.
- 마이그레이션 SQL: `docs/ops/migrations/2026-05-07-todo-first-completed-date.sql`.
- `TodoServiceImpl.changeStatus(...)` 또는 도메인 이벤트 리스너에서 DONE 전이 시:
  - `firstCompletedDate` 가 NULL 이면 today 로 세팅 (이후 보존).
  - `today_distinct_first_completed > today_earn_count` 면 `creditEarnService.tryEarn(userId, TODO_COMPLETION, 20, todoId, false)` 호출.
- 취소/되돌리기 시 `firstCompletedDate` 변경 없음. 이미 지급된 뚜레딧·경험치 회수 없음.
- 단위 테스트: undo→redo 5회 토글 후 카운트가 1 그대로인지 검증.

### Stage 3 — 다마고치 터치 적립

- `UserCharacter` 에 컬럼 추가: `lastTouchedAt TIMESTAMP NULL`, `dailyTouchCount INT NOT NULL DEFAULT 0`, `dailyTouchDate DATE NULL`.
- `UserCharacterRepository.findByUserIdForUpdate(userId)` 추가 (PESSIMISTIC_WRITE).
- 마이그레이션 SQL: `docs/ops/migrations/2026-05-07-user-character-touch-fields.sql`.
- `getMyCharacterActionUrl(userId, actionType)` 흐름:
  1. 활성 캐릭터 actionUrl 조회 (그대로).
  2. `actionType` 은 `AnimationAction` enum 으로 바인딩한다. enum 에 없는 값은 400, enum 에 있지만 row 가 없으면 404 `M09-002`.
  3. `EYE` 포함 모든 enum 액션은 동일하게 적립 평가에 진입한다.
  4. `userCharacterRepository.findByUserIdForUpdate(userId)` 로 `UserCharacter` 락.
  5. `dailyTouchDate != today` 면 `dailyTouchCount = 0`, `dailyTouchDate = today` 갱신.
  6. `now - lastTouchedAt < 2h` 또는 `dailyTouchCount >= 2` 이면 적립 skip.
  7. 통과 시 `creditEarnService.tryEarn(userId, PET_TOUCH, 50, characterId, false)` 호출. 성공하면 `lastTouchedAt = now`, `dailyTouchCount += 1`.
  8. 모든 mutation 은 같은 트랜잭션 안에서 마무리.
  9. 응답 DTO `CharacterActionUrlResp` 확장: `(actionUrl, earnedAmount, balanceAfter, dailyTouchCount, nextAvailableAt)`. 적립 skip 시 `earnedAmount: 0`, `nextAvailableAt` 으로 다음 가능 시각 신호.
- Swagger `@ApiErrorCodes`, `docs/api/error-codes.md` 갱신 (필요 시 신규 코드).
- 액션 enum 전환 상세 설계: `docs/plans/2026-05-08-animation-action-enum-design.md`.
- **FE 영향 사전 확인**: Flutter `CharacterActionUrlResp` Dart DTO 가 unknown 필드를 무시하는지 (`@JsonSerializable` 의 `disallowUnrecognizedKeys` 설정 점검). strict 면 BE 변경과 같은 시점에 FE DTO 도 확장 필요(별도 FE PR).

### Stage 5 — 통합 검증 + 문서

- `@SpringBootTest` 통합 테스트:
  - 신규가입 직후 잔액 100, `wallet_earn_logs` 에 SIGNUP_BONUS 1행.
  - 스트릭 7일 보상 → +500, cap 영향 없음, `STREAK_7DAY` 로그.
  - 다마고치 등록 액션 호출 2회 → +100, 3회째 actionUrl 정상 + earnedAmount=0.
  - 2시간 쿨다운: 1회차 직후 즉시 호출 → 적립 0.
  - 24시간 경과 후 다시 적립 가능.
  - TODO 5개 완료 → +100, 6개째 적립 0.
  - **TODO undo→redo 토글 5회 → 카운트 1, 적립 1회 그대로** (정밀 정의 검증).
  - 다마 100 + TODO 100 합산 후 추가 적립 0.
  - 가구 구매 → `wallet.spend()` 정상, 잔액 부족 시 `S00-003 INSUFFICIENT_BALANCE`.
  - 동시성: 같은 사용자에게서 등록 액션 호출 5개 동시 발사 → race 없이 일관된 결과, 총 적립 ≤ 100 (2시간 cooldown 정책상 첫 호출만 통과되는 게 정합 — race condition 없음 검증이 핵심).
- 최종 docs 동기화 점검 (위 단계에서 누락 영역).
- 노션 SSOT 영향 영역 확인 (있으면 노션도 같이 갱신).

## MR 전략

- **단일 MR + Stage 단위 커밋 분리**.
- 브랜치: `be/feat/doredit-earning-system` (dev 위에서 분기).
- 커밋 분리:
  - `feat : 스트릭 7일 보상 100 → 200 으로 정정` (Stage 0)
  - `feat : 적립 이력 테이블·CreditEarnService 추가` (Stage 1 인프라)
  - `feat : 가입·스트릭 적립 경로 wallet_earn_logs 통합` (Stage 1 retrofit)
  - `feat : TODO 완료 1개당 뚜레딧 적립 구현` (Stage 2)
  - `feat : 다마고치 터치 뚜레딧 적립 구현` (Stage 3)
  - `test : 뚜레딧 적립 시스템 통합 테스트` (Stage 5)
  - `docs : 뚜레딧 적립 시스템 docs 동기화` (Stage 5)
- MR 제목: `[BE : feat] 뚜레딧 적립 시스템 구현`.
- MR 본문: `~/.claude/projects/-home-cbkjh0225-project-ssafyTodo-S14P31D107/templates/mr-body.md` 그대로.
- 대상 브랜치: dev.

## 위임 라우팅

| Stage | 모델 | 사유 |
|---|---|---|
| 0 | Sonnet Agent (background) | 단순 상수 교체 + 문서 정정 |
| 1 | Codex `--background --write` xhigh | 신규 도메인 + 트랜잭션·락·retrofit |
| 2 | Codex | 도메인 결합 + 정밀 트리거 |
| 3 | Codex | 동시성 (이중 락) + 도메인 결합 |
| 5 | Sonnet Agent | 통합 테스트 + 문서 마무리 |

## 영향 파일 요약

신규:
- `src/main/java/com/doitdo/domain/user/entity/WalletEarnLog.java`
- `src/main/java/com/doitdo/domain/user/application/CreditEarnService.java` (+ Impl)
- `src/main/java/com/doitdo/domain/user/repository/WalletEarnLogRepository.java`
- `docs/ops/migrations/2026-05-07-wallet-earn-log.sql`
- `docs/ops/migrations/2026-05-07-todo-first-completed-date.sql`
- `docs/ops/migrations/2026-05-07-user-character-touch-fields.sql`

수정:
- `src/main/java/com/doitdo/domain/streak/application/...` (스트릭 보상 상수 500, claimReward → tryEarn 경유)
- `src/main/java/com/doitdo/domain/auth/application/impl/AuthServiceImpl.java` (signup → tryEarn 경유)
- `src/main/java/com/doitdo/domain/todo/entity/Todo.java` (firstCompletedDate)
- `src/main/java/com/doitdo/domain/todo/application/impl/TodoServiceImpl.java` 또는 신규 이벤트 리스너
- `src/main/java/com/doitdo/domain/tamagotchi/entity/UserCharacter.java` (컬럼 3개)
- `src/main/java/com/doitdo/domain/tamagotchi/repository/UserCharacterRepository.java` (findByUserIdForUpdate)
- `src/main/java/com/doitdo/domain/tamagotchi/api/dto/resp/CharacterActionUrlResp.java` (필드 확장)
- `src/main/java/com/doitdo/domain/tamagotchi/application/impl/TamagotchiServiceImpl.java` (`getMyCharacterActionUrl`)
- `src/main/java/com/doitdo/global/exception/ErrorCodeRegistry.java` (SOURCES 추가, 필요 시)
- `docs/architecture/erd.md`, `docs/architecture/package-layout.md`, `docs/api/error-codes.md`
- `docs/legal/terms-of-service-{ko,en}.md` (스트릭 500 반영)
