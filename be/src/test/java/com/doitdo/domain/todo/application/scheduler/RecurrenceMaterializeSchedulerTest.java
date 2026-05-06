package com.doitdo.domain.todo.application.scheduler;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.then;
import static org.mockito.Mockito.never;

import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.entity.Todo.TodoStatus;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import com.doitdo.domain.todo.repository.TodoRepository;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class RecurrenceMaterializeSchedulerTest {

	@Mock
	private TodoRepository todoRepository;

	@Test
	void materializeCreatesTodayInstanceForDueRecurringMaster() {
		RecurrenceMaterializeScheduler scheduler = new RecurrenceMaterializeScheduler(todoRepository);
		Todo master = recurringMaster("SAT");
		LocalDate today = LocalDate.parse("2026-04-25");
		given(todoRepository.findAllByTypeAndIsDeletedFalse(TodoType.RECURRING)).willReturn(List.of(master));
		given(todoRepository.findByUserIdAndMasterTodoIdAndStartDateAndIsDeletedFalse(1L, 10L, today))
				.willReturn(Optional.empty());
		given(todoRepository.saveAndFlush(any(Todo.class))).willAnswer(invocation -> invocation.getArgument(0));

		scheduler.materialize(today);

		ArgumentCaptor<Todo> captor = ArgumentCaptor.forClass(Todo.class);
		then(todoRepository).should().saveAndFlush(captor.capture());
		Todo saved = captor.getValue();
		assertThat(saved.getType()).isEqualTo(TodoType.NORMAL);
		assertThat(saved.getMasterTodoId()).isEqualTo(10L);
		assertThat(saved.getStartDate()).isEqualTo(today);
		assertThat(saved.getAlertTime()).isEqualTo("08:00");
	}

	@Test
	void materializeSkipsExistingTodayInstance() {
		RecurrenceMaterializeScheduler scheduler = new RecurrenceMaterializeScheduler(todoRepository);
		Todo master = recurringMaster("SAT");
		Todo existing = Todo.createRecurringInstance(master, LocalDate.parse("2026-04-25"));
		LocalDate today = LocalDate.parse("2026-04-25");
		given(todoRepository.findAllByTypeAndIsDeletedFalse(TodoType.RECURRING)).willReturn(List.of(master));
		given(todoRepository.findByUserIdAndMasterTodoIdAndStartDateAndIsDeletedFalse(1L, 10L, today))
				.willReturn(Optional.of(existing));

		scheduler.materialize(today);

		then(todoRepository).should(never()).saveAndFlush(any(Todo.class));
	}

	private Todo recurringMaster(String daysOfWeekRaw) {
		return Todo.builder()
				.todoId(10L)
				.userId(1L)
				.title("repeat")
				.type(TodoType.RECURRING)
				.status(TodoStatus.TODO)
				.priority(2)
				.alertTime("08:00")
				.startDate(LocalDate.parse("2026-04-20"))
				.daysOfWeekRaw(daysOfWeekRaw)
				.isDeleted(false)
				.expGranted(false)
				.build();
	}
}
