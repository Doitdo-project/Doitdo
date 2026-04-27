package com.doitdo.domain.todo.api.dto.req;

import jakarta.validation.constraints.NotNull;

public record TodoPriorityChangeReq(

		@NotNull
		Integer priority
) {
}
