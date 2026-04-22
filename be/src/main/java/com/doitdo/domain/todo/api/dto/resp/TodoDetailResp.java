package com.doitdo.domain.todo.api.dto.resp;

import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.entity.Todo.TodoStatus;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import java.time.LocalDate;

public record TodoDetailResp(

		Long todoId,
		String title,
		String content,
		String category,
		TodoType type,
		Integer priority,
		LocalDate startDate,
		LocalDate endDate,
		Integer period,
		TodoStatus status
) {

	public static TodoDetailResp from(Todo todo, String categoryName) {
		return new TodoDetailResp(
				todo.getTodoId(),
				todo.getTitle(),
				todo.getContent(),
				categoryName,
				todo.getType(),
				todo.getPriority(),
				todo.getStartDate(),
				todo.getEndDate(),
				todo.getPeriod(),
				todo.getStatus()
		);
	}
}
