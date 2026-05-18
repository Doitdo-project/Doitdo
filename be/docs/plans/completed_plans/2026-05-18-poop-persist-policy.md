## 구현 결과
2026-05-18 13:32:48 KST - 변경 파일: `src/main/java/com/doitdo/domain/tamagotchi/application/impl/TamagotchiServiceImpl.java`, `src/test/java/com/doitdo/integration/PoopMissionIntegrationTest.java`, `docs/plans/2026-05-18-poop-persist-policy.md`

# Poop 미션 — 미청소 시 다음날까지 유지 정책 (2026-05-18)

## 배경

- 기존 정책 (`docs/plans/completed_plans/2026-05-13-poop-mission-stage4.md`) 에서는
  자정 후 첫 `GET /api/characters/me` 호출 시 `poop_time_date != today` 이기만 하면
  무조건 `poop_time` 을 새로 결정해 어제 미청소 똥이 사라지는 것처럼 보였다.
- 사용자 의도: **안 치운 똥은 다음 날에도 유지되어야 한다.**

## 정책 (확정)

| 항목 | 값 |
|---|---|
| 보상 | 청소 1회당 **50 뚜레딧 고정** (기존 동일) |
| 신규 똥 발생 | 직전 발생 똥이 미청소이면 **신규 발생 정지** (누적 최대 1개) |
| DB 컬럼 추가 | **없음** (기존 `poop_time` / `poop_time_date` / `poop_cleared_date` 재해석) |
| 활성 시각 결정 | 직전 똥이 청소되었거나 처음 결정될 때만 10:00 ~ 22:00 KST 중 랜덤 |
| 청소 처리 | 단일 `POST /api/characters/me/actions/POOP` 호출로 누적 똥(최대 1개) 일괄 클리어 |

## 코드 변경 범위

### A. `TamagotchiServiceImpl.refreshPoopTimeIfNewDate()`
`src/main/java/com/doitdo/domain/tamagotchi/application/impl/TamagotchiServiceImpl.java:273-278`

**현재**
```java
private void refreshPoopTimeIfNewDate(UserCharacter userCharacter, LocalDate today) {
    if (today.equals(userCharacter.getPoopTimeDate())) {
        return;
    }
    userCharacter.refreshPoopTime(randomPoopTime(), today);
}
```

**변경 후**
```java
private void refreshPoopTimeIfNewDate(UserCharacter userCharacter, LocalDate today) {
    LocalDate poopTimeDate = userCharacter.getPoopTimeDate();
    if (today.equals(poopTimeDate)) {
        return; // 오늘 이미 결정됨
    }
    // 직전 발생 똥이 미청소이면 유지 (poop_time_date != poop_cleared_date)
    if (poopTimeDate != null
        && !poopTimeDate.equals(userCharacter.getPoopClearedDate())) {
        return;
    }
    userCharacter.refreshPoopTime(randomPoopTime(), today);
}
```

### B. `TamagotchiServiceImpl.isPoopActive()`
`src/main/java/com/doitdo/domain/tamagotchi/application/impl/TamagotchiServiceImpl.java:566-570`

**현재**
```java
private boolean isPoopActive(UserCharacter userCharacter, LocalDateTime now, LocalDate today) {
    return userCharacter.getPoopTime() != null
        && !now.toLocalTime().isBefore(userCharacter.getPoopTime())
        && !today.equals(userCharacter.getPoopClearedDate());
}
```

**변경 후**
```java
private boolean isPoopActive(UserCharacter userCharacter, LocalDateTime now, LocalDate today) {
    LocalDate poopTimeDate = userCharacter.getPoopTimeDate();
    if (userCharacter.getPoopTime() == null || poopTimeDate == null) {
        return false;
    }
    // 이미 청소된 똥이면 비활성
    if (poopTimeDate.equals(userCharacter.getPoopClearedDate())) {
        return false;
    }
    // 과거 발생 똥(어제 미청소)은 시각 무관 활성
    if (poopTimeDate.isBefore(today)) {
        return true;
    }
    // 오늘 발생 똥은 결정된 시각 도달 시 활성
    return !now.toLocalTime().isBefore(userCharacter.getPoopTime());
}
```

### C. `TamagotchiServiceImpl.clearPoop()`
`src/main/java/com/doitdo/domain/tamagotchi/application/impl/TamagotchiServiceImpl.java:538-558`

- 가드 조건 단순화: `isPoopActive(...)` 만 검사 (활성 = 청소 가능)
  - 기존 `today.equals(poopTimeDate)` 가드는 어제 똥도 청소 가능하게 만들기 위해 제거
- `markPoopCleared(today)` → `markPoopCleared(userCharacter.getPoopTimeDate())` 로 변경
  - 청소 표시 일자를 **청소된 똥의 발생일**로 기록해야 이후 `refreshPoopTimeIfNewDate()` 가
    "이 똥은 청소됨" 으로 정상 판정함

