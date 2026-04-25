package com.doitdo.domain.todo.application.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.BDDMockito.given;

import com.doitdo.domain.streak.application.UserStreakService;
import com.doitdo.domain.todo.api.dto.req.TodoCreateReq;
import com.doitdo.domain.todo.api.dto.req.TodoUpdateReq;
import com.doitdo.domain.todo.api.dto.resp.TodoDetailResp;
import com.doitdo.domain.todo.application.RecurrenceService;
import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.entity.Todo.TodoStatus;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import com.doitdo.domain.todo.repository.CategoryRepository;
import com.doitdo.domain.todo.repository.SnoozeHistoryRepository;
import com.doitdo.domain.todo.repository.TodoRepository;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.TodoErrorCode;
import java.time.LocalDate;
import java.util.Optional;
import java.util.Set;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;

@ExtendWith(MockitoExtension.class)
class TodoServiceImplTest {

	@Mock
	private TodoRepository todoRepository;

	@Mock
	private CategoryRepository categoryRepository;

	@Mock
	private SnoozeHistoryRepository snoozeHistoryRepository;

	@Mock
	private RecurrenceService recurrenceService;

	@Mock
	private UserStreakService userStreakService;

	@Mock
	private ApplicationEventPublisher eventPublisher;

	private TodoServiceImpl service;

	@BeforeEach
	void setUp() {
		service = new TodoServiceImpl(
				todoRepository,
				categoryRepository,
				snoozeHistoryRepository,
				recurrenceService,
				userStreakService,
				eventPublisher);
	}

	@Test
	void createRecurringRequiresDaysOfWeek() {
		TodoCreateReq req = new TodoCreateReq(
				"repeat",
				null,
				null,
				TodoType.RECURRING,
				LocalDate.parse("2026-04-20"),
				null,
				null,
				null,
				null);

		assertThatThrownBy(() -> service.create(1L, req))
				.isInstanceOf(CustomException.class)
				.satisfies(ex -> assertThat(((CustomException) ex).getErrorCode())
						.isEqualTo(TodoErrorCode.TODO_RECURRING_DAYS_OF_WEEK_REQUIRED));
	}

	@Test
	void createRecurringRequiresStartDateDayToBeIncludedInDaysOfWeek() {
		TodoCreateReq req = new TodoCreateReq(
				"repeat",
				null,
				null,
				TodoType.RECURRING,
				LocalDate.parse("2026-04-20"),
				null,
				Set.of("TUE"),
				null,
				null);

		assertThatThrownBy(() -> service.create(1L, req))
				.isInstanceOf(CustomException.class)
				.satisfies(ex -> assertThat(((CustomException) ex).getErrorCode())
						.isEqualTo(TodoErrorCode.TODO_RECURRING_START_DATE_DAY_MISMATCH));
	}

	@Test
	void updateChangesAlertTimeWhenClearAlertTimeIsFalse() {
		Todo todo = normalTodo("09:00");
		given(todoRepository.findByTodoIdAndIsDeletedFalse(1L)).willReturn(Optional.of(todo));
		given(snoozeHistoryRepository.countByTodoId(1L)).willReturn(0L);

		TodoUpdateReq req = new TodoUpdateReq(
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				"20:00",
				false);

		TodoDetailResp resp = service.update(1L, 1L, req);

		assertThat(resp.alertTime()).isEqualTo("20:00");
		assertThat(todo.getAlertTime()).isEqualTo("20:00");
	}

	@Test
	void updateClearAlertTimeWinsOverAlertTime() {
		Todo todo = normalTodo("09:00");
		given(todoRepository.findByTodoIdAndIsDeletedFalse(1L)).willReturn(Optional.of(todo));
		given(snoozeHistoryRepository.countByTodoId(1L)).willReturn(0L);

		TodoUpdateReq req = new TodoUpdateReq(
				null,
				null,
				null,
				null,
				null,
				null,
				null,
				"20:00",
				true);

		TodoDetailResp resp = service.update(1L, 1L, req);

		assertThat(resp.alertTime()).isNull();
		assertThat(todo.getAlertTime()).isNull();
	}

	private Todo normalTodo(String alertTime) {
		return Todo.builder()
				.todoId(1L)
				.userId(1L)
				.title("todo")
				.type(TodoType.NORMAL)
				.status(TodoStatus.TODO)
				.priority(1)
				.alertTime(alertTime)
				.startDate(LocalDate.parse("2026-04-20"))
				.isDeleted(false)
				.expGranted(false)
				.build();
	}
}
