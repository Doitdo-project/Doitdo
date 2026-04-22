package com.doitdo.domain.todo.api.controller;

import com.doitdo.domain.auth.application.CustomUserDetails;
import com.doitdo.domain.todo.api.dto.req.TodoCreateReq;
import com.doitdo.domain.todo.api.dto.req.TodoListReq;
import com.doitdo.domain.todo.api.dto.req.TodoPriorityChangeReq;
import com.doitdo.domain.todo.api.dto.req.TodoSearchReq;
import com.doitdo.domain.todo.api.dto.req.TodoStatusChangeReq;
import com.doitdo.domain.todo.api.dto.req.TodoUpdateReq;
import com.doitdo.domain.todo.api.dto.resp.TodoDetailResp;
import com.doitdo.domain.todo.api.dto.resp.TodoListResp;
import com.doitdo.domain.todo.api.dto.resp.TodoSearchResp;
import com.doitdo.domain.todo.application.TodoService;
import com.doitdo.global.api.response.GlobalApiResponse;
import com.doitdo.global.swagger.ApiErrorCodes;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
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

	@Operation(summary = "TODO 목록 조회", description = "뷰/상태/카테고리/타입/날짜/검색/정렬 필터로 본인 소유 TODO 목록을 조회한다.")
	@ApiErrorCodes({"T02-002"})
	@GetMapping
	public GlobalApiResponse<TodoListResp> list(
			@AuthenticationPrincipal CustomUserDetails userDetails,
			@ModelAttribute TodoListReq req) {
		return GlobalApiResponse.ok("TODO 목록 조회 성공",
				todoService.list(userDetails.getUserId(), req));
	}

	@Operation(summary = "TODO 검색", description = "키워드로 본인 소유 TODO 를 검색한다. 페이지네이션 지원.")
	@ApiErrorCodes({"T09-002"})
	@GetMapping("/search")
	public GlobalApiResponse<TodoSearchResp> search(
			@AuthenticationPrincipal CustomUserDetails userDetails,
			@Valid @ModelAttribute TodoSearchReq req) {
		return GlobalApiResponse.ok("TODO 검색 성공",
				todoService.search(userDetails.getUserId(), req));
	}

	@Operation(summary = "TODO 삭제", description = "본인 소유 TODO 를 소프트 삭제(isDeleted=true) 한다.")
	@ApiErrorCodes({"T01-001", "T01-003"})
	@DeleteMapping("/{todoId}")
	@ResponseStatus(HttpStatus.NO_CONTENT)
	public GlobalApiResponse<Void> delete(
			@AuthenticationPrincipal CustomUserDetails userDetails,
			@PathVariable Long todoId) {
		todoService.delete(userDetails.getUserId(), todoId);
		return GlobalApiResponse.noContent("삭제 완료");
	}

	@Operation(summary = "TODO 상세 조회", description = "단일 TODO 를 조회한다. 본인 소유 TODO 만 조회 가능.")
	@ApiErrorCodes({"T00-001", "T00-003"})
	@GetMapping("/{todoId}")
	public GlobalApiResponse<TodoDetailResp> detail(
			@AuthenticationPrincipal CustomUserDetails userDetails,
			@PathVariable Long todoId) {
		return GlobalApiResponse.ok("TODO 상세 조회 성공",
				todoService.detail(userDetails.getUserId(), todoId));
	}

	@Operation(summary = "TODO 수정", description = "TODO 의 내용·일정 정보를 부분 수정한다. 본인 소유 + 'TODO' 상태의 항목만 수정 가능.")
	@ApiErrorCodes({"T04-001", "T04-003", "T04-004", "T04-005"})
	@PatchMapping("/{todoId}")
	public GlobalApiResponse<TodoDetailResp> update(
			@AuthenticationPrincipal CustomUserDetails userDetails,
			@PathVariable Long todoId,
			@RequestBody TodoUpdateReq req) {
		return GlobalApiResponse.ok("TODO 수정 성공",
				todoService.update(userDetails.getUserId(), todoId, req));
	}

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

	@Operation(summary = "TODO 상태 변경", description = "TODO 상태를 TODO/IN_PROGRESS/DONE 로 변경. 반복 TODO 마스터(type=RECURRING) 는 상태 변경 불가.")
	@ApiErrorCodes({"T03-001", "T03-003", "T03-004"})
	@PatchMapping("/{todoId}/status")
	public GlobalApiResponse<TodoDetailResp> changeStatus(
			@AuthenticationPrincipal CustomUserDetails userDetails,
			@PathVariable Long todoId,
			@Valid @RequestBody TodoStatusChangeReq req) {
		return GlobalApiResponse.ok("TODO 상태 변경 성공",
				todoService.changeStatus(userDetails.getUserId(), todoId, req));
	}

	@Operation(summary = "TODO 우선순위 변경", description = "TODO 의 우선순위 값을 부분 수정한다.")
	@ApiErrorCodes({"T07-001", "T07-003"})
	@PatchMapping("/{todoId}/priority")
	public GlobalApiResponse<TodoDetailResp> changePriority(
			@AuthenticationPrincipal CustomUserDetails userDetails,
			@PathVariable Long todoId,
			@Valid @RequestBody TodoPriorityChangeReq req) {
		return GlobalApiResponse.ok("TODO 우선순위 변경 성공",
				todoService.changePriority(userDetails.getUserId(), todoId, req));
	}
}
