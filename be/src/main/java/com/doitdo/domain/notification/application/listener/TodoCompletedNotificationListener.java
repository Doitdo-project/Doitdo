package com.doitdo.domain.notification.application.listener;

import com.doitdo.domain.notification.application.NotificationService;
import com.doitdo.domain.todo.event.TodoCompletedEvent;
import com.doitdo.domain.todo.repository.TodoRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * TODO DONE 전이 이벤트를 구독해 FCM 알림을 발송하는 리스너.
 *
 * <p>설계 포인트:
 * <ul>
 *   <li>{@code AFTER_COMMIT}: Todo 저장이 커밋된 뒤에만 발동 → Todo 가 롤백되면 알림도 발송 안 됨</li>
 *   <li>{@code REQUIRES_NEW}: 알림 처리를 별도 TX 로 격리 → 알림 실패가 Todo 상태에 영향 없음</li>
 *   <li>기존 {@link com.doitdo.domain.tamagotchi.application.listener.TodoCompletionExpListener} 와 분리
 *       (도메인 책임 분리 — exp 가산 vs 알림)</li>
 * </ul>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class TodoCompletedNotificationListener {

	private final TodoRepository todoRepository;
	private final NotificationService notificationService;

	@TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
	@Transactional(propagation = Propagation.REQUIRES_NEW)
	public void onTodoCompleted(TodoCompletedEvent event) {
		String title = todoRepository.findByTodoIdAndIsDeletedFalse(event.todoId())
				.map(todo -> todo.getTitle())
				.orElse(null);

		if (title == null) {
			log.warn("[todo-done] todo not found; notification skipped todoId={}", event.todoId());
			return;
		}

		notificationService.sendTodoDone(event.userId(), event.todoId(), title);
	}
}
