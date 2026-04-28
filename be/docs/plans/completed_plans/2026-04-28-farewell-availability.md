# Plan — 다마고치 이별(독립) 알림 시점 변경 + 4·5번 알림 비활성화

작성일: 2026-04-28
브랜치: `be/feat/farewell-availability`
관련 도메인: `notification`, `tamagotchi`, `todo`

## 배경

현재 알림 시스템 7종 중 운영 활성은 6종. 사용자 요구로 다음 변경:

1. **TODO_SNOOZED** 알림 비활성화
2. **TAMAGOTCHI_GROWTH** 알림 비활성화
3. **TAMAGOTCHI_FAREWELL** 알림: 발동 시점을 **이별(approveIndependence) 순간이 아니라 canFarewell 활성화 순간**으로 변경
   - canFarewell 활성화 = ADULT 캐릭터의 `currentExp` 가 처음 `requiredExp` 에 도달한 후 **랜덤 48~96시간 경과 시점**
   - 메시지: `"<name>이(가) 독립할 준비가 되었어요!"`

## 사양

### 1. canFarewell 정의 변경

기존 (`TamagotchiServiceImpl.toCurrentCharacterResp` line 212-214):
```java
canFarewell = stage == ADULT && requiredExp != null && currentExp >= requiredExp;
```

변경 후:
```java
canFarewell = stage == ADULT
    && requiredExp != null
    && currentExp >= requiredExp
    && farewellAvailableAt != null
    && !LocalDateTime.now().isBefore(farewellAvailableAt);
```

### 2. 활성화 예약 시점 — TODO 완료 → exp 가산 transition

`TodoCompletionExpListener.onTodoCompleted` 안에서 `uc.gainExp` 호출 직전·직후 `currentExp` 비교:

조건 (모두 만족):
- `character.stage == ADULT`
- `before < requiredExp && after >= requiredExp` (정확히 cap 도달 transition; cap 클램프로 after 는 항상 == requiredExp)
- `uc.farewellAvailableAt == null` (멱등 보장)

조건 만족 시:
```java
long hours = ThreadLocalRandom.current().nextLong(48, 97); // [48, 96] 균등
uc.scheduleFarewell(LocalDateTime.now().plusHours(hours));
```

### 3. 활성화 감지 — 신규 `FarewellAvailabilityScheduler`

매분 cron (`0 * * * * *`, KST). sweep query:

```sql
SELECT uc FROM UserCharacter uc
WHERE uc.farewellAvailableAt IS NOT NULL
  AND uc.farewellAvailableAt <= :now
  AND uc.farewellNotified = false
  AND uc.isActive = true
  AND uc.isDeleted = false
```

각 row 처리:
1. `uc.markFarewellNotified()` 로 멱등 마킹 (`farewell_notified = true`)
2. `notificationService.sendFarewellAvailable(userId, userCharacterId, characterName)` 호출
   - DB 알림 저장 (`type=TAMAGOTCHI_FAREWELL`, referenceId=userCharacterId)
   - DND 체크 후 FCM 푸시
   - 메시지: `"<name>이(가) 독립할 준비가 되었어요!"`

> 별도 도메인 이벤트 publish 없이 스케줄러가 직접 NotificationService 호출 (`MorningReminderScheduler` 와 동일 패턴).

### 4. `approveIndependence` 게이트 강화

`TamagotchiServiceImpl.approveIndependence` 에 `farewellAvailableAt` 검사 추가:

```java
if (uc.getFarewellAvailableAt() == null
    || LocalDateTime.now().isBefore(uc.getFarewellAvailableAt())) {
    throw new CustomException(TamagotchiErrorCode.M00_003); // 또는 신규 에러코드
}
```

> 기존엔 `stage == ADULT` 만 검사 → 새 정책에서는 cap 도달 + 활성화 시각 경과 둘 다 충족해야 이별 가능.

### 5. 4·5·6번 알림 핸들러 정리

| 항목 | 기존 | 변경 |
|------|------|------|
| `TodoSnoozedNotificationListener` | snooze 이벤트 → DB 저장 + FCM | **본문 비움 (no-op)**, 주석으로 비활성화 표기 |
| `TamagotchiGrowthNotificationListener` | growth 이벤트 → DB 저장 + FCM | **본문 비움 (no-op)** |
| `TamagotchiFarewellNotificationListener` | farewell 이벤트 → DB 저장 + FCM | **본문 비움 (no-op)** — 이별 시점 알림 제거 |
| 신규 `FarewellAvailabilityScheduler` | — | 매분 sweep → 활성화 시점 알림 |

> enum (`TODO_SNOOZED`, `TAMAGOTCHI_GROWTH`, `TAMAGOTCHI_FAREWELL`) 자체는 보존 — 기존 DB 데이터 호환·롤백 여지.
> `TAMAGOTCHI_FAREWELL` 는 의미가 "이별 처리 완료" → "독립 준비 완료" 로 재정의됨. 새 메시지로 발송.

