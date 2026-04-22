package com.doitdo.domain.todo.api.dto.resp;

import com.doitdo.domain.todo.entity.Todo;
import java.util.List;
import java.util.Map;

public record TodoListResp(List<TodoDetailResp> items) {

	public static TodoListResp of(
			List<Todo> todos,
			Map<Long, String> categoryNameById,
			Map<Long, Integer> snoozeCountByTodoId) {
		List<TodoDetailResp> items = todos.stream()
				.map(todo -> TodoDetailResp.from(
						todo,
						todo.getCategoryId() != null
								? categoryNameById.get(todo.getCategoryId())
								: null,
						snoozeCountByTodoId.getOrDefault(todo.getTodoId(), 0)
				))
				.toList();
		return new TodoListResp(items);
	}
}
