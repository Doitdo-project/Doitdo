package com.doitdo.domain.todo.api.dto.resp;

import java.util.List;

public record TodoSearchResp(
		List<TodoDetailResp> items,
		int page,
		int size,
		long totalElements,
		int totalPages
) {
}
