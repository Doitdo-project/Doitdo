package com.doitdo.domain.todo.repository;

import static org.assertj.core.api.Assertions.assertThat;

import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.entity.Todo.TodoStatus;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import com.doitdo.global.config.JpaAuditingConfig;
import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.context.annotation.Import;

@DataJpaTest
@Import(JpaAuditingConfig.class)
class TodoSpecificationsTest {

	private static final Long USER_ID = 1L;
	private static final LocalDate TODAY = LocalDate.parse("2026-04-30");

	@Autowired
	private TodoRepository todoRepository;

	@Test
	void excludeExpiredSomedayDoneIncludesSomedayDoneCompletedToday() {
		Todo todo = save(TodoType.SOMEDAY, TodoStatus.DONE, TODAY);

		assertVisible(todo);
	}

	@Test
	void excludeExpiredSomedayDoneExcludesSomedayDoneCompletedBeforeToday() {
		Todo todo = save(TodoType.SOMEDAY, TodoStatus.DONE, TODAY.minusDays(1));

		assertNotVisible(todo);
	}

	@Test
	void excludeExpiredSomedayDoneIncludesSomedayDoneWithoutDoneDate() {
		Todo todo = save(TodoType.SOMEDAY, TodoStatus.DONE, null);

		assertVisible(todo);
	}

	@Test
	void excludeExpiredSomedayDoneIncludesSomedayTodo() {
		Todo todo = save(TodoType.SOMEDAY, TodoStatus.TODO, TODAY.minusDays(1));

		assertVisible(todo);
	}

	@Test
	void excludeExpiredSomedayDoneIncludesSomedayInProgress() {
		Todo todo = save(TodoType.SOMEDAY, TodoStatus.IN_PROGRESS, TODAY.minusDays(1));

		assertVisible(todo);
	}

	@Test
	void excludeExpiredSomedayDoneIncludesNormalDoneCompletedBeforeToday() {
		Todo todo = save(TodoType.NORMAL, TodoStatus.DONE, TODAY.minusDays(1));

		assertVisible(todo);
	}

	@Test
	void countPendingByUserIdAndTodayCountsOnlyTodayVisiblePendingTodos() {
		saveWithDates(TodoType.NORMAL, TodoStatus.TODO, TODAY, null);
		saveWithDates(TodoType.NORMAL, TodoStatus.TODO, TODAY.minusDays(1), null);
		saveWithDates(TodoType.NORMAL, TodoStatus.TODO, TODAY.plusDays(1), null);
		saveWithDates(TodoType.PERIOD, TodoStatus.IN_PROGRESS, TODAY.minusDays(1), TODAY.plusDays(1));
		saveWithDates(TodoType.PERIOD, TodoStatus.TODO, TODAY.minusDays(3), TODAY.minusDays(1));
		saveWithDates(TodoType.SOMEDAY, TodoStatus.TODO, null, null);
		saveWithDates(TodoType.RECURRING, TodoStatus.TODO, TODAY, null);
		saveWithDates(TodoType.NORMAL, TodoStatus.DONE, TODAY, null);

		long count = todoRepository.countPendingByUserIdAndToday(USER_ID, TODAY);

		assertThat(count).isEqualTo(2);
	}

	@Test
	void excludeExpiredSomedayDoneIncludesPeriodDoneCompletedBeforeToday() {
		Todo todo = save(TodoType.PERIOD, TodoStatus.DONE, TODAY.minusDays(1));

		assertVisible(todo);
	}

	private void assertVisible(Todo todo) {
		assertThat(visibleTodos())
				.extracting(Todo::getTodoId)
				.contains(todo.getTodoId());
	}

	private void assertNotVisible(Todo todo) {
		assertThat(visibleTodos())
				.extracting(Todo::getTodoId)
				.doesNotContain(todo.getTodoId());
	}

	private List<Todo> visibleTodos() {
		return todoRepository.findAll(
				TodoSpecifications.ownerAndActive(USER_ID)
						.and(TodoSpecifications.excludeExpiredSomedayDone(TODAY))
		);
	}

	private Todo save(TodoType type, TodoStatus status, LocalDate doneDate) {
		return todoRepository.saveAndFlush(Todo.builder()
				.userId(USER_ID)
				.title(type.name() + " " + status.name())
				.type(type)
				.status(status)
				.doneDate(doneDate)
				.priority(1)
				.startDate(type == TodoType.SOMEDAY ? null : TODAY)
				.endDate(type == TodoType.PERIOD ? TODAY.plusDays(1) : null)
				.isDeleted(false)
				.expGranted(false)
				.build());
	}

	private Todo saveWithDates(TodoType type, TodoStatus status, LocalDate startDate, LocalDate endDate) {
		return todoRepository.saveAndFlush(Todo.builder()
				.userId(USER_ID)
				.title(type.name())
				.type(type)
				.status(status)
				.priority(1)
				.startDate(startDate)
				.endDate(endDate)
				.isDeleted(false)
				.expGranted(false)
				.build());
	}
}
