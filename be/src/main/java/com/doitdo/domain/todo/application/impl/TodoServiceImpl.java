package com.doitdo.domain.todo.application.impl;

import com.doitdo.domain.todo.api.dto.req.TodoCreateReq;
import com.doitdo.domain.todo.api.dto.req.TodoStatusChangeReq;
import com.doitdo.domain.todo.api.dto.req.TodoUpdateReq;
import com.doitdo.domain.todo.api.dto.resp.TodoDetailResp;
import com.doitdo.domain.todo.application.TodoService;
import com.doitdo.domain.todo.entity.Category;
import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.entity.Todo.TodoStatus;
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
	@Transactional(readOnly = true)
	public TodoDetailResp detail(Long userId, Long todoId) {
		Todo todo = todoRepository.findByTodoIdAndIsDeletedFalse(todoId)
				.orElseThrow(() -> new CustomException(TodoErrorCode.T00_001));

		if (!todo.getUserId().equals(userId)) {
			throw new CustomException(TodoErrorCode.T00_003);
		}

		String categoryName = null;
		if (todo.getCategoryId() != null) {
			categoryName = categoryRepository.findById(todo.getCategoryId())
					.map(Category::getCategoryName)
					.orElse(null);
		}

		return TodoDetailResp.from(todo, categoryName);
	}

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

	@Override
	@Transactional
	public void delete(Long userId, Long todoId) {
		Todo todo = todoRepository.findByTodoIdAndIsDeletedFalse(todoId)
				.orElseThrow(() -> new CustomException(TodoErrorCode.T01_001));

		if (!todo.getUserId().equals(userId)) {
			throw new CustomException(TodoErrorCode.T01_003);
		}

		todo.softDelete();
	}

	@Override
	@Transactional
	public TodoDetailResp update(Long userId, Long todoId, TodoUpdateReq req) {
		Todo todo = todoRepository.findByTodoIdAndIsDeletedFalse(todoId)
				.orElseThrow(() -> new CustomException(TodoErrorCode.T04_001));

		if (!todo.getUserId().equals(userId)) {
			throw new CustomException(TodoErrorCode.T04_003);
		}

		if (todo.getStatus() == TodoStatus.IN_PROGRESS || todo.getStatus() == TodoStatus.DONE) {
			throw new CustomException(TodoErrorCode.T04_004);
		}

		Long categoryId = todo.getCategoryId();
		String categoryName = null;
		if (req.category() != null && StringUtils.hasText(req.category())) {
			Category category = categoryRepository.findByCategoryNameAndUserId(req.category(), userId)
					.orElseThrow(() -> new CustomException(TodoErrorCode.T04_005));
			categoryId = category.getCategoryId();
			categoryName = category.getCategoryName();
		} else {
			if (todo.getCategoryId() != null) {
				categoryName = categoryRepository.findById(todo.getCategoryId())
						.map(Category::getCategoryName)
						.orElse(null);
			}
		}

		TodoType finalType = req.type() != null ? req.type() : todo.getType();
		Integer finalPeriod = req.period() != null ? req.period() : todo.getPeriod();
		if (finalType == TodoType.RECURRING && finalPeriod == null) {
			throw new CustomException(TodoErrorCode.T04_004);
		}

		todo.update(
				req.title(),
				req.content(),
				categoryId,
				req.type(),
				req.startDate(),
				req.endDate(),
				req.period()
		);

		return TodoDetailResp.from(todo, categoryName);
	}

	@Override
	@Transactional
	public TodoDetailResp changeStatus(Long userId, Long todoId, TodoStatusChangeReq req) {
		Todo todo = todoRepository.findByTodoIdAndIsDeletedFalse(todoId)
				.orElseThrow(() -> new CustomException(TodoErrorCode.T03_001));

		if (!todo.getUserId().equals(userId)) {
			throw new CustomException(TodoErrorCode.T03_003);
		}

		if (todo.getType() == TodoType.RECURRING) {
			throw new CustomException(TodoErrorCode.T03_004);
		}

		todo.changeStatus(req.status());

		String categoryName = null;
		if (todo.getCategoryId() != null) {
			categoryName = categoryRepository.findById(todo.getCategoryId())
					.map(Category::getCategoryName)
					.orElse(null);
		}

		// TODO: DONE 상태 변경 시 Tamagotchi 도메인 경험치 연동 필요 — Tamagotchi 이벤트 발행 추가 예정

		return TodoDetailResp.from(todo, categoryName);
	}
}
