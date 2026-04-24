# Plan — 알림 Layer 1 머지 전 강화 (Hardening)

## Context

`notification-foundation-fix.md` (completed_plans/) 로 Layer 1 구현 완료 후, Opus 4.7 두 에이전트가 병렬 교차 평가 실시:
- **A (플랜 검증)**: 플랜 문서 L224/L247 "enum 제거" 흔적과 L59 "유지+주석" 결론 불일치. 다중 인스턴스 중복 발송 가드 부재.
- **B (코드 검증)**: `@Transactional` 안에서 FCM 호출 → 플랜 §5 "DND 걸려도 row 는 저장" 방침 정반대. `LocalTime` 정밀도 미스매치로 스케줄러 equals 매칭이 실패할 수 있음.

→ 이 둘 중 **플랜 의도를 무너뜨리는 코드 버그 2건** 은 머지 전 반드시 수정. 나머지는 Layer 2 로 정리.

---

## 범위 (이 수정)

| # | 항목 | 원인 | 심각도 |
|---|------|------|--------|
| 1 | `sendEveningReminder` 의 `@Transactional` 로 인한 FCM 실패 시 save 동반 롤백 | 외부 I/O 가 TX 안 | BLOCKER (플랜 §5 방침 위배) |
| 2 | `LocalTime` 나노초 정밀도 미스매치 | Hibernate 가 TIME(6) 생성 시 저장값에 나노 포함, `now.withSecond(0).withNano(0)` equals 매칭 실패 | BLOCKER (알림이 아예 안 돌 수 있음) |
| 3 | 스케줄러 `now` vs 서비스 `now` 로 DND 2회 계산 → 경계값 드리프트 | 메서드 간 clock 공유 없음 | HIGH |
| 4 | `completed_plans/notification-foundation-fix.md` L224/L247 "enum 3개 제거" 기록 잔존 | 내 L59 수정 시 동기화 누락 | HIGH (문서 무결성, 후대 참고 혼란) |

### 범위 제외 — Layer 2 이월

별도 플랜 `notification-layer2-event-driven.md` (미작성) 에 묶을 항목:

- 멀티 인스턴스 중복 발송 가드 (ShedLock 또는 DB unique index `(user_id, type, trigger_date, trigger_time)`)
- `Notification` 엔티티에 idempotency key 컬럼
- `ApplicationEventPublisher` + `@TransactionalEventListener(AFTER_COMMIT)` 로 save ↔ FCM 경계 분리 (이번에 TX 제거는 임시조치, 구조적 해결은 Layer 2)
- FCM 재시도 큐 / dead-letter
- DND 해제 시 밀린 알림 요약 전송 정책
- DND 경계값 `start==end` 처리 의미 정의 (24h DND 인가? 꺼짐인가?)
- `FcmService.SendResult` 반환값 로깅·모니터링
- `docs/api/swagger.md` enum 반영 (현재는 유지 정책이라 변경 無)
- `updateAllRead` 의 `LocalDateTime.now()` Asia/Seoul 타임존 일관화

### 범위 제외 — FE 팀 확인 필요 (별도 티켓)

- `UserSetting.pushEnabled` 필드 부재가 FE 동기화됐는지
- DND 중 쌓인 알림을 유저가 어떻게 인지할지 (배지 카운트 경로)

---

## 설계

### 1. FCM 호출 TX 경계 분리

`NotificationServiceImpl.sendEveningReminder` 에서 **`@Transactional` 어노테이션 제거**. Spring Data JPA 의 `JpaRepository.save()` 는 자체 트랜잭션을 열고 커밋하므로, 상위 메서드에 `@Transactional` 이 없으면 save 는 즉시 커밋되고 그 이후 호출(쿼리/FCM)은 트랜잭션 밖에서 돌아간다.

**Before**:
```java
@Override
@Transactional
public void sendEveningReminder(Long userId, int pendingCount) {
    Notification n = Notification.of(...);
    notificationRepository.save(n);
    ...
    if (!isInDnd(...)) fcmService.send(tokens, title, body);   // TX 안
}
```

