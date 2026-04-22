package com.doitdo.domain.todo.api.dto.req;

import java.time.LocalDate;

public record TodoSnoozeReq(
		LocalDate occurrenceDate
) {}
