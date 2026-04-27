package com.doitdo.domain.notification.application.listener;

import com.doitdo.domain.todo.event.TodoCompletedEvent;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * TODO DONE 전이 알림은 현재 비활성화 상태다.
 */
@Component
public class TodoCompletedNotificationListener {

	@TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
	@Transactional(propagation = Propagation.REQUIRES_NEW)
	public void onTodoCompleted(TodoCompletedEvent event) {
		// TODO 완료 알림은 현재 비활성화한다.
	}
}
