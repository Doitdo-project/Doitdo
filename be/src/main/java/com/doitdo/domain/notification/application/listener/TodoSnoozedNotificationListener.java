package com.doitdo.domain.notification.application.listener;

import com.doitdo.domain.notification.application.NotificationService;
import com.doitdo.domain.todo.event.TodoSnoozedEvent;
import com.doitdo.domain.todo.repository.TodoRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * TODO 미루기 이벤트를 구독해 FCM 알림을 발송하는 리스너.
 *
 * <p>설계 포인트:
 * <ul>
 *   <li>{@code AFTER_COMMIT}: snooze 저장이 커밋된 뒤에만 발동</li>
 *   <li>{@code REQUIRES_NEW}: 알림 처리를 별도 TX 로 격리 → 알림 실패가 snooze 에 영향 없음</li>
 * </ul>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class TodoSnoozedNotificationListener {

	private final TodoRepository todoRepository;
	private final NotificationService notificationService;

	@TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
	@Transactional(propagation = Propagation.REQUIRES_NEW)
	public void onTodoSnoozed(TodoSnoozedEvent event) {
		String title = todoRepository.findByTodoIdAndIsDeletedFalse(event.todoId())
				.map(todo -> todo.getTitle())
				.orElse(null);

		if (title == null) {
			log.warn("[todo-snoozed] todo not found; notification skipped todoId={}", event.todoId());
			return;
		}

		notificationService.sendTodoSnoozed(event.userId(), event.todoId(), title, event.toDate());
	}
}
