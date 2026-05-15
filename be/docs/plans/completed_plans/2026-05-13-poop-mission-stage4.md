# 일일 똥치우기 미션 — Stage 4

- **작성일:** 2026-05-13
- **MR 단위:** Stage 4 단독 MR (`[BE : feat] 일일 똥치우기 미션`)
- **브랜치:** `be/feat/poop-mission` (origin/dev 최신에서 분기 — Stage 3·5 머지 후)
- **선행:** Stage 3 (머지 완료), Stage 5 (머지 대기 — base 가 그 위에 올라감)

---

## 1. 정책

| 항목 | 값 |
|---|---|
| 활성 시각 결정 | 매일 10:00 ~ 22:00 KST 중 랜덤 1회 |
| 갱신 방식 | **Lazy** — `getCurrentCharacter` 호출 시점에 `poop_time_date != today` 면 그 자리에서 재설정 |
| 보상 금액 | **50 뚜레딧** |
| 일일 한도 | **1회** (poop=true 일 때만 가능, 처리 후 즉시 false) |
| 일일 cap 검사 | `bypassDailyCap=true` (자체 1일 1회로 보장) |
| 트리거 | `POST /api/characters/me/actions/POOP` (action API 분기) |
| `poop=true` 조건 | `now(KST) >= poop_time` AND `poop_cleared_date != today` |

> **Streak 와 다름**: 똥치우기는 캐릭터 단위 일일 미션, 서버가 결정한 시각 이후만 활성. action API 의 한 분기.

---

## 2. DB 변경

### 2.1 신규 컬럼 (`user_character`)

```sql
ALTER TABLE user_character
  ADD COLUMN poop_time          TIME NULL    COMMENT '오늘 똥 활성 시각 (10:00~22:00 KST 랜덤)',
  ADD COLUMN poop_time_date     DATE NULL    COMMENT 'poop_time 마지막 결정 일자 (Lazy 갱신 트리거)',
  ADD COLUMN poop_cleared_date  DATE NULL    COMMENT '마지막 똥 치운 날짜 (today 면 이미 치움)';
```

> **3개 칼럼 분리 이유**:
> - `poop_time`: 활성 시각 (HH:mm)
> - `poop_time_date`: 그 시각이 결정된 날짜 (Lazy 비교 — `!= today` 면 재결정)
> - `poop_cleared_date`: 사용자가 똥을 치운 날짜 (`== today` 면 활성 false)

### 2.2 마이그레이션 SQL

`docs/ops/migrations/2026-05-13-user-character-poop-fields.sql`:

```sql
ALTER TABLE user_character
  ADD COLUMN poop_time          TIME NULL,
  ADD COLUMN poop_time_date     DATE NULL,
  ADD COLUMN poop_cleared_date  DATE NULL;

-- 기존 row 의 컬럼은 NULL 로 초기화. 다음 GET /me/character 호출 시 Lazy 로 채워진다.
```

### 2.3 local-init seed (있으면)

`local-init/00-schema-and-seed.sql` 에 user_character 정의가 있으면 위 컬럼 추가. (.gitignore 라 commit 안 됨)

---

## 3. enum 신규

### 3.1 `CharacterActionType` (action 종류)

기존 enum 에 `POOP` 값 추가. **정확한 enum 클래스 위치**는 Codex 가 grep 으로 확정 (예: `com.doitdo.domain.tamagotchi.entity.CharacterActionType` 또는 enum/AnimationAction).

### 3.2 `WalletEarnSource`

```java
public enum WalletEarnSource {
    SIGNUP_BONUS,
    STREAK_7DAY,
    PET_TOUCH,
    TODO_COMPLETION,
    DAILY_ATTENDANCE,
    POOP_CLEAR    // 신규 — 50 뚜레딧, 일일 1회, bypassDailyCap=true
}
```

> `DAILY_CAPPED_SOURCES` 에는 추가하지 않음 (cap 무관).

---

## 4. 응답 노출 — `CurrentCharacterResp`

```java
public record CurrentCharacterResp(
    Long characterId,
    Long userCharacterId,
    String name,
    String stage,
    String thumbnailUrl,
    int growthPercent,
    int currentExp,
    int requiredExp,
    boolean canEvolve,
    boolean canFarewell,
    Long equippedUserItemId,
    boolean poop          // 신규
) {}
```

