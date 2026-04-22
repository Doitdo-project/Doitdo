package com.doitdo.domain.todo.application;

import com.doitdo.domain.todo.api.dto.req.TodoCreateReq;
import com.doitdo.domain.todo.api.dto.resp.TodoDetailResp;

public interface TodoService {

	TodoDetailResp create(Long userId, TodoCreateReq req);

	TodoDetailResp detail(Long userId, Long todoId);
}
