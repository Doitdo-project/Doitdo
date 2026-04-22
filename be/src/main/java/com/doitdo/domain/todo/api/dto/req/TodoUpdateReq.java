package com.doitdo.domain.todo.api.dto.req;

import com.doitdo.domain.todo.entity.Todo.TodoType;
import java.time.LocalDate;

public record TodoUpdateReq(

		String title,

		String content,

		String category,

		TodoType type,

		LocalDate startDate,

		LocalDate endDate,

		Integer period
) {
}
