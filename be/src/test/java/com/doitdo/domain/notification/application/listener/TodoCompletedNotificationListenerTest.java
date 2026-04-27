package com.doitdo.domain.notification.application.listener;

import static org.mockito.BDDMockito.then;

import com.doitdo.domain.todo.event.TodoCompletedEvent;
import com.doitdo.domain.todo.repository.TodoRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class TodoCompletedNotificationListenerTest {

	@Mock
	private TodoRepository todoRepository;

	@Test
	void onTodoCompletedDoesNotSendNotification() {
		TodoCompletedNotificationListener listener = new TodoCompletedNotificationListener();

		listener.onTodoCompleted(new TodoCompletedEvent(1L, 10L));

		then(todoRepository).shouldHaveNoInteractions();
	}
}
