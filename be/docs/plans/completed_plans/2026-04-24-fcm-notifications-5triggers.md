# FCM 알림 5종 트리거 구현 (Plan)

작성: 2026-04-24
브랜치 베이스: `dev`
대상 작업 브랜치(예시): `be/feat/fcm-notification-triggers`

---

## 0. 목표

현재 `REMINDER_EVENING` 단 1건만 동작하는 FCM 알림을 다음 **5종**으로 확장한다.

| # | 트리거 | NotificationType (신규) | 발화 방식 |
|---|---|---|---|
| A | TODO 완료 (status → DONE) | `TODO_DONE` | `TodoCompletedEvent` 리스너 (기존 이벤트 재사용) |
| B | TODO 알림 시각(`alertTime`) 도달 | `TODO_REMINDER` | 기존 `TodoAlertScheduler` 흐름을 NotificationService 경유로 교체 |
| C | TODO 미루기(snooze) | `TODO_SNOOZED` | 신규 `TodoSnoozedEvent` 발행 + 리스너 |
| D | 다마고치 이별(독립 승인) | `TAMAGOTCHI_FAREWELL` (enum 기존) | 신규 `TamagotchiFarewellEvent` 발행 + 리스너 |
| E | 다마고치 성장(부화/진화) | `TAMAGOTCHI_GROWTH` (신규) | 신규 `TamagotchiGrowthEvent` 발행 + 리스너 (HATCHED/EVOLVED 통합) |

---

## 1. 공통 원칙 (모든 트리거에 적용)

