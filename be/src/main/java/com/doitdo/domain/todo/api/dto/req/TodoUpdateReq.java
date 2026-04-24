package com.doitdo.domain.todo.api.dto.req;

import com.doitdo.domain.todo.entity.Todo.TodoType;
import jakarta.validation.constraints.Pattern;
import java.time.LocalDate;

public record TodoUpdateReq(

		String title,

		String content,

		String category,

		TodoType type,

		LocalDate startDate,

		LocalDate endDate,

		Integer period,

		@Pattern(regexp = "^([01]\\d|2[0-3]):[0-5]\\d$", message = "알림 시각은 HH:mm 형식이어야 합니다")
		String alertTime
) {
}
