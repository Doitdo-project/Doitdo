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
 * TODO 미루기 알림은 현재 비활성화 상태다.
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
		// 비활성화: TODO 미루기 알림은 현재 발송하지 않는다.
	}
}
