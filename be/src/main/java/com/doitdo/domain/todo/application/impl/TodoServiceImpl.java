package com.doitdo.domain.todo.application.impl;

import com.doitdo.domain.todo.api.dto.req.TodoCreateReq;
import com.doitdo.domain.todo.api.dto.resp.TodoDetailResp;
import com.doitdo.domain.todo.application.TodoService;
import com.doitdo.domain.todo.entity.Category;
import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import com.doitdo.domain.todo.repository.CategoryRepository;
import com.doitdo.domain.todo.repository.TodoRepository;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.TodoErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
@RequiredArgsConstructor
public class TodoServiceImpl implements TodoService {

	private final TodoRepository todoRepository;
	private final CategoryRepository categoryRepository;

	@Override
	@Transactional
	public TodoDetailResp create(Long userId, TodoCreateReq req) {
		if (req.type() == TodoType.RECURRING && req.period() == null) {
			throw new CustomException(TodoErrorCode.T06_002);
		}

		Long categoryId = null;
		String categoryName = null;
		if (StringUtils.hasText(req.category())) {
			Category category = categoryRepository.findByCategoryNameAndUserId(req.category(), userId)
					.orElseThrow(() -> new CustomException(TodoErrorCode.T06_003));
			categoryId = category.getCategoryId();
			categoryName = category.getCategoryName();
		}

		int priority = req.priority() != null ? req.priority() : 1;

		Todo todo = todoRepository.save(
				Todo.create(userId, categoryId, req.title(), req.content(),
						req.type(), priority, req.startDate(), req.endDate(), req.period())
		);

		return TodoDetailResp.from(todo, categoryName);
	}
}
