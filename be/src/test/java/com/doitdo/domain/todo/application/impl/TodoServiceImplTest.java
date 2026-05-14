package com.doitdo.domain.todo.application.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.argThat;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

import com.doitdo.domain.streak.application.UserStreakService;
import com.doitdo.domain.todo.api.dto.req.TodoCreateReq;
import com.doitdo.domain.todo.api.dto.req.TodoListReq;
import com.doitdo.domain.todo.api.dto.req.TodoPriorityChangeReq;
import com.doitdo.domain.todo.api.dto.req.TodoStatusChangeReq;
import com.doitdo.domain.todo.api.dto.req.TodoUpdateReq;
import com.doitdo.domain.todo.api.dto.resp.TodoDetailResp;
import com.doitdo.domain.todo.api.dto.resp.TodoListResp;
import com.doitdo.domain.todo.application.RecurrenceService;
import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.entity.Todo.TodoStatus;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import com.doitdo.domain.todo.event.TodoCompletedEvent;
import com.doitdo.domain.todo.repository.CategoryRepository;
import com.doitdo.domain.todo.repository.PaletteColorRepository;
import com.doitdo.domain.todo.repository.SnoozeHistoryRepository;
import com.doitdo.domain.todo.repository.TodoListQueryRepository;
import com.doitdo.domain.todo.repository.TodoRepository;
import com.doitdo.domain.todo.repository.TodoRepository.ExcludedDateProjection;
import com.doitdo.domain.todo.repository.projection.TodoListRow;
import com.doitdo.global.cache.CacheEvictHelper;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.TodoErrorCode;
import java.time.LocalDate;
import java.time.LocalDateTime;
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
	private TodoListQueryRepository todoListQueryRepository;

	@Mock
	private CategoryRepository categoryRepository;

	@Mock
	private PaletteColorRepository paletteColorRepository;

	@Mock
	private SnoozeHistoryRepository snoozeHistoryRepository;

	@Mock
	private RecurrenceService recurrenceService;

	@Mock
	private UserStreakService userStreakService;

	@Mock
	private ApplicationEventPublisher eventPublisher;

	@Mock
	private CacheEvictHelper cacheEvictHelper;

	private TodoServiceImpl service;

	@BeforeEach
	void setUp() {
		service = new TodoServiceImpl(
				todoRepository,
				todoListQueryRepository,
				categoryRepository,
				paletteColorRepository,
				snoozeHistoryRepository,
				recurrenceService,
				userStreakService,
				eventPublisher,
				cacheEvictHelper);
	}

	@Test
	void listUsesProjectedRowsWithoutExtraBulkLookups() {
		LocalDate baseDate = LocalDate.parse("2026-05-06");
		TodoListReq req = new TodoListReq("today", null, null, null, baseDate, null, null);
		TodoListRow row = new TodoListRow(
				1L,
				"todo",
				"memo",
				"work",
				null,
				TodoType.NORMAL,
				1,
				"09:00",
				baseDate,
				null,
				"WED,MON",
				TodoStatus.TODO,
				LocalDateTime.parse("2026-05-06T10:00:00"),
				2L);
		given(todoListQueryRepository.findListRows(
				eq(1L),
				eq("today"),
				isNull(),
				isNull(),
				isNull(),
				eq(baseDate),
				any(LocalDate.class),
				isNull(),
				isNull()))
				.willReturn(List.of(row));

		TodoListResp resp = service.list(1L, req);

		assertThat(resp.items()).hasSize(1);
		TodoDetailResp item = resp.items().getFirst();
		assertThat(item.category()).isEqualTo("work");
		assertThat(item.daysOfWeek()).containsExactly("MON", "WED");
		assertThat(item.snoozedDays()).isEqualTo(2);
		assertThat(item.excludedDates()).isEmpty();
		// list 는 NORMAL TODO 에 대해 todoRepository / snoozeHistoryRepository 와는
		// 상호작용하지 않아야 함 (N+1 회피).
		// categoryRepository 와 paletteColorRepository 는 활성 카테고리·색상 맵 빌드를 위해
		// 한 번씩 호출되므로 verifyNoInteractions 대상에서 제외한다.
		verifyNoInteractions(todoRepository, snoozeHistoryRepository);
	}

	@Test
	void listIncludesExcludedDatesForRecurringMasters() {
		LocalDate baseDate = LocalDate.parse("2026-05-06");
		TodoListReq req = new TodoListReq("today", null, null, null, baseDate, null, null);
		TodoListRow row = new TodoListRow(
				10L,
				"repeat",
				"memo",
				"work",
				null,
				TodoType.RECURRING,
				1,
				"09:00",
				baseDate,
				null,
				"WED,MON",
				TodoStatus.TODO,
				LocalDateTime.parse("2026-05-06T10:00:00"),
				2L);
		given(todoListQueryRepository.findListRows(
				eq(1L),
				eq("today"),
				isNull(),
				isNull(),
				isNull(),
				eq(baseDate),
				any(LocalDate.class),
				isNull(),
				isNull()))
				.willReturn(List.of(row));
		given(todoRepository.findExcludedDatesByMasterTodoIds(1L, List.of(10L)))
				.willReturn(List.of(excludedDate(10L, LocalDate.parse("2026-05-14"))));

		TodoListResp resp = service.list(1L, req);

		assertThat(resp.items()).hasSize(1);
		TodoDetailResp item = resp.items().getFirst();
		assertThat(item.category()).isEqualTo("work");
		assertThat(item.daysOfWeek()).containsExactly("MON", "WED");
		assertThat(item.snoozedDays()).isEqualTo(2);
		assertThat(item.excludedDates()).containsExactly(LocalDate.parse("2026-05-14"));
		verifyNoInteractions(snoozeHistoryRepository);
	}

	@Test
	void detailIncludesExcludedDatesForRecurringMaster() {
		Todo master = recurringMaster();
		given(todoRepository.findByTodoIdAndIsDeletedFalse(10L)).willReturn(Optional.of(master));
		given(snoozeHistoryRepository.countByTodoId(10L)).willReturn(0L);
		given(todoRepository.findExcludedDatesByMasterTodoIds(1L, List.of(10L)))
				.willReturn(List.of(excludedDate(10L, LocalDate.parse("2026-05-14"))));

		TodoDetailResp resp = service.detail(1L, 10L);

		assertThat(resp.excludedDates()).containsExactly(LocalDate.parse("2026-05-14"));
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
	void createWithoutPriorityAppendsAfterExistingNonSomedayTodos() {
		given(todoRepository.findMaxPriorityForNonSomeday(1L)).willReturn(2);
		given(todoRepository.save(any(Todo.class))).willAnswer(invocation -> invocation.getArgument(0));
		TodoCreateReq req = new TodoCreateReq(
				"new",
				null,
				null,
				TodoType.NORMAL,
				LocalDate.parse("2026-04-20"),
				null,
				null,
				null,
				null);

		TodoDetailResp resp = service.create(1L, req);

		assertThat(resp.priority()).isEqualTo(3);
		verify(todoRepository).save(argThat(todo -> todo.getPriority() == 3));
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

	@Test
	void changeStatusToDoneMarksFirstCompletedDateBeforePublishingEvent() {
		Todo todo = normalTodo("09:00");
		given(todoRepository.findByTodoIdAndIsDeletedFalse(1L)).willReturn(Optional.of(todo));
		given(snoozeHistoryRepository.countByTodoId(1L)).willReturn(0L);

		LocalDate before = LocalDate.now(java.time.ZoneId.of("Asia/Seoul"));
		service.changeStatus(1L, 1L, new TodoStatusChangeReq(TodoStatus.DONE));
		LocalDate after = LocalDate.now(java.time.ZoneId.of("Asia/Seoul"));

		assertThat(todo.getStatus()).isEqualTo(TodoStatus.DONE);
		assertThat(todo.getFirstCompletedDate()).isIn(before, after);
		verify(userStreakService).recordActivity(1L);
		verify(eventPublisher).publishEvent(any(TodoCompletedEvent.class));
	}

	@Test
	void changeStatusForRecurringMaterializesOccurrenceAndMarksOnlyInstanceDone() {
		Todo master = recurringMaster();
		Todo instance = recurringInstance(master, LocalDate.parse("2026-05-12"));
		given(todoRepository.findByTodoIdAndIsDeletedFalse(10L)).willReturn(Optional.of(master));
		given(recurrenceService.materializeRecurringOccurrence(1L, master, LocalDate.parse("2026-05-12")))
				.willReturn(instance);
		given(snoozeHistoryRepository.countByTodoId(25L)).willReturn(0L);

		TodoDetailResp resp = service.changeStatus(
				1L,
				10L,
				new TodoStatusChangeReq(TodoStatus.DONE, LocalDate.parse("2026-05-12")));

		assertThat(master.getStatus()).isEqualTo(TodoStatus.TODO);
		assertThat(instance.getStatus()).isEqualTo(TodoStatus.DONE);
		assertThat(resp.todoId()).isEqualTo(25L);
		verify(userStreakService).recordActivity(1L);
		verify(eventPublisher).publishEvent(any(TodoCompletedEvent.class));
	}

	@Test
	void changeStatusForRecurringRequiresOccurrenceDate() {
		Todo master = recurringMaster();
		given(todoRepository.findByTodoIdAndIsDeletedFalse(10L)).willReturn(Optional.of(master));

		assertThatThrownBy(() -> service.changeStatus(1L, 10L, new TodoStatusChangeReq(TodoStatus.DONE)))
				.isInstanceOf(CustomException.class)
				.satisfies(ex -> assertThat(((CustomException) ex).getErrorCode())
						.isEqualTo(TodoErrorCode.T03_004));

		verifyNoInteractions(recurrenceService, userStreakService, eventPublisher);
	}

	@Test
	void deleteRecurringOnlyMaterializesOccurrenceAndSoftDeletesOnlyInstance() {
		Todo master = recurringMaster();
		Todo instance = recurringInstance(master, LocalDate.parse("2026-05-12"));
		given(todoRepository.findByTodoIdAndIsDeletedFalse(10L)).willReturn(Optional.of(master));
		given(recurrenceService.materializeRecurringOccurrence(1L, master, LocalDate.parse("2026-05-12")))
				.willReturn(instance);

		service.delete(1L, 10L, "only", LocalDate.parse("2026-05-12"));

		assertThat(master.getIsDeleted()).isFalse();
		assertThat(instance.getIsDeleted()).isTrue();
		verify(cacheEvictHelper).evictUserTodosAfterCommit(1L);
		verify(cacheEvictHelper).evictTodoItemAfterCommit(1L, 10L);
		verify(cacheEvictHelper).evictTodoItemAfterCommit(1L, 25L);
	}

	@Test
	void deleteRecurringFromCutsMasterAndSoftDeletesFutureInstances() {
		Todo master = recurringMaster();
		Todo future = recurringInstance(master, LocalDate.parse("2026-05-19"));
		given(todoRepository.findByTodoIdAndIsDeletedFalse(10L)).willReturn(Optional.of(master));
		given(todoRepository.findAllByUserIdAndMasterTodoIdAndStartDateGreaterThanEqualAndIsDeletedFalse(
				1L,
				10L,
				LocalDate.parse("2026-05-12")))
				.willReturn(List.of(future));

		service.delete(1L, 10L, "from", LocalDate.parse("2026-05-12"));

		assertThat(master.getEndDate()).isEqualTo(LocalDate.parse("2026-05-11"));
		assertThat(future.getIsDeleted()).isTrue();
		verify(cacheEvictHelper).evictUserTodosAfterCommit(1L);
		verify(cacheEvictHelper).evictTodoItemAfterCommit(1L, 10L);
	}

	@Test
	void updateRecurringOnlyMaterializesOccurrenceAndUpdatesOnlyInstance() {
		Todo master = recurringMaster();
		Todo instance = recurringInstance(master, LocalDate.parse("2026-05-12"));
		given(todoRepository.findByTodoIdAndIsDeletedFalse(10L)).willReturn(Optional.of(master));
		given(recurrenceService.materializeRecurringOccurrence(1L, master, LocalDate.parse("2026-05-12")))
				.willReturn(instance);
		given(snoozeHistoryRepository.countByTodoId(25L)).willReturn(0L);

		TodoDetailResp resp = service.update(
				1L,
				10L,
				new TodoUpdateReq("하루만 수정", "메모", null, null, null, null, null, null, false),
				"only",
				LocalDate.parse("2026-05-12"));

		assertThat(master.getTitle()).isEqualTo("repeat");
		assertThat(instance.getTitle()).isEqualTo("하루만 수정");
		assertThat(instance.getContent()).isEqualTo("메모");
		assertThat(resp.todoId()).isEqualTo(25L);
	}

	@Test
	void updateRecurringFromCutsMasterDeletesFutureInstancesAndCreatesNewMaster() {
		Todo master = recurringMaster();
		Todo future = recurringInstance(master, LocalDate.parse("2026-05-19"));
		given(todoRepository.findByTodoIdAndIsDeletedFalse(10L)).willReturn(Optional.of(master));
		given(todoRepository.findAllByUserIdAndMasterTodoIdAndStartDateGreaterThanEqualAndIsDeletedFalse(
				1L,
				10L,
				LocalDate.parse("2026-05-12")))
				.willReturn(List.of(future));
		given(todoRepository.save(any(Todo.class))).willAnswer(invocation -> invocation.getArgument(0));

		TodoDetailResp resp = service.update(
				1L,
				10L,
				new TodoUpdateReq("이후 수정", "새 메모", null, null, null, null, Set.of("TUE"), null, false),
				"from",
				LocalDate.parse("2026-05-12"));

		assertThat(master.getEndDate()).isEqualTo(LocalDate.parse("2026-05-11"));
		assertThat(future.getIsDeleted()).isTrue();
		verify(todoRepository).save(argThat(newMaster ->
				newMaster.getType() == TodoType.RECURRING
						&& newMaster.getTitle().equals("이후 수정")
						&& newMaster.getStartDate().equals(LocalDate.parse("2026-05-12"))
						&& newMaster.getPriority().equals(master.getPriority())));
		assertThat(resp.title()).isEqualTo("이후 수정");
	}

	@Test
	void updateRecurringFromAllowsCutDateThatMatchesNewDaysOfWeek() {
		Todo master = recurringMaster();
		given(todoRepository.findByTodoIdAndIsDeletedFalse(10L)).willReturn(Optional.of(master));
		given(todoRepository.findAllByUserIdAndMasterTodoIdAndStartDateGreaterThanEqualAndIsDeletedFalse(
				1L,
				10L,
				LocalDate.parse("2026-05-14")))
				.willReturn(List.of());
		given(todoRepository.save(any(Todo.class))).willAnswer(invocation -> invocation.getArgument(0));

		TodoDetailResp resp = service.update(
				1L,
				10L,
				new TodoUpdateReq("요일 변경", "새 메모", null, null, null, null, Set.of("THU"), null, false),
				"from",
				LocalDate.parse("2026-05-14"));

		assertThat(master.getEndDate()).isEqualTo(LocalDate.parse("2026-05-13"));
		verify(todoRepository).save(argThat(newMaster ->
				newMaster.getStartDate().equals(LocalDate.parse("2026-05-14"))
						&& newMaster.getDaysOfWeek().contains(java.time.DayOfWeek.THURSDAY)));
		assertThat(resp.title()).isEqualTo("요일 변경");
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

	private Todo recurringMaster() {
		return Todo.builder()
				.todoId(10L)
				.userId(1L)
				.title("repeat")
				.type(TodoType.RECURRING)
				.status(TodoStatus.TODO)
				.priority(1)
				.startDate(LocalDate.parse("2026-05-01"))
				.daysOfWeekRaw("TUE")
				.isDeleted(false)
				.expGranted(false)
				.build();
	}

	private Todo recurringInstance(Todo master, LocalDate occurrenceDate) {
		return Todo.builder()
				.todoId(25L)
				.userId(master.getUserId())
				.title(master.getTitle())
				.type(TodoType.NORMAL)
				.status(TodoStatus.TODO)
				.priority(master.getPriority())
				.startDate(occurrenceDate)
				.masterTodoId(master.getTodoId())
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

	private ExcludedDateProjection excludedDate(Long masterTodoId, LocalDate occurrenceDate) {
		return new ExcludedDateProjection() {
			@Override
			public Long getMasterTodoId() {
				return masterTodoId;
			}

			@Override
			public LocalDate getOccurrenceDate() {
				return occurrenceDate;
			}
		};
	}
}
