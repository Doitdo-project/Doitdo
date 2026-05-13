package com.doitdo.domain.todo.api.dto.req;

import com.doitdo.domain.todo.entity.Todo.TodoStatus;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

public record TodoStatusChangeReq(

		@NotNull
		TodoStatus status,

		LocalDate occurrenceDate
) {
	public TodoStatusChangeReq(TodoStatus status) {
		this(status, null);
	}
}
