# Plan — 알림 시스템 근본 정합화 (Layer 1)

## Context

`cbf593f feat : be/notification 도메인 기반 구축` 머지 이후 확인된 구조적 문제:

1. **EveningReminderScheduler 가 영원히 비활성** — `@ConditionalOnBean(type = "...NotificationSettingRepository")` 로 문자열 기반 감지인데, 설정 도메인이 실제로는 `UserSettingRepository` 로 머지돼 이름 불일치. `@ConditionalOnBean` 이 true 가 된 적 없음 → 스케줄러 빈 자체가 등록되지 않음.
2. **미사용 enum 3종** (`REMINDER_MORNING`, `TODO_UNLOCK`, `TAMAGOTCHI_FAREWELL`) — 호출부 0. 기획 트리거 스펙 미확정 상태로 코드에 선언만 남아 "구현된 것 같은" 착시 유발.
3. **Notification 생성 경로 부재** — `NotificationService` 는 read/update/delete 만. `notificationRepository.save(...)` 호출하는 코드 0줄. 테이블에 row 가 생길 수 없는 구조.
4. **이벤트 기반 아키텍처 미사용** — 전 프로젝트에 `ApplicationEventPublisher`/`@EventListener` 사용 0. 트리거 경로 통일 불가.

의도한 결과:
- 저녁 리마인더가 **실제로 돈다**. `UserSetting.eveningReminderEnabled=true` + `eveningReminderTime` 일치 유저에게 매분 cron 에서 `Notification` INSERT + (Firebase on 이면) FCM 발송.
- enum 은 현재 구현된 것만 남긴다 (`REMINDER_EVENING` 1종).
- 이 PR 은 Layer 1 (최소 정합화)까지만. Layer 2 (이벤트 주도 리팩터) 는 별도 PR 예정.

---

## 범위 (이번 PR)

| 항목 | 상태 | 비고 |
|------|------|------|
| EveningReminderScheduler 활성화 + body 구현 | ✅ | Layer 1 핵심 |
| `@ConditionalOnBean` → `@ConditionalOnProperty` 교체 | ✅ | 명시적 on/off |
| `UserSettingRepository` 쿼리 메서드 추가 | ✅ | eveningReminderEnabled+time 조회 |
| `TodoRepository` 미완료 집계 메서드 추가 | ✅ | `countPending...` |
| `NotificationService` 에 생성 메서드 신설 | ✅ | `sendEveningReminder(Long userId, int pending)` |
| `NotificationType` enum 주석 명시 | ✅ | 미사용 3종 **유지** + `// TODO: 트리거 미구현` 주석 |
| `application.yml` 플래그 추가 | ✅ | `notification.evening-reminder.enabled` |
| 로컬·dev 환경에서 한 번 돌아가는 것 확인 | ✅ | E2E 스크립트 [37][39] skip 해소 확인 |
| `docs/api/error-codes.md` 갱신 | 조건부 | 새 ErrorCode 추가 시에만 |
| `docs/architecture/overview.md` 갱신 | ✅ | 스케줄러·알림 플로우 1~2줄 |

**범위 제외 (Layer 2 이후)**:
- `ApplicationEventPublisher` 도입 및 NotificationService 이벤트화
- `REMINDER_MORNING` 스케줄러 — 기획 확정 후 별도 티켓
- `TODO_UNLOCK` 트리거 — 스펙 미확정
- `TAMAGOTCHI_FAREWELL` 트리거 — 수명 종료 정의 필요
- DND 구간 미끄러져 밀린 알림 재전송 정책
- FCM 실패 시 재시도 큐

---

## 설계

### 1. `NotificationType` enum 주석 명시

유지하되 각 값에 구현 상태 주석. 기획 확정 시 주석을 지우고 활성.

```java
public enum NotificationType {
    REMINDER_EVENING,       // 저녁 미완료 TODO 리마인더 — 구현 (이번 PR)
    REMINDER_MORNING,       // TODO: 트리거 미구현 — 기획 확정 시 활성화
    TODO_UNLOCK,            // TODO: 트리거 미구현 — 기획 확정 시 활성화
    TAMAGOTCHI_FAREWELL     // TODO: 트리거 미구현 — 기획 확정 시 활성화
}
```