`poop` 판정 (`TamagotchiService.getCurrentCharacter` 안):

```java
boolean poop = userCharacter.getPoopTime() != null
    && !LocalTime.now(SEOUL).isBefore(userCharacter.getPoopTime())
    && !today.equals(userCharacter.getPoopClearedDate());
```

---

## 5. Lazy 갱신 로직

`TamagotchiService.getCurrentCharacter()` 안에 추가:

```java
LocalDate today = LocalDate.now(SEOUL);
if (!today.equals(userCharacter.getPoopTimeDate())) {
    // 매일 첫 호출 — poop_time 새로 결정
    LocalTime newTime = randomTimeBetween(LocalTime.of(10, 0), LocalTime.of(22, 0));
    userCharacter.refreshPoopTime(newTime, today);
    // entity helper:
    //   public void refreshPoopTime(LocalTime time, LocalDate date) {
    //     this.poopTime = time;
    //     this.poopTimeDate = date;
    //   }
}
```

**`randomTimeBetween` 구현**:
- 두 시각 사이 분 단위 차이 = 720분 (10:00~22:00)
- `ThreadLocalRandom.current().nextInt(720)` 으로 분 offset 결정
- 결과: 10:00 + n분

> Lazy 갱신은 **활성 사용자만 비용 발생**. 스케줄러 불필요.

---

## 6. Action API 분기 — `POOP`

`POST /api/characters/me/actions/{actionType}` (또는 정확한 매핑 — Codex 가 controller 확정) 의 처리 분기:

```java
case POOP:
    if (!isPoopActive(userCharacter, now, today)) {
        // 활성 시각 전 OR 이미 치움 → 거절
        throw new CustomException(TamagotchiErrorCode.M09_POOP_NOT_ACTIVE);
    }
    int earned = creditEarnService.tryEarn(
        userId, WalletEarnSource.POOP_CLEAR, POOP_CLEAR_REWARD, characterId, true
    );
    userCharacter.markPoopCleared(today);  // poop_cleared_date = today
    // 응답에 earnedAmount=50 (또는 0 if cap 등)
```

**상수**:
```java
private static final int POOP_CLEAR_REWARD = 50;
```

**ErrorCode 신규**:
- `M09_???` 또는 적절한 코드 (예: `M09-003 캐릭터 똥 활성화 시간이 아닙니다`) — Codex 가 기존 M09 코드 grep 후 다음 번호 부여

---

## 7. `CharacterActionUrlResp` 두 필드 제거

**파일:** `src/main/java/com/doitdo/domain/tamagotchi/api/dto/resp/CharacterActionUrlResp.java`

기존:
```java
public record CharacterActionUrlResp(
    String actionUrl,
    int earnedAmount,
    int balanceAfter,
    int dailyTouchCount,        // ← 제거
    LocalDateTime nextAvailableAt   // ← 제거
) {}
```

신규:
```java
public record CharacterActionUrlResp(
    String actionUrl,
    int earnedAmount,
    int balanceAfter
) {}
```

**`TamagotchiServiceImpl` 의 채우는 코드 제거** (라인 ~469-475, 497-502 부근):
- `dailyTouchCount` / `nextAvailableAt` 계산 로직 제거
- `nextAvailableAt(...)` 헬퍼 메서드 자체 제거
- 단, **entity `UserCharacter.dailyTouchCount` 컬럼은 그대로 유지** — 쿨타임/한도 검사에 여전히 필요

---

## 8. 통합 테스트

**파일:** `src/test/java/com/doitdo/integration/PoopMissionIntegrationTest.java` (신규)

| Case | 시나리오 | 기대 |
|---|---|---|
| 1 | 신규 사용자, 첫 GET /api/characters/me | poop=false, poop_time=10:00~22:00 사이 랜덤 결정 |
| 2 | poop_time 전 호출 | poop=false |
| 3 | poop_time 도래 후 호출 | poop=true |
| 4 | POOP action 호출 (활성 상태) | 50뚜레딧 적립 + poop_cleared_date=today + poop=false |
| 5 | 같은 날 두 번째 POOP action | 거절 (M09-???) |
| 6 | 자정 경과 후 GET /me/character | poop_time 새로 결정 (Lazy), poop=false (시각 전이라면) |
| 7 | POOP_CLEAR 가 SOURCE/COMBINED cap 무관 (PET_TOUCH 100 + TODO 100 + POOP 50 가능) | 50뚜레딧 적립 |

