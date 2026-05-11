package com.doitdo.domain.todo.api.dto.req;

import com.doitdo.domain.todo.entity.Todo.TodoType;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import java.util.Set;

public record TodoUpdateReq(

		@Size(max = 20)
		String title,

		@Size(max = 100)
		String content,

		String category,

		TodoType type,

		LocalDate startDate,

		LocalDate endDate,

		Set<@Pattern(regexp = "^(MON|TUE|WED|THU|FRI|SAT|SUN)$", message = "요일은 MON,TUE,WED,THU,FRI,SAT,SUN 중 하나여야 합니다") String> daysOfWeek,

		@Pattern(regexp = "^([01]\\d|2[0-3]):[0-5]\\d$", message = "알림 시각은 HH:mm 형식이어야 합니다")
		String alertTime,

		Boolean clearAlertTime
) {
}