**이유**: 제거 시 기획 확정 후 enum 재추가 + FE 타입 동기화 부담. 유지하되 "구현됨 vs 예약됨" 을 코드에서 명시. "구현된 것 같은 착시" 는 주석으로 방지.

---

### 2. `UserSettingRepository` 확장

```java
public interface UserSettingRepository extends JpaRepository<UserSetting, Long> {
    Optional<UserSetting> findByUserId(Long userId);

    // NEW — 저녁 스케줄러 조회
    List<UserSetting> findAllByEveningReminderEnabledTrueAndEveningReminderTime(LocalTime time);
}
```

---

### 3. `TodoRepository` 집계 메서드

`TodoStatus.DONE` 아닌 것 + `isDeleted=false` 기준.

```java
@Query("""
    select count(t) from Todo t
    where t.userId = :userId
      and t.status <> com.doitdo.domain.todo.entity.Todo.TodoStatus.DONE
      and t.isDeleted = false
""")
long countPendingByUserId(@Param("userId") Long userId);
```

(derived query 로도 가능하지만 명시적 JPQL 이 읽기 쉬움)

---

### 4. `NotificationService` 생성 메서드 신설

기존 인터페이스에 추가:
```java
void sendEveningReminder(Long userId, int pendingCount);
```

구현 (`NotificationServiceImpl`):
```java
@Override
@Transactional
public void sendEveningReminder(Long userId, int pendingCount) {
    String title = "저녁 미완료 TODO 알림";
    String body = String.format("아직 %d개의 할 일이 남아있어요.", pendingCount);

    Notification notification = Notification.of(
        userId, NotificationType.REMINDER_EVENING, title, body, null
    );
    notificationRepository.save(notification);

    List<DeviceToken> tokens = deviceTokenRepository.findAllByUserIdAndIsActiveTrue(userId);
    if (tokens.isEmpty()) return;

    FcmService.SendResult result = fcmService.send(tokens, title, body);
    // 실패 토큰 isActive=false 는 FcmService 내부에서 처리 (기존 스펙 유지)
}
```

→ 이 메서드는 Layer 2 에서 `applicationEventPublisher.publishEvent(new NotificationPublished(...))` 로 교체 예정. 지금은 직접 호출 방식 유지해도 OK (YAGNI).

---

### 5. `EveningReminderScheduler` body 구현

```java
@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(
    name = "notification.evening-reminder.enabled",
    havingValue = "true",
    matchIfMissing = true)
public class EveningReminderScheduler {

    private final UserSettingRepository userSettingRepository;
    private final TodoRepository todoRepository;
    private final NotificationService notificationService;

    @Scheduled(cron = "0 * * * * *", zone = "Asia/Seoul")
    public void run() {
        LocalTime now = LocalTime.now(ZoneId.of("Asia/Seoul"))
                                 .withSecond(0).withNano(0);

        List<UserSetting> targets = userSettingRepository
            .findAllByEveningReminderEnabledTrueAndEveningReminderTime(now);

        for (UserSetting s : targets) {
            if (isInDnd(s, now)) continue;
            long pending = todoRepository.countPendingByUserId(s.getUserId());
            if (pending == 0) continue;

            try {
                notificationService.sendEveningReminder(s.getUserId(), (int) pending);
            } catch (Exception ex) {
                log.warn("[evening-reminder] send failed user={}", s.getUserId(), ex);
            }
        }
    }

    private boolean isInDnd(UserSetting s, LocalTime now) {
        if (!Boolean.TRUE.equals(s.getDndEnabled())) return false;
        LocalTime start = s.getDndStartTime();
        LocalTime end = s.getDndEndTime();
        if (start == null || end == null) return false;
        // 자정 교차 구간 처리 (예: 22:00~06:00)
        if (start.isBefore(end))   return !now.isBefore(start) && now.isBefore(end);
        else                       return !now.isBefore(start) || now.isBefore(end);
    }
}
```

