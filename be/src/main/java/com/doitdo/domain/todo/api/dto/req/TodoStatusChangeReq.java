package com.doitdo.domain.todo.api.dto.req;

import com.doitdo.domain.todo.entity.Todo.TodoStatus;
import jakarta.validation.constraints.NotNull;

public record TodoStatusChangeReq(

		@NotNull
		TodoStatus status
) {
}
