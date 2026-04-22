package com.doitdo.domain.todo.api.dto.resp;

import com.doitdo.domain.todo.entity.Todo;
import java.util.List;
import java.util.Map;
import org.springframework.data.domain.Page;

public record TodoSearchResp(
		List<TodoDetailResp> content,
		int page,
		int size,
		long totalElements,
		int totalPages
) {

	public static TodoSearchResp from(
			Page<Todo> pageResult,
			Map<Long, String> categoryNameById,
			Map<Long, Integer> snoozeCountByTodoId) {
		List<TodoDetailResp> items = pageResult.getContent().stream()
				.map(t -> TodoDetailResp.from(
						t,
						categoryNameById.get(t.getCategoryId()),
						snoozeCountByTodoId.getOrDefault(t.getTodoId(), 0)
				))
				.toList();
		return new TodoSearchResp(
				items,
				pageResult.getNumber(),
				pageResult.getSize(),
				pageResult.getTotalElements(),
				pageResult.getTotalPages()
		);
	}
}