**DND 구간 처리 방침 (Layer 1 범위)**:
- DND 걸리더라도 **`Notification` row 는 저장** (알림함에 남아 유저가 해제 후 앱 열면 확인 가능).
- **FCM push 만 skip** — 조용한 시간엔 푸시 안 감.
- 별도 "DND 해제 시점에 밀린 알림 재발송" 큐는 **Layer 1 범위 제외**. 필요 시 Layer 2 이후 별도 티켓.
- 구현 위치: `NotificationServiceImpl.sendEveningReminder` 안에서 DND 판단 → row 는 save, DND 중이면 `fcmService.send(...)` 호출 skip.

따라서 DND 체크를 **스케줄러가 아니라 Service 에 둔다** (row 저장은 항상, push 만 조건부). 스케줄러는 "발송 후보 수집 + 미완료 카운트 판단" 까지만.

수정된 책임 경계:

```
EveningReminderScheduler.run()
  ├─ 현재 시각 = eveningReminderTime 이고 eveningReminderEnabled=true 인 유저 조회
  ├─ 각 유저에 대해 미완료 TODO 개수 집계. 0 이면 skip.
  └─ NotificationService.sendEveningReminder(userId, pending) 호출

NotificationService.sendEveningReminder(userId, pending)
  ├─ Notification.save(REMINDER_EVENING) — 항상 수행
  ├─ UserSetting 조회 → DND 판정
  └─ DND 가 아니면 DeviceToken 조회 → FcmService.send(...)
```

DND 판정 유틸은 `NotificationServiceImpl` 에 private 메서드 또는 `setting` 도메인의 공용 유틸로 둔다 (지금은 전자로 충분).
```

핵심 변경 포인트:
- `@ConditionalOnBean(type=...)` **삭제** → `@ConditionalOnProperty` 로 명시적 토글. `matchIfMissing=true` 라 dev 기본 동작.
- 의존성은 **생성자 주입** — 없으면 컴파일 깨짐. 은폐 불가.
- DND·미완료 집계·발송을 서비스/리포지토리로 위임. 스케줄러는 오케스트레이션만.

---

### 6. `application.yml` 플래그

```yaml
notification:
  evening-reminder:
    enabled: ${notification.evening-reminder.enabled:true}
```

→ 테스트 프로파일이나 상황 따라 `notification.evening-reminder.enabled=false` 로 끌 수 있음. (대량 dev 인스턴스 공존 시 중복 발송 방지 등.)

---

### 7. 파일 구조 (수정/생성)

```
be/src/main/java/com/doitdo/
├── domain/notification/
│   ├── entity/Notification.java                              (수정: enum 4종 유지 + 구현 상태 주석)
│   ├── application/
│   │   ├── NotificationService.java                          (수정: sendEveningReminder 추가)
│   │   ├── impl/NotificationServiceImpl.java                 (수정: sendEveningReminder 구현 + deviceTokenRepo/fcmService 주입)
│   │   └── scheduler/EveningReminderScheduler.java           (전면 교체: body 구현 + ConditionalOnProperty)
│   └── repository/ (변동 없음)
├── domain/setting/
│   └── repository/UserSettingRepository.java                 (수정: findAllByEveningReminderEnabledTrueAndEveningReminderTime)
├── domain/todo/
│   └── repository/TodoRepository.java                        (수정: countPendingByUserId)

be/src/main/resources/
└── application.yml                                           (수정: notification.evening-reminder.enabled)

