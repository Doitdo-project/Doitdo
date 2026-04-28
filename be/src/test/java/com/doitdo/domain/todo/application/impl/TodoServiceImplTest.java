package com.doitdo.domain.todo.application.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.BDDMockito.given;

import com.doitdo.domain.streak.application.UserStreakService;
import com.doitdo.domain.todo.api.dto.req.TodoCreateReq;
import com.doitdo.domain.todo.api.dto.req.TodoPriorityChangeReq;
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
import java.util.List;
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

	@Test
	void updateClearsContentWhenNullIsExplicitlySent() {
		Todo todo = todoWithContent("기존 메모");
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
				null,
				null);

		TodoDetailResp resp = service.update(1L, 1L, req);

		assertThat(resp.content()).isNull();
		assertThat(todo.getContent()).isNull();
	}

	@Test
	void updateOverwritesContentWhenNewValueProvided() {
		Todo todo = todoWithContent("기존 메모");
		given(todoRepository.findByTodoIdAndIsDeletedFalse(1L)).willReturn(Optional.of(todo));
		given(snoozeHistoryRepository.countByTodoId(1L)).willReturn(0L);

		TodoUpdateReq req = new TodoUpdateReq(
				null,
				"새 메모",
				null,
				null,
				null,
				null,
				null,
				null,
				null);

		TodoDetailResp resp = service.update(1L, 1L, req);

		assertThat(resp.content()).isEqualTo("새 메모");
		assertThat(todo.getContent()).isEqualTo("새 메모");
	}

	@Test
	void changePriorityReordersOnlyNonSomedayTodos() {
		Todo a = todo(1L, TodoType.NORMAL, 1);
		Todo b = todo(2L, TodoType.PERIOD, 2);
		Todo c = todo(3L, TodoType.SOMEDAY, 1);
		Todo d = todo(4L, TodoType.NORMAL, 3);
		given(todoRepository.findByTodoIdAndIsDeletedFalse(4L)).willReturn(Optional.of(d));
		given(todoRepository.findReorderTargetsForNonSomeday(1L)).willReturn(List.of(a, b, d));
		given(snoozeHistoryRepository.countByTodoId(4L)).willReturn(0L);

		service.changePriority(1L, 4L, new TodoPriorityChangeReq(1));

		assertThat(d.getPriority()).isEqualTo(1);
		assertThat(a.getPriority()).isEqualTo(2);
		assertThat(b.getPriority()).isEqualTo(3);
		assertThat(c.getPriority()).isEqualTo(1);
	}

	@Test
	void changePriorityReordersOnlySomedayTodos() {
		Todo a = todo(1L, TodoType.NORMAL, 1);
		Todo x = todo(2L, TodoType.SOMEDAY, 1);
		Todo y = todo(3L, TodoType.SOMEDAY, 2);
		given(todoRepository.findByTodoIdAndIsDeletedFalse(3L)).willReturn(Optional.of(y));
		given(todoRepository.findReorderTargetsForSomeday(1L)).willReturn(List.of(x, y));
		given(snoozeHistoryRepository.countByTodoId(3L)).willReturn(0L);

		service.changePriority(1L, 3L, new TodoPriorityChangeReq(1));

		assertThat(y.getPriority()).isEqualTo(1);
		assertThat(x.getPriority()).isEqualTo(2);
		assertThat(a.getPriority()).isEqualTo(1);
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

	private Todo todoWithContent(String content) {
		return Todo.builder()
				.todoId(1L)
				.userId(1L)
				.title("todo")
				.content(content)
				.type(TodoType.NORMAL)
				.status(TodoStatus.TODO)
				.priority(1)
				.startDate(LocalDate.parse("2026-04-20"))
				.isDeleted(false)
				.expGranted(false)
				.build();
	}

	private Todo todo(Long todoId, TodoType type, Integer priority) {
		return Todo.builder()
				.todoId(todoId)
				.userId(1L)
				.title("todo" + todoId)
				.type(type)
				.status(TodoStatus.TODO)
				.priority(priority)
				.startDate(LocalDate.parse("2026-04-20"))
				.isDeleted(false)
				.expGranted(false)
				.build();
	}
}
