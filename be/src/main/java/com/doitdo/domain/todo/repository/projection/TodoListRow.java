package com.doitdo.domain.todo.repository.projection;

import com.doitdo.domain.todo.entity.Todo.TodoStatus;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import java.time.LocalDate;
import java.time.LocalDateTime;

public record TodoListRow(
		Long todoId,
		String title,
		String content,
		String categoryName,
		Integer categoryColorId,
		TodoType type,
		Integer priority,
		String alertTime,
		LocalDate startDate,
		LocalDate endDate,
		String daysOfWeekRaw,
		TodoStatus status,
		LocalDateTime updatedAt,
		long snoozeCount
) {
}