**After**:
```java
@Override
public void sendEveningReminder(Long userId, int pendingCount, LocalTime now) {
    String title = "저녁 미완료 TODO 알림";
    String body  = "아직 %d개의 할 일이 남아있어요.".formatted(pendingCount);

    notificationRepository.save(Notification.of(
        userId, NotificationType.REMINDER_EVENING, title, body, null));
    // ↑ save 는 자체 TX 커밋. 이후 예외가 나도 row 는 남는다.

    boolean inDnd = userSettingRepository.findByUserId(userId)
        .map(s -> isInDnd(s, now))
        .orElse(false);
    if (inDnd) {
        log.debug("[evening-reminder] dnd; fcm skipped user={}", userId);
        return;
    }

    List<DeviceToken> tokens = deviceTokenRepository.findAllByUserIdAndIsActiveTrue(userId);
    if (tokens.isEmpty()) return;

    try {
        fcmService.send(tokens, title, body);
    } catch (Exception ex) {
        log.warn("[evening-reminder] fcm failed user={}", userId, ex);
    }
}
```

- `@Transactional` 어노테이션 **제거**.
- FCM 호출부는 `try/catch` 로 한 유저 실패가 다른 처리로 전파되지 않게.
- `FirebaseFcmService` 가 내부에서 `@Transactional` 로 토큰 비활성화를 처리하는 로직은 **자기 자신의 TX** 로 돌아가게 됨 (propagation 전파 문제 해소).

### 2. `LocalTime` 나노초 정규화

`UserSetting.java` 에 `@PrePersist` / `@PreUpdate` 콜백 추가. 모든 `LocalTime` 필드를 `withSecond(0).withNano(0)` 로 정규화해 저장한다.

```java
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;

@PrePersist
@PreUpdate
private void normalizeTimes() {
    this.morningReminderTime = truncate(this.morningReminderTime);
    this.eveningReminderTime = truncate(this.eveningReminderTime);
    this.dndStartTime        = truncate(this.dndStartTime);
    this.dndEndTime          = truncate(this.dndEndTime);
}

private static LocalTime truncate(LocalTime t) {
    return t == null ? null : t.withSecond(0).withNano(0);
}
```

- `@PrePersist` / `@PreUpdate` 는 JPA 표준 라이프사이클이며, `update(...)` 메서드 경로·빌더 경로 **모두 커버**.
- `AuditingEntityListener` 와 병존 가능 (다른 애너테이션 콜백).
- nullable 필드(`dndStartTime/EndTime`) 는 null 을 그대로 유지.

### 3. DND 판정 `now` 일관성

`NotificationService` 인터페이스 시그니처에 `LocalTime now` 파라미터 추가.

**Before**:
```java
void sendEveningReminder(Long userId, int pendingCount);
```

**After**:
```java
void sendEveningReminder(Long userId, int pendingCount, LocalTime now);
```

스케줄러가 한 번 계산한 `now` 를 서비스로 넘겨, 스케줄러·서비스가 **같은 시각으로 DND 판정**.

```java
// EveningReminderScheduler
@Scheduled(cron = "0 * * * * *", zone = "Asia/Seoul")
public void run() {
    LocalTime now = LocalTime.now(ZoneId.of("Asia/Seoul"))
                             .withSecond(0).withNano(0);

    List<UserSetting> targets = userSettingRepository
        .findAllByEveningReminderEnabledTrueAndEveningReminderTime(now);

    for (UserSetting s : targets) {
        long pending = todoRepository.countPendingByUserId(s.getUserId());
        if (pending == 0) continue;
        try {
            notificationService.sendEveningReminder(s.getUserId(), (int) pending, now);
        } catch (Exception ex) {
            log.warn("[evening-reminder] send failed user={}", s.getUserId(), ex);
        }
    }
}
```

서비스의 `isInDnd(UserSetting, LocalTime)` 는 이미 파라미터를 받음 — 호출부만 교체.

### 4. 완료 플랜 문서 정정

