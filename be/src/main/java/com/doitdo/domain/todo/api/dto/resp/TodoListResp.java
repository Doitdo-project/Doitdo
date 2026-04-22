package com.doitdo.domain.todo.api.dto.resp;

import com.doitdo.domain.todo.entity.Todo;
import java.util.List;
import java.util.Map;

public record TodoListResp(List<TodoDetailResp> items) {

	public static TodoListResp of(List<Todo> todos, Map<Long, String> categoryNameById) {
		List<TodoDetailResp> items = todos.stream()
				.map(todo -> TodoDetailResp.from(
						todo,
						todo.getCategoryId() != null
								? categoryNameById.get(todo.getCategoryId())
								: null
				))
				.toList();
		return new TodoListResp(items);
	}
}