**변경 후**
```java
private int clearPoop(Long userId, UserCharacter userCharacter, LocalDateTime now, LocalDate today) {
    if (!isPoopActive(userCharacter, now, today)) {
        throw new CustomException(TamagotchiErrorCode.M09_004);
    }
    int earnedAmount = creditEarnService.tryEarn(
        userId, WalletEarnSource.POOP_CLEAR, POOP_CLEAR_REWARD,
        userCharacter.getCharacterId(), true
    );
    userCharacter.markPoopCleared(userCharacter.getPoopTimeDate());
    cacheEvictHelper.evictTamagotchiCurrentAfterCommit(userId);
    return earnedAmount;
}
```

### D. 엔티티 헬퍼 — 변경 없음
`UserCharacter.markPoopCleared(LocalDate)` 시그니처 그대로. 인자만 today 대신
poopTimeDate 를 넣어주는 호출부 변경.

## 시나리오 검증 (수동)

| Case | 직전 상태 | 액션 | 기대 |
|---|---|---|---|
| 1 | 첫 호출 | GET | 오늘 10~22시 중 시각 결정, 시각 전 비활성 |
| 2 | 오늘 14:00 활성, now 15:00 | POST POOP | 50 적립, poop_cleared_date = today, poop=false |
| 3 | 오늘 14:00 발생, 미청소, 자정 경과, now=다음날 09:00 | GET | poop_time / poop_time_date 갱신 안 됨, **poop=true** (어제 발생) |
| 4 | Case 3 직후 | POST POOP | 50 적립, poop_cleared_date = 어제 날짜, poop=false |
| 5 | Case 4 직후 같은 날 09:01 | GET | 청소됐으니 새 시각 결정, today 시각 전이면 poop=false |
| 6 | 오늘 14:00 청소 완료 후 같은 날 15:00 | GET | today 이미 결정됨, 새 시각 결정 안 함, poop=false |

## 테스트 변경

### 파일: `src/test/java/com/doitdo/integration/PoopMissionIntegrationTest.java`

- **Case 6 (기존 "자정 경과 후 Lazy 재결정") 의미 반전**:
  - 어제 미청소 + 자정 경과 → GET 시 poop_time_date 가 어제 그대로 유지되고 poop=true 임을 검증
  - 기존 "새 날짜로 재결정" 단정을 "이전 시각/날짜 유지" 단정으로 교체
- **신규 케이스 추가** (예: Case 7~9):
  - 어제 미청소 똥을 다음날 청소 1회로 클리어 → 보상 50 정확, poop_cleared_date = 어제 날짜
  - Case 7 직후 같은 날 다시 GET → 새 poop_time 결정됨
  - 어제 청소 완료 후 자정 경과 → 새 poop_time 결정됨 (기존 정상 흐름 회귀 방지)

테스트는 `Clock` 가짜 주입 패턴을 그대로 사용 (기존 테스트와 동일 방식).

## 영향 받는 docs

- **`docs/plans/2026-05-18-poop-persist-policy.md`** (이 문서, 신규)
- 기존 stage4 plan (`completed_plans/2026-05-13-poop-mission-stage4.md`) 은 이력이라 수정 X.
  대신 본 문서 상단에 "후속 정책 변경" 언급으로 충분.
- API 응답 포맷/엔드포인트/ErrorCode/스키마 변경 없음 → `docs/api/*`, `local-init/*` 갱신 불필요.

## 비기능 / 리스크

- `LocalTime.isBefore(...)` 만으로 활성 판정하던 부분이 `poopTimeDate.isBefore(today)` 분기를
  타게 되므로, 시각 비교 단위 차이(LocalTime vs LocalDate)에 주의. 위 로직은 둘을 분리해서 처리.
- 동시성: `getCurrentCharacter()` 가 `@Transactional` 로 묶여 있고 `refreshPoopTimeIfNewDate()` 의
  분기가 더 보수적(쓰기 안 함)으로 바뀌므로 동시 호출 시 race condition 위험은 오히려 감소.
- 캐시: 청소 시 `cacheEvictHelper.evictTamagotchiCurrentAfterCommit(userId)` 그대로 호출.
  GET 결과의 `poop` 값이 정확히 갱신됨.

## 작업 분할

1. **Codex (gpt-5.5, xhigh, background)**
   - A/B/C 코드 변경
   - PoopMissionIntegrationTest Case 6 반전 + 신규 케이스 추가
   - `./gradlew test --tests 'com.doitdo.integration.PoopMissionIntegrationTest'` 그린 확인
   - 본 plan 문서 상단에 구현 결과 한 줄 추가 후 완료 보고
2. **Sonnet** (Codex 완료 후, 구현 권한 없음)
   - 로컬 서버 띄워 실제 curl 시나리오 Case 1~6 검증
   - 결과만 보고