**기존 테스트 영향**:
- `TamagotchiServiceImplTest` — `CharacterActionUrlResp` 필드 제거 반영 (assertion 갱신)
- 다른 테스트도 grep 으로 영향 확인

---

## 9. docs 갱신

| 문서 | 갱신 |
|---|---|
| `docs/api/swagger.md` | `POST /api/characters/me/actions/POOP` 분기 + `CurrentCharacterResp.poop` 필드 + `CharacterActionUrlResp` 두 필드 제거 명시 |
| `docs/api/response-format.md` | `CurrentCharacterResp` 와 `CharacterActionUrlResp` 변경 |
| `docs/api/error-codes.md` | 신규 M09-??? 추가 |
| `docs/architecture/erd.md` | `user_character` 신규 컬럼 3개 (`poop_time`, `poop_time_date`, `poop_cleared_date`) + `WalletEarnSource.POOP_CLEAR` 추가 |
| `docs/architecture/package-layout.md` | (변경 없음, 같은 도메인) |
| `docs/plans/completed_plans/2026-05-07-doredit-earning-system-design.md` | "Stage 4 똥치우기 반영" 주석 |

---

## 10. 영향 파일 전체 목록

### 신규
- `docs/ops/migrations/2026-05-13-user-character-poop-fields.sql`
- `src/test/java/com/doitdo/integration/PoopMissionIntegrationTest.java`
- `docs/plans/completed_plans/2026-05-13-poop-mission-stage4.md` (이 문서)

### 변경
- `src/main/java/com/doitdo/domain/tamagotchi/entity/UserCharacter.java` — 3개 컬럼 + 헬퍼 (refreshPoopTime, markPoopCleared)
- `src/main/java/com/doitdo/domain/tamagotchi/entity/CharacterActionType.java` (또는 정확한 위치) — `POOP` enum 값 추가
- `src/main/java/com/doitdo/domain/user/entity/WalletEarnSource.java` — `POOP_CLEAR` enum 값 추가
- `src/main/java/com/doitdo/domain/tamagotchi/api/dto/resp/CurrentCharacterResp.java` — `poop` boolean 필드
- `src/main/java/com/doitdo/domain/tamagotchi/api/dto/resp/CharacterActionUrlResp.java` — `dailyTouchCount`, `nextAvailableAt` 제거
- `src/main/java/com/doitdo/domain/tamagotchi/application/impl/TamagotchiServiceImpl.java` — Lazy 갱신, POOP 분기, ActionUrlResp 정리
- `src/main/java/com/doitdo/global/exception/TamagotchiErrorCode.java` (또는 정확한 위치) — M09-??? 추가
- 영향 받는 기존 테스트 (`TamagotchiServiceImplTest` 등)
- docs 4~5개

---

## 11. 완료 기준 (DoD)

1. user_character 신규 컬럼 3개 + 마이그레이션 SQL
2. CharacterActionType.POOP, WalletEarnSource.POOP_CLEAR 추가
3. CurrentCharacterResp.poop 노출 + Lazy 갱신
4. action API POOP 분기 (50뚜레딧/일1회)
5. CharacterActionUrlResp 두 필드 제거 + 채우는 코드 제거 (entity 컬럼 유지)
6. 신규 ErrorCode M09-???
7. PoopMissionIntegrationTest 7 케이스 + 영향 테스트 갱신
8. `./gradlew test` 전체 통과
9. docs 동시 갱신
10. 커밋 메시지: `feat: 일일 똥치우기 미션 + action 응답 정리`

---

## 12. 작업하지 않는 것 (Out of Scope)

- 똥치우기 통계/캘린더 API
- 푸시 알림 ("똥이 등장했어요")
- 캐릭터 종별 똥 종류 차별화
- ADULT 단계만 똥 싸기 등 단계별 정책
- Stage 1~3, 5 의 영역 변경

---

## 13. 제약 (Codex 위임 시 필수)

CDP MCP(Chrome DevTools Protocol MCP)는 절대 사용하지 않는다. 브라우저 자동화, DOM 접근, 스크린샷 등 CDP 관련 도구 일체 금지.
