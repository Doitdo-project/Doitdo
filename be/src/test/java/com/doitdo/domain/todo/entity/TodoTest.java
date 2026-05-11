package com.doitdo.domain.todo.entity;

import static org.assertj.core.api.Assertions.assertThat;

import com.doitdo.domain.todo.entity.Todo.TodoStatus;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import java.time.LocalDate;
import java.time.ZoneId;
import org.junit.jupiter.api.Test;

class TodoTest {

	private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

	@Test
	void changeStatusSetsDoneDateWhenTodoBecomesDone() {
		Todo todo = todo(TodoStatus.TODO, null);

		LocalDate before = LocalDate.now(SEOUL);
		todo.changeStatus(TodoStatus.DONE);
		LocalDate after = LocalDate.now(SEOUL);

		assertThat(todo.getStatus()).isEqualTo(TodoStatus.DONE);
		assertThat(todo.getDoneDate()).isIn(before, after);
	}

	@Test
	void changeStatusSetsDoneDateWhenInProgressBecomesDone() {
		Todo todo = todo(TodoStatus.IN_PROGRESS, null);

		LocalDate before = LocalDate.now(SEOUL);
		todo.changeStatus(TodoStatus.DONE);
		LocalDate after = LocalDate.now(SEOUL);

		assertThat(todo.getStatus()).isEqualTo(TodoStatus.DONE);
		assertThat(todo.getDoneDate()).isIn(before, after);
	}

	@Test
	void changeStatusClearsDoneDateWhenDoneBecomesTodo() {
		Todo todo = todo(TodoStatus.DONE, LocalDate.parse("2026-04-20"));

		todo.changeStatus(TodoStatus.TODO);

		assertThat(todo.getStatus()).isEqualTo(TodoStatus.TODO);
		assertThat(todo.getDoneDate()).isNull();
	}

	@Test
	void changeStatusKeepsDoneDateWhenDoneStaysDone() {
		LocalDate existingDoneDate = LocalDate.parse("2026-04-20");
		Todo todo = todo(TodoStatus.DONE, existingDoneDate);

		todo.changeStatus(TodoStatus.DONE);

		assertThat(todo.getStatus()).isEqualTo(TodoStatus.DONE);
		assertThat(todo.getDoneDate()).isEqualTo(existingDoneDate);
	}

	@Test
	void markFirstCompletedIfAbsentSetsOnlyOnceAcrossUndoRedo() {
		Todo todo = todo(TodoStatus.TODO, null);
		LocalDate firstCompletedDate = LocalDate.parse("2026-05-07");
		LocalDate laterDate = firstCompletedDate.plusDays(1);

		for (int i = 0; i < 5; i++) {
			todo.changeStatus(TodoStatus.DONE);
			todo.markFirstCompletedIfAbsent(i == 0 ? firstCompletedDate : laterDate);
			todo.changeStatus(TodoStatus.TODO);
		}

		assertThat(todo.getFirstCompletedDate()).isEqualTo(firstCompletedDate);
		assertThat(todo.getDoneDate()).isNull();
	}

	private Todo todo(TodoStatus status, LocalDate doneDate) {
		return Todo.builder()
				.userId(1L)
				.title("todo")
				.type(TodoType.SOMEDAY)
				.status(status)
				.doneDate(doneDate)
				.priority(1)
				.isDeleted(false)
				.expGranted(false)
				.build();
	}
}
