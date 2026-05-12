package com.doitdo.domain.todo.api.dto.resp;

import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.entity.Todo.TodoStatus;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;

public record CalendarItemResp(
		Long todoId,
		Long masterTodoId,
		LocalDate occurrenceDate,
		boolean isVirtual,
		String title,
		String content,
		String category,
		String colorHex,
		TodoType type,
		Integer priority,
		LocalDate startDate,
		LocalDate endDate,
		List<String> daysOfWeek,
		TodoStatus status,
		LocalDateTime updatedAt,
		int snoozedDays
) {

	public static CalendarItemResp fromActual(
			Todo todo,
			Long masterTodoId,
			String categoryName,
			String colorHex,
			TodoType responseType,
			Set<DayOfWeek> responseDaysOfWeek,
			int snoozedDays) {
		LocalDate occurrenceDate = masterTodoId != null ? todo.getStartDate() : null;
		return new CalendarItemResp(
				todo.getTodoId(),
				masterTodoId,
				occurrenceDate,
				false,
				todo.getTitle(),
				todo.getContent(),
				categoryName,
				colorHex,
				responseType,
				todo.getPriority(),
				todo.getStartDate(),
				todo.getEndDate(),
				toDayOfWeekCodes(responseDaysOfWeek),
				todo.getStatus(),
				todo.getUpdatedAt(),
				snoozedDays
		);
	}

	public static CalendarItemResp fromVirtual(Todo master, String categoryName, String colorHex, LocalDate occurrenceDate) {
		return new CalendarItemResp(
				null,
				master.getTodoId(),
				occurrenceDate,
				true,
				master.getTitle(),
				master.getContent(),
				categoryName,
				colorHex,
				master.getType(),
				master.getPriority(),
				occurrenceDate,
				null,
				toDayOfWeekCodes(master.getDaysOfWeek()),
				TodoStatus.TODO,
				master.getUpdatedAt(),
				0
		);
	}

	private static List<String> toDayOfWeekCodes(Set<DayOfWeek> daysOfWeek) {
		return daysOfWeek == null
				? List.of()
				: daysOfWeek.stream()
						.sorted()
						.map(Todo::toDayOfWeekCode)
						.toList();
	}
}
