package com.doitdo.domain.todo.api.controller;

import com.doitdo.domain.auth.application.CustomUserDetails;
import com.doitdo.domain.todo.api.dto.req.TodoCreateReq;
import com.doitdo.domain.todo.api.dto.resp.TodoDetailResp;
import com.doitdo.domain.todo.application.TodoService;
import com.doitdo.global.api.response.GlobalApiResponse;
import com.doitdo.global.swagger.ApiErrorCodes;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "todo", description = "TODO 관련 API")
@RestController
@RequestMapping("/api/todos")
@RequiredArgsConstructor
public class TodoController {

	private final TodoService todoService;

	@Operation(summary = "TODO 작성", description = "새로운 TODO 항목을 작성한다")
	@ApiErrorCodes({"T06-002", "T06-003"})
	@PostMapping
	@ResponseStatus(HttpStatus.CREATED)
	public GlobalApiResponse<TodoDetailResp> create(
			@AuthenticationPrincipal CustomUserDetails userDetails,
			@Valid @RequestBody TodoCreateReq req) {
		return GlobalApiResponse.created("TODO 작성 성공",
				todoService.create(userDetails.getUserId(), req));
	}
}
