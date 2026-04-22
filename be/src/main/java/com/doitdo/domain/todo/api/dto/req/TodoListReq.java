package com.doitdo.domain.todo.api.dto.req;

import com.doitdo.domain.todo.entity.Todo.TodoStatus;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import java.time.LocalDate;
import org.springframework.format.annotation.DateTimeFormat;

public record TodoListReq(
		String view,
		TodoStatus status,
		String category,
		TodoType type,
		@DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
		String q,
		String sort
) {}
