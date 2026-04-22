package com.doitdo.domain.todo.application;

import com.doitdo.domain.todo.api.dto.req.TodoCreateReq;
import com.doitdo.domain.todo.api.dto.req.TodoStatusChangeReq;
import com.doitdo.domain.todo.api.dto.req.TodoUpdateReq;
import com.doitdo.domain.todo.api.dto.resp.TodoDetailResp;

public interface TodoService {

	TodoDetailResp create(Long userId, TodoCreateReq req);

	TodoDetailResp detail(Long userId, Long todoId);

	TodoDetailResp update(Long userId, Long todoId, TodoUpdateReq req);

	void delete(Long userId, Long todoId);

	TodoDetailResp changeStatus(Long userId, Long todoId, TodoStatusChangeReq req);
}