### 6. NotificationService 변경

- 기존 `sendTamagotchiFarewell(userId, userCharacterId, beforeCharacterName)` 시그니처 유지 가능, 메시지 본문만 변경:
  - 기존: `"<name>의 독립을 응원해요. 새 친구가 알을 깨고 나올 준비를 하고 있어요."`
  - 변경: `"<name>이(가) 독립할 준비가 되었어요!"`
  - 제목: `"독립 준비 완료"` (또는 적절한 한국어)
  - referenceId 는 ADULT 의 userCharacterId (딥링크)
- 호출 경로가 listener 에서 scheduler 로 바뀜.

## DDL (직접 적용 — 수동)

```sql
ALTER TABLE user_character
  ADD COLUMN farewell_available_at DATETIME(6) NULL AFTER current_exp,
  ADD COLUMN farewell_notified BIT(1) NOT NULL DEFAULT b'0' AFTER farewell_available_at;

-- 기존 운영 데이터 backfill: ADULT cap 도달 row 에만 random 48~96h 채움
UPDATE user_character uc
JOIN characters c ON c.character_id = uc.character_id
SET uc.farewell_available_at = NOW(6) + INTERVAL FLOOR(48 + RAND() * 49) HOUR
WHERE c.stage = 'ADULT'
  AND c.required_exp IS NOT NULL
  AND uc.current_exp >= c.required_exp
  AND uc.is_active = b'1'
  AND uc.is_deleted = b'0';
```

> 적용 대상: `doitdo` (dev), `doitdo_main` (main).
> ddl-auto=update 로 컬럼은 Hibernate 가 자동 추가하지만, 사용자 지시로 운영 DB 에 수동 SQL 적용.

## 변경 파일 목록 (Codex 작업)

### 수정
- `src/main/java/com/doitdo/domain/tamagotchi/entity/UserCharacter.java` — 컬럼 2개 + `scheduleFarewell`, `markFarewellNotified` 메서드
- `src/main/java/com/doitdo/domain/tamagotchi/repository/UserCharacterRepository.java` — sweep query 추가
- `src/main/java/com/doitdo/domain/tamagotchi/application/listener/TodoCompletionExpListener.java` — transition 감지 + 예약
- `src/main/java/com/doitdo/domain/tamagotchi/application/impl/TamagotchiServiceImpl.java` — `canFarewell` 계산식 + `approveIndependence` 게이트
- `src/main/java/com/doitdo/domain/notification/application/listener/TodoSnoozedNotificationListener.java` — no-op
- `src/main/java/com/doitdo/domain/notification/application/listener/TamagotchiGrowthNotificationListener.java` — no-op
- `src/main/java/com/doitdo/domain/notification/application/listener/TamagotchiFarewellNotificationListener.java` — no-op
- `src/main/java/com/doitdo/domain/notification/application/impl/NotificationServiceImpl.java` — `sendTamagotchiFarewell` 메시지 변경 (또는 별도 메서드 신설)

### 신규
- `src/main/java/com/doitdo/domain/notification/application/scheduler/FarewellAvailabilityScheduler.java`

### 테스트
- `TodoCompletionExpListenerTest` — cap 도달 transition 시 `farewellAvailableAt` 세팅 확인 (멱등성 포함)
- `FarewellAvailabilitySchedulerTest` — sweep 동작 + 알림 1회 발송 확인
- `TamagotchiServiceImplTest` — `canFarewell` 새 조건 + `approveIndependence` 게이트
- 기존 `TamagotchiFarewellNotificationListenerTest` 류 있으면 비활성화 반영

### 문서
- `docs/api/notifications.md` 또는 관련 문서가 있다면 알림 종류·발동 조건 업데이트
- `docs/architecture/*` 에 farewell-availability 흐름 추가 (필요 시)

## 완료 기준

- `./gradlew clean build` 성공
- `./gradlew test` 전 케이스 통과
- 관련 문서 갱신 (CLAUDE.md 의 "docs 도 같은 PR" 규칙)
- 운영 DB 두 곳에 DDL + backfill 수동 적용 완료 (Claude 본인이 SSH 로 직접 수행)

## 비고 / 주의

- `gainExp` 의 캡 클램프 동작상 `before == cap` 인 상태에서는 transition 감지 안 됨 → 마이그레이션 backfill SQL 로 기존 cap 도달 데이터 보호.
- 진화(`evolve` BABY→TEEN→ADULT) 직후엔 `resetExp()` 로 currentExp=0 → ADULT 진입 후 다시 todo 완료로 cap 채워야 transition 발생. 정상 동작.
- DND·deviceToken·FCM 발송 공통 처리(`dispatchFcm`)는 변경 없음.
- `farewell_available_at` 은 timezone-naive `LocalDateTime` (서버 KST 기준). BaseTimeEntity 와 일관.