- **`sendEveningReminder` 패턴을 그대로 따른다** ([NotificationServiceImpl.java:86-110](../../src/main/java/com/doitdo/domain/notification/application/impl/NotificationServiceImpl.java#L86)):
  1. `Notification.of(...)` → `notificationRepository.save()`  (DB 우선 기록 — FCM 실패해도 알림함에는 남음)
  2. `userSettingRepository.findByUserId()` → DND 체크 → 구간이면 FCM만 스킵 (DB는 이미 저장)
  3. `deviceTokenRepository.findAllByUserIdAndIsActiveTrue()` → 활성 토큰
  4. `fcmService.send(tokens, title, body)` — 예외는 catch + warn 만, 호출 흐름은 끊지 않음
- **이벤트 리스너는 `@TransactionalEventListener(phase = AFTER_COMMIT)` + `@Transactional(propagation = REQUIRES_NEW)`** ([TodoCompletionExpListener.java:41-82](../../src/main/java/com/doitdo/domain/tamagotchi/application/listener/TodoCompletionExpListener.java#L41) 패턴).
  - 본 트랜잭션 커밋 후 알림 처리. 알림 실패가 본 도메인 트랜잭션에 영향 주지 않게 분리.
- **DTO 필드 제외 명시 변경 없음.** 신규 enum 추가만 있고 기존 응답 포맷 변경 없음 → 응답 포맷/Swagger 문서 영향 없음.
- **마이그레이션:** `ddl-auto: update` 사용 중이므로 enum 추가만으로 컬럼 길이(VARCHAR(30)) 내에서 자동 반영. **DDL 스크립트 없음.**
- **referenceId 규칙:**
  - TODO 관련(A/B/C): `referenceId = todoId`
  - 다마고치 성장(E): `referenceId = userCharacterId` (현재 활성 캐릭터)
  - 다마고치 이별(D): `referenceId = afterUserCharacterId` (새로 부여된 EGG 의 id) — **선택 (a) 채택**: 본문은 작별한 캐릭터를 회상하지만 딥링크는 새 캐릭터 상세로 이동. 이력 페이지 링크 옵션은 후속 PR.

### 검증 완료 사항 (advisor 피드백 반영)

- `TodoStatus.DONE` 전이 경로는 [TodoServiceImpl.changeStatus():269](../../src/main/java/com/doitdo/domain/todo/application/impl/TodoServiceImpl.java#L269) **단 1곳**. (208 라인은 검증 분기, Repository 라인은 read 쿼리.) → Trigger A 누락 가능성 없음.
- 다마고치 상태 전이(HATCHED/EVOLVED/FAREWELL)는 모두 [TamagotchiServiceImpl](../../src/main/java/com/doitdo/domain/tamagotchi/application/impl/TamagotchiServiceImpl.java) 내부에서만 발생. `setCharacterId` 도 hatch/evolve 2곳, `deactivate` 는 approveIndependence 1곳뿐. → Trigger D/E 누락 가능성 없음.
- `TamagotchiServiceImpl` 에는 **현재 `ApplicationEventPublisher` 주입 없음** → 신규 주입 확정 (3.7 참고).

---

## 2. 알림 문구 (제안 — Codex가 그대로 사용)

| 트리거 | 제목 | 본문 |
|---|---|---|
| A. TODO 완료 | `"할 일 완료!"` | `"\"%s\" 완료를 기록했어요. 잘 했어요!".formatted(todoTitle)` |
| B. TODO 알림 시각 | `"할 일 알림"` | `"\"%s\" 시작할 시간이에요.".formatted(todoTitle)` |
| C. TODO 미루기 | `"할 일을 미뤘어요"` | `"\"%s\"을(를) %s(으)로 미뤘어요.".formatted(todoTitle, toDate)` |
| D. 다마고치 이별 | `"다마고치와 작별했어요"` | `"\"%s\"의 독립을 응원해요. 새 친구가 알을 깨고 나올 준비를 하고 있어요.".formatted(beforeName)` |
| E. 다마고치 성장 | `"다마고치가 성장했어요!"` | `"\"%s\"이(가) %s 단계로 성장했어요.".formatted(name, afterStage)` |

문구는 변경 가능하지만 enum/필드 시그니처는 위 표에 맞춰 구현.

---

## 3. 변경 파일 명세

### 3.1 신규 enum & 인터페이스 메서드

**[Notification.java](../../src/main/java/com/doitdo/domain/notification/entity/Notification.java#L27)**
```java
public enum NotificationType {
    REMINDER_EVENING,
    REMINDER_MORNING,        // 미사용 유지
    TODO_UNLOCK,             // 미사용 유지
    TODO_DONE,               // 신규
    TODO_REMINDER,           // 신규
    TODO_SNOOZED,            // 신규
    TAMAGOTCHI_FAREWELL,     // 트리거 신규 구현
    TAMAGOTCHI_GROWTH        // 신규
}
```

**[NotificationService.java](../../src/main/java/com/doitdo/domain/notification/application/NotificationService.java)** — 5개 메서드 추가
```java
void sendTodoDone(Long userId, Long todoId, String todoTitle);
void sendTodoAlert(Long userId, Long todoId, String todoTitle);
void sendTodoSnoozed(Long userId, Long todoId, String todoTitle, java.time.LocalDate toDate);
void sendTamagotchiFarewell(Long userId, Long userCharacterId, String beforeCharacterName);
void sendTamagotchiGrowth(Long userId, Long userCharacterId, String characterName, String afterStage);
```

**[NotificationServiceImpl.java](../../src/main/java/com/doitdo/domain/notification/application/impl/NotificationServiceImpl.java)** — 5개 구현 추가
- DND 체크/토큰 조회/FCM 호출은 공통 private 메서드 `dispatchFcm(Long userId, String title, String body)` 로 추출 후 재사용 권장.
- 시각 인자는 `LocalTime.now(ZoneId.of("Asia/Seoul"))` 로 내부에서 계산 (호출자 신경 X).

### 3.2 트리거 A — TODO 완료

- **재사용:** [TodoCompletedEvent](../../src/main/java/com/doitdo/domain/todo/event/TodoCompletedEvent.java) 그대로.
- **신규 리스너:** `notification/application/listener/TodoCompletedNotificationListener.java`
  - `TodoCompletedEvent` 수신 → `todoRepository.findByTodoIdAndIsDeletedFalse()` 로 title 조회 → `notificationService.sendTodoDone(userId, todoId, title)` 호출.
  - 기존 `TodoCompletionExpListener` 와 분리(도메인 책임 분리 — exp 가산 vs 알림).

### 3.3 트리거 B — TODO 알림 시각

- **수정:** [TodoAlertScheduler.java](../../src/main/java/com/doitdo/domain/notification/application/scheduler/TodoAlertScheduler.java)
  - 현재 `fcmService.send()` 직접 호출 → `notificationService.sendTodoAlert(todo.getUserId(), todo.getTodoId(), todo.getTitle())` 로 교체.
  - DB 저장/DND 체크가 NotificationService 안에서 일어나므로 스케줄러 로직은 단순화.
- **`Todo.alertTime` 으로 발화** (기존 `findAlertTargets` 쿼리 그대로 사용).

### 3.4 트리거 C — TODO 미루기

- **신규 이벤트:** `todo/event/TodoSnoozedEvent.java`
  ```java
  public record TodoSnoozedEvent(Long userId, Long todoId, java.time.LocalDate fromDate, java.time.LocalDate toDate) {}
  ```
- **수정:** [TodoServiceImpl.snooze()](../../src/main/java/com/doitdo/domain/todo/application/impl/TodoServiceImpl.java#L362) — `snoozeHistoryRepository.save(...)` 직후 `eventPublisher.publishEvent(new TodoSnoozedEvent(userId, todo.getTodoId(), fromDate, todo.getStartDate()))`.
- **신규 리스너:** `notification/application/listener/TodoSnoozedNotificationListener.java`
  - title 조회 → `notificationService.sendTodoSnoozed(...)`.

### 3.5 트리거 D — 다마고치 이별

- **신규 이벤트:** `tamagotchi/event/TamagotchiFarewellEvent.java`
  ```java
  public record TamagotchiFarewellEvent(Long userId, Long beforeUserCharacterId, Long afterUserCharacterId, String beforeCharacterName) {}
  ```
- **수정:** [TamagotchiServiceImpl.approveIndependence()](../../src/main/java/com/doitdo/domain/tamagotchi/application/impl/TamagotchiServiceImpl.java#L346) — `saveHistory(...)` 직후 이벤트 발행.
  - `approved == false` 인 분기에선 발행 X (Codex가 코드 보고 판정 — 거절은 알림 없음).
- **신규 리스너:** `notification/application/listener/TamagotchiFarewellNotificationListener.java`
  - `notificationService.sendTamagotchiFarewell(userId, afterUserCharacterId, beforeCharacterName)`.

### 3.6 트리거 E — 다마고치 성장 (HATCHED + EVOLVED 통합)

- **신규 이벤트:** `tamagotchi/event/TamagotchiGrowthEvent.java`
  ```java
  public record TamagotchiGrowthEvent(Long userId, Long userCharacterId, String beforeStage, String afterStage, String characterName) {}
  ```
- **수정:**
  - [TamagotchiServiceImpl.hatch()](../../src/main/java/com/doitdo/domain/tamagotchi/application/impl/TamagotchiServiceImpl.java#L219) — `saveHistory(... HATCHED ...)` 직후 `new TamagotchiGrowthEvent(userId, ucId, "EGG", "BABY", name)` 발행.
  - [TamagotchiServiceImpl.evolve()](../../src/main/java/com/doitdo/domain/tamagotchi/application/impl/TamagotchiServiceImpl.java#L259) — `saveHistory(... EVOLVED ...)` 직후 `new TamagotchiGrowthEvent(userId, ucId, beforeStage.name(), afterStage.name(), name)` 발행.
- **신규 리스너:** `notification/application/listener/TamagotchiGrowthNotificationListener.java`

### 3.7 ApplicationEventPublisher 주입

- `TamagotchiServiceImpl` 에 **`ApplicationEventPublisher` 신규 주입 필수** (현재 의존 없음을 grep 으로 확인). 생성자 파라미터에 추가하고 final 필드로 보관.
- `TodoServiceImpl` 은 이미 `eventPublisher` 보유 — 그대로 사용.

---

## 4. 영향도 / 회귀 위험

| 영역 | 위험 | 완화 |
|---|---|---|
| TODO 완료 응답 시간 | 리스너가 AFTER_COMMIT 이라 응답 지연 거의 없음 | REQUIRES_NEW + 예외 무시로 격리 |
| 알림함 폭주 | 미루기/완료 등 사용자 행위 알림이 본인에게 즉시 도착 | 본인이 행한 액션 = 의도된 알림. UX 의도 OK. DND 만 적용. |
| **TodoAlertScheduler 동작 변경** | 기존: FCM-only (DB 미기록). 신규: **DB+FCM** 으로 확장 → 그 시점부터 `notification` 테이블에 알림 행이 누적 | 의도된 변경. 운영/QA에 공유 필요. 알림함이 비어 있던 게 정상이었다면 신규 채워짐. |
| 스케줄러 1분 단위 다중 발송 | 동일 분 안에서 같은 alertTime 매칭 todo 가 여러 개여도 각각 1건 발송 | 의도된 동작. 멱등성 필요시 향후 별도 처리. |
| Notification 테이블 증가 | 모든 알림이 DB 저장 → 양 증가 | 기존 EveningReminder 와 같은 정책. 변경 없음. |
| 다마고치 거절 케이스 | farewell 거절 시 알림 X | 위 3.5에 명시 |
| TODO 재완료 | `DONE → TODO → DONE` 시 알림 재발송됨 | 정상 UX. 멱등성 미적용. |

---

## 5. docs 갱신 (필수 — CLAUDE.md 규칙)

- [docs/architecture/overview.md](../architecture/overview.md) — `## 알림 플로우` 섹션(현재 저녁 리마인더 1줄만 존재, line 68 부근)에 본 PR 의 5종 트리거 표를 추가. 표 컬럼: `트리거 / NotificationType / 발화 위치(file) / referenceId / 비고`.
- [docs/api/error-codes.md](../api/error-codes.md) — 변경 없음 (신규 ErrorCode 없음).
- [docs/api/response-format.md](../api/response-format.md) — 변경 없음 (응답 포맷 변경 없음).
- 신규 docs 파일은 만들지 않음.
- Codex 가 같은 PR(=같은 commit set) 안에 docs 변경을 포함해야 한다.

---

## 6. 테스트 계획

기존 notification 테스트가 없음 → **단위 테스트는 신규 작성하지 않음** (스코프 밖).
대신 Codex 완료 후 Sonnet 서브에이전트가 **로컬 부팅 + curl 시나리오 테스트** 수행:

1. 토큰 등록 → TODO 작성 (alertTime = 다음 분) → 1분 대기 → DB `notification` 행 + 로그 확인 (B)
2. 같은 TODO 를 status=DONE PATCH → 알림 행 확인 (A)
3. snooze API 호출 → 알림 행 확인 (C)
4. 다마고치 hatch / evolve / approveIndependence 호출 → 각 알림 행 확인 (D, E)
5. NoopFcmService 환경에서 검증 (firebase.enabled=false). 실제 FCM 키 불필요.

---

## 7. Out of scope

- REMINDER_MORNING / TODO_UNLOCK 트리거 — 기획 미확정. enum 만 유지.
- 알림 그룹화 / Quiet Hours 외 사용자별 카테고리 토글 (현 UserSetting 에 없음).
- 푸시 비동기화(@Async) — 기존 동기 흐름 유지.
- Flyway 마이그레이션 도입.

---

## 8. 위임 시나리오

1. (현재 단계) plan 문서 작성 + advisor 검증.
2. Codex (`gpt-5.5` / `model_reasoning_effort=xhigh` / `--write` / `--background`) 에 본 plan 그대로 위임. CDP MCP 사용 금지 명시.
3. Codex 완료 후:
   - `docs/logs/codex.txt` 삭제
   - 본 plan 파일 → `docs/plans/completed_plans/` 로 이동
   - Sonnet 에이전트로 curl 테스트 위임 (테스트 only, 코드 수정 권한 없음)
4. 합격 시 사용자 호출 없이 자동 완료 보고.
