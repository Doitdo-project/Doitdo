package com.doitdo.domain.todo.api.dto.resp;

import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.entity.Todo.TodoStatus;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import java.time.LocalDate;
import java.time.LocalDateTime;

public record CalendarItemResp(
		Long todoId,
		Long masterTodoId,
		LocalDate occurrenceDate,
		boolean isVirtual,
		String title,
		String content,
		String category,
		TodoType type,
		Integer priority,
		LocalDate startDate,
		LocalDate endDate,
		Integer period,
		TodoStatus status,
		LocalDateTime updatedAt,
		int snoozedDays
) {

	public static CalendarItemResp fromActual(
			Todo todo,
			Long masterTodoId,
			String categoryName,
			TodoType responseType,
			Integer responsePeriod,
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
				responseType,
				todo.getPriority(),
				todo.getStartDate(),
				todo.getEndDate(),
				responsePeriod,
				todo.getStatus(),
				todo.getUpdatedAt(),
				snoozedDays
		);
	}

	public static CalendarItemResp fromVirtual(Todo master, String categoryName, LocalDate occurrenceDate) {
		return new CalendarItemResp(
				null,
				master.getTodoId(),
				occurrenceDate,
				true,
				master.getTitle(),
				master.getContent(),
				categoryName,
				master.getType(),
				master.getPriority(),
				occurrenceDate,
				null,
				master.getPeriod(),
				TodoStatus.TODO,
				master.getUpdatedAt(),
				0
		);
	}
}
