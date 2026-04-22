package com.doitdo.domain.todo.api.dto.resp;

import java.util.List;

public record TodoCalendarResp(
		List<CalendarItemResp> items
) {}