be/docs/
├── api/error-codes.md                                        (조건부)
└── architecture/overview.md                                  (수정: 스케줄러·알림 플로우 서술)
```

---

## 구현 순서 (Codex 위임용)

1. NotificationType 4종 유지. 각 값에 구현 상태 주석 부여 (REMINDER_EVENING = 구현, 나머지 = TODO)
2. `UserSettingRepository` 쿼리 추가
3. `TodoRepository` 에 `countPendingByUserId` 추가
4. `NotificationService` 인터페이스에 `sendEveningReminder` 선언
5. `NotificationServiceImpl` 에 `sendEveningReminder` 구현 (+ `DeviceTokenRepository`, `FcmService` 주입)
6. `EveningReminderScheduler` 전면 교체 (body + ConditionalOnProperty + 생성자 주입)
7. `application.yml` 에 `notification.evening-reminder.enabled` 키 추가
8. docs 갱신 — `architecture/overview.md` 에 "매분 cron → UserSetting 조회 → 미완료 카운트 → NotificationService.sendEveningReminder → Notification INSERT + FcmService.send" 한 단락

---

## 검증

### 로컬
1. `./gradlew compileJava` 성공.
2. 로컬 BE 띄우고 자신 계정의 `UserSetting.eveningReminderEnabled=true`, `eveningReminderTime=지금+2분` 으로 PATCH.
3. 미완료 TODO 1개 이상 생성.
4. 2분 대기 → `GET /api/notifications` 에 `REMINDER_EVENING` 1건 확인.
5. Firebase off (`firebase.enabled=false`) 상태에선 `NoopFcmService` 로그만 뜨고 Notification 저장은 정상 — 로그 확인.

### E2E 스크립트
- `scripts/e2e/run.py --insecure` 재실행.
- 조건을 맞추기 어려우면 Layer 2 까지 기다리지 말고 **임시 수단**: `eveningReminderTime` 을 "현재 +1 분" 으로 맞추고 sleep 70초 삽입하는 옵션 플래그 `--wait-evening` 을 run.py 에 추가 고려 (선택사항, 이번 PR 범위 밖).

### Swagger
- `NotificationType` 값이 1개로 축소된 응답 스키마가 `/swagger-ui.html` 에 반영되는지 확인.

---

## 롤백·영향

- **DB**: `notifications.type` 컬럼은 `VARCHAR(30) ENUM NAME`. 기존 row 0 이라 안전. migration 필요 없음.
- **API 응답 contract**: `type` 필드 enum 변경 없음 (enum 유지) — 실 응답은 지금도 REMINDER_EVENING 만 나올 예정이라 소비자(FE) 영향 없음.
- **스케줄러 플래그**: `notification.evening-reminder.enabled=false` 로 설정하면 롤백과 동일.

---

## Layer 2 (별도 PR 예고, 이 플랜에 포함 X)

- `NotificationPublished` 이벤트 + `NotificationEventListener`
- `NotificationService.sendEveningReminder` → `eventPublisher.publishEvent(...)` 로 변경
- 향후 MORNING/UNLOCK/FAREWELL 트리거는 각 도메인에서 이벤트 publish, 발송은 리스너가 단일 경로
- 기획 트리거 확정 후 `NotificationType` 재증설

---

## Layer 3 (별도 문서, 이번 PR 에서는 생략)

`docs/conventions/` 에 원칙 문서화 — 별도 메모 혹은 팀 회의 안건으로:

- **"조건부 빈 + 문자열 타입 감지" 금지** — 컴파일 타임에 잡히지 않는 의존성은 남기지 않는다.
- **"동작하지 않는 스켈레톤 머지 금지"** — 하위작업 분해 기준: 머지 후 실제 한 번은 돌아가는 단위.
- **enum·API 는 기획 확정 이후 선언** — "나중에 채울 것" 으로 남기지 않는다.

---

## Codex 위임 시 주의사항 (헤드 메모 반영)

- `--write` 플래그 필수.
- `--background` 로 job 제출, log tail 로 완료 감지.
- CDP MCP 금지 문구 프롬프트에 포함.
- 설계안 승인 요청이 Codex 에서 오면 Claude 가 직접 판단해 재개 (이 문서가 SSOT).
- 시작 시 `be/docs/logs/codex.txt` 생성, 완료 시 삭제.
- 완료 후 Sonnet Agent 에게 로컬 컴파일/동작 검증 위임 (구현 권한 없이 verify 전용).
- 완료 후 이 플랜 파일을 `be/docs/plans/completed_plans/` 로 이동.