파일: `be/docs/plans/completed_plans/notification-foundation-fix.md`

- L224: `│   ├── entity/Notification.java                              (수정: enum 3개 제거)`  
  → `│   ├── entity/Notification.java                              (수정: enum 4종 유지 + 구현 상태 주석)`
- L247: `1. NotificationType 에서 3개 enum 값 제거 (최우선 — 뒤 코드 정리와 엮임)`  
  → `1. NotificationType 4종 유지. 각 값 뒤에 구현 상태 주석 (REMINDER_EVENING = 구현, 나머지 = TODO)`
- (탐색 후) 롤백·영향 §L279 의 "3개 줄어듦" 문구도 잔존하면 "변경 없음 (enum 유지)" 로 정정.

---

## 파일별 변경 요약

| 파일 | 변경 |
|------|------|
| `NotificationService.java` | 시그니처 `sendEveningReminder(Long, int, LocalTime)` |
| `NotificationServiceImpl.java` | `@Transactional` 제거, save → setting/DND → FCM try/catch 순서. 시그니처 맞춤. |
| `EveningReminderScheduler.java` | `notificationService.sendEveningReminder(id, pending, now)` 호출 |
| `UserSetting.java` | `@PrePersist @PreUpdate normalizeTimes()` + `truncate(LocalTime)` |
| `docs/plans/completed_plans/notification-foundation-fix.md` | L224/L247/L279 정정 |

기존 구현에서 수정 안 할 파일 (Opus B 가 LOW/NIT 로 지적했으나 범위 제외):
- `application.yml` (matchIfMissing 정책 유지)
- `TodoRepository.java` (JPQL 그대로)
- `UserSettingRepository.java` (쿼리 그대로)
- `Notification.java` (enum 유지 결정)

---

## 구현 순서 (Sonnet Agent 에 전달)

1. `UserSetting.java` — @PrePersist / @PreUpdate / truncate
2. `NotificationService.java` — 시그니처 업데이트
3. `NotificationServiceImpl.java` — @Transactional 제거, body 재구성
4. `EveningReminderScheduler.java` — 호출부 `now` 전달
5. 플랜 문서 3곳 Edit
6. `./gradlew compileJava` 통과 확인

---

## 검증

### 자기 검증 (Sonnet Agent)
1. `./gradlew compileJava` BUILD SUCCESSFUL
2. `grep -n "@Transactional" src/main/java/com/doitdo/domain/notification/application/impl/NotificationServiceImpl.java` — `sendEveningReminder` 위에 @Transactional **없음** 확인 (`read`/`readAll`/`delete` 기존에 붙어있는 건 그대로 유지)
3. `grep -n "sendEveningReminder" src/main/java/com/doitdo/domain/notification/application/NotificationService.java` — 3-arg 시그니처
4. `grep -n "@PrePersist\|@PreUpdate\|normalizeTimes\|truncate" src/main/java/com/doitdo/domain/setting/entity/UserSetting.java` — 4+ 매치
5. `grep -n "enum 3개 제거\|3개 enum 값 제거" docs/plans/completed_plans/notification-foundation-fix.md` — **매치 0**

### 로컬 smoke (사용자 확인용)
1. BE 재기동
2. `/api/settings` PATCH: `eveningReminderEnabled=true`, `eveningReminderTime="현재+1분"`
3. 미완료 TODO 1개 이상 유지
4. 1~2분 대기
5. `GET /api/notifications` 에 `REMINDER_EVENING` 1건 확인
6. DND 테스트: `dndEnabled=true`, `dndStartTime/EndTime` 을 현재 시각 감싸게 설정 후 같은 테스트 → Notification row 는 남되 FCM 로그는 "dnd; fcm skipped" 로 뜸

---

## Codex 위임 시 주의 — 이번엔 Sonnet Agent
- `model: "sonnet"` 으로 `general-purpose` 서브에이전트 위임
- CDP MCP 금지
- 이 플랜이 SSOT, 충돌 시 플랜 우선
- 완료 후 Claude 가 spot check + 플랜 → `completed_plans/` 이동
