# 도메인 이벤트 컨벤션 (Domain Events)

> 최초 도입: `be/feat/todo-exp-system` PR (2026-04)
> 첫 구현 사례: `TodoCompletedEvent` → `TodoCompletionExpListener`

---

## 1. 이벤트 네이밍

```
{도메인}{동작}Event   // 과거형 동사
```

예시:
- `TodoCompletedEvent` (TODO 가 완료됨)
- `UserRegisteredEvent` (향후)
- `CharacterEvolvedEvent` (향후)

이벤트 이름은 **이미 일어난 사실**을 과거형으로 표현한다. 명령형(`CompleteTodoEvent`) 이나 현재형(`TodoCompleteEvent`) 사용 금지.

---

## 2. 이벤트 payload 규칙

- **`record` 타입** 사용 (불변, 간결).
- payload 에는 **primitive / id 값만** 포함. 엔티티 객체 직접 담지 말 것.
  - 이유: AFTER_COMMIT 리스너는 별도 TX 에서 실행되므로 영속성 컨텍스트 공유 불가. 엔티티를 payload 로 넘기면 LazyInitializationException 등 예기치 않은 버그 발생.
- 예시:

```java
// 올바름
public record TodoCompletedEvent(Long userId, Long todoId) {}

// 금지
public record TodoCompletedEvent(Todo todo) {} // 엔티티 직접 포함 금지
```

---

## 3. 파일 위치

| 역할 | 위치 | 규칙 |
|------|------|------|
| 이벤트 클래스 | 발행 도메인의 `event/` 패키지 | `domain/todo/event/TodoCompletedEvent.java` |
| 리스너 | 구독 도메인의 `application/listener/` 패키지 | `domain/tamagotchi/application/listener/TodoCompletionExpListener.java` |

의존 방향: **구독 도메인이 발행 도메인의 이벤트를 import** 한다. 발행 도메인은 구독 도메인을 모른다.

```
todo.event.TodoCompletedEvent   ← tamagotchi.application.listener.TodoCompletionExpListener
```

---

## 4. 트랜잭션 경계 표준

```java
@TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
@Transactional(propagation = Propagation.REQUIRES_NEW)
public void onXxxCompleted(XxxEvent event) { ... }
```

- `AFTER_COMMIT`: 발행 TX 가 커밋된 뒤에만 리스너 실행. 발행 TX 가 롤백되면 이벤트도 처리 안 됨.
- `REQUIRES_NEW`: 리스너 로직을 별도 TX 로 실행. 리스너 실패가 발행 TX 에 영향 주지 않음.

두 어노테이션은 **반드시 함께** 사용한다. 어느 하나만 사용하면 TX 경계가 의도와 달라질 수 있다.

---

## 5. 멱등성 책임

리스너가 멱등성을 담보한다. 발행자는 상태 전이만 감지하고 이벤트를 발행한다.

구현 패턴:
```java
if (Boolean.TRUE.equals(entity.getProcessedFlag())) {
    return; // 이미 처리됨 — skip
}
// 처리 로직
entity.markProcessed(); // 마킹
```

같은 이벤트가 두 번 도착하더라도 side-effect 는 한 번만 발생해야 한다.

---

## 6. 이벤트 소실 리스크

`AFTER_COMMIT` 이후 JVM 크래시 또는 네트워크 분리가 발생하면 해당 이벤트는 소실된다 (수 ms 의 창 존재). 현재 MVP 단계에서는 이 리스크를 수용한다. 이벤트 소실이 비즈니스 치명적인 경우에는 별도 스토리에서 **Outbox 패턴** 도입을 검토한다.

---

## 7. Spring ApplicationEventPublisher 발행

```java
@RequiredArgsConstructor
public class XxxServiceImpl {
    private final ApplicationEventPublisher eventPublisher;

    public void doSomething() {
        // ... 상태 변경
        if (조건) {
            eventPublisher.publishEvent(new XxxEvent(id1, id2));
        }
    }
}
```

발행은 항상 **조건부**로 한다. 상태가 이미 해당 단계면 이벤트를 발행하지 않는다 (중복 발행 방지).

---

## 8. 과거 Todo 경험치 제외 정책 (S14P31D107-475)

`TodoCompletionExpListener` 는 `expGranted` 멱등성 체크 직후, UC 조회 전에 **과거 기준일 가드**를 수행한다.

### 기준일 결정 규칙

| TodoType | 기준일 (criteriaDate) |
|---|---|
| `SOMEDAY` | `null` → 가드 통과 (날짜 무관 지급) |
| `PERIOD` | `endDate != null` 이면 `endDate`, 아니면 `startDate` |
| `NORMAL` / 그 외 | `startDate` |

- `criteriaDate.isBefore(today)` 이면 `return` (skip). `expGranted` 마킹 없음.
- `today` = `LocalDate.now(ZoneId.of("Asia/Seoul"))` (KST 기준)

### 설계 의도

- 날짜가 지난 Todo 를 뒤늦게 완료해도 경험치를 받을 수 없다.
- `SOMEDAY` 는 날짜 개념이 없는 타입이므로 언제 완료해도 지급한다.
- 스킵 시 `expGranted` 를 마킹하지 않는다 — 날짜 오류가 수정되는 경우는 없으므로 재진입 시에도 동일하게 스킵된다.
