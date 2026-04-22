package com.doitdo.domain.todo.api.dto.req;

import com.doitdo.domain.todo.entity.Todo.TodoType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

public record TodoCreateReq(

		@NotBlank
		String title,

		String content,

		String category,

		@NotNull
		TodoType type,

		@NotNull
		LocalDate startDate,

		LocalDate endDate,

		Integer period,

		Integer priority
) {
}
