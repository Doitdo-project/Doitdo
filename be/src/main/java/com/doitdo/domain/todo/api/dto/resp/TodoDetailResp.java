package com.doitdo.domain.todo.api.dto.resp;

import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.entity.Todo.TodoStatus;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import java.time.LocalDate;
import java.time.LocalDateTime;

public record TodoDetailResp(

		Long todoId,
		String title,
		String content,
		String category,
		TodoType type,
		Integer priority,
		String alertTime,
		LocalDate startDate,
		LocalDate endDate,
		Integer period,
		TodoStatus status,
		LocalDateTime updatedAt,
		int snoozedDays
) {

	public static TodoDetailResp from(Todo todo, String categoryName, int snoozedDays) {
		return new TodoDetailResp(
				todo.getTodoId(),
				todo.getTitle(),
				todo.getContent(),
				categoryName,
				todo.getType(),
				todo.getPriority(),
				todo.getAlertTime(),
				todo.getStartDate(),
				todo.getEndDate(),
				todo.getPeriod(),
				todo.getStatus(),
				todo.getUpdatedAt(),
				snoozedDays
		);
	}
}
