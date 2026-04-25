package com.doitdo.domain.todo.application.impl;

import static org.assertj.core.api.Assertions.assertThat;

import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.entity.Todo.TodoStatus;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;

class CalendarOccurrenceGeneratorTest {

	@Test
	void generateReturnsOnlyMatchingDaysOfWeekInsideRequestedRange() {
		Todo master = recurringMaster(
				LocalDate.parse("2026-04-20"),
				LocalDate.parse("2026-04-26"),
				"MON,WED,FRI");

		List<LocalDate> occurrences = CalendarOccurrenceGenerator.generate(
				master,
				LocalDate.parse("2026-04-21"),
				LocalDate.parse("2026-04-25"));

		assertThat(occurrences).containsExactly(
				LocalDate.parse("2026-04-22"),
				LocalDate.parse("2026-04-24"));
	}

	@Test
	void generateStopsAtMasterEndDate() {
		Todo master = recurringMaster(
				LocalDate.parse("2026-04-20"),
				LocalDate.parse("2026-04-22"),
				"MON,WED,FRI");

		List<LocalDate> occurrences = CalendarOccurrenceGenerator.generate(
				master,
				LocalDate.parse("2026-04-20"),
				LocalDate.parse("2026-04-30"));

		assertThat(occurrences).containsExactly(
				LocalDate.parse("2026-04-20"),
				LocalDate.parse("2026-04-22"));
	}

	private Todo recurringMaster(LocalDate startDate, LocalDate endDate, String daysOfWeekRaw) {
		return Todo.builder()
				.todoId(1L)
				.userId(1L)
				.title("repeat")
				.type(TodoType.RECURRING)
				.status(TodoStatus.TODO)
				.priority(1)
				.startDate(startDate)
				.endDate(endDate)
				.daysOfWeekRaw(daysOfWeekRaw)
				.isDeleted(false)
				.expGranted(false)
				.build();
	}
}
