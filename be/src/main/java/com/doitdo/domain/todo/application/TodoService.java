package com.doitdo.domain.todo.application;

import com.doitdo.domain.todo.api.dto.req.TodoCreateReq;
import com.doitdo.domain.todo.api.dto.req.TodoCalendarReq;
import com.doitdo.domain.todo.api.dto.req.TodoListReq;
import com.doitdo.domain.todo.api.dto.req.TodoPriorityChangeReq;
import com.doitdo.domain.todo.api.dto.req.TodoSearchReq;
import com.doitdo.domain.todo.api.dto.req.TodoSnoozeReq;
import com.doitdo.domain.todo.api.dto.req.TodoStatusChangeReq;
import com.doitdo.domain.todo.api.dto.req.TodoUpdateReq;
import com.doitdo.domain.todo.api.dto.resp.TodoCalendarResp;
import com.doitdo.domain.todo.api.dto.resp.TodoDetailResp;
import com.doitdo.domain.todo.api.dto.resp.TodoListResp;
import com.doitdo.domain.todo.api.dto.resp.TodoSearchResp;

public interface TodoService {

	TodoListResp list(Long userId, TodoListReq req);

	TodoCalendarResp calendar(Long userId, TodoCalendarReq req);

	TodoDetailResp create(Long userId, TodoCreateReq req);

	TodoDetailResp detail(Long userId, Long todoId);

	TodoDetailResp update(Long userId, Long todoId, TodoUpdateReq req);

	void delete(Long userId, Long todoId, String scope);

	TodoDetailResp changeStatus(Long userId, Long todoId, TodoStatusChangeReq req);

	TodoDetailResp changePriority(Long userId, Long todoId, TodoPriorityChangeReq req);

	TodoSearchResp search(Long userId, TodoSearchReq req);

	TodoDetailResp snooze(Long userId, Long todoId, TodoSnoozeReq req);
}
