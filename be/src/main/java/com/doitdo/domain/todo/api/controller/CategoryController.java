package com.doitdo.domain.todo.api.controller;

import com.doitdo.domain.auth.application.CustomUserDetails;
import com.doitdo.domain.todo.api.dto.req.CategoryCreateReq;
import com.doitdo.domain.todo.api.dto.req.CategoryUpdateReq;
import com.doitdo.domain.todo.api.dto.resp.CategoryResp;
import com.doitdo.domain.todo.application.CategoryService;
import com.doitdo.global.api.response.GlobalApiResponse;
import com.doitdo.global.swagger.ApiErrorCodes;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "category")
@RestController
@RequestMapping("/api/categories")
@RequiredArgsConstructor
public class CategoryController {

	private final CategoryService categoryService;

	@Operation(summary = "카테고리 생성", description = "새 카테고리를 생성한다. 사용자당 최대 6개.")
	@ApiErrorCodes({"T10-003", "T10-004"})
	@PostMapping
	@ResponseStatus(HttpStatus.CREATED)
	public GlobalApiResponse<CategoryResp> create(
			@AuthenticationPrincipal CustomUserDetails userDetails,
			@Valid @RequestBody CategoryCreateReq req) {
		return GlobalApiResponse.created("카테고리 생성 완료",
				categoryService.create(userDetails.getUserId(), req));
	}

	@Operation(summary = "카테고리 삭제", description = "본인 소유 카테고리를 삭제한다 (하드 삭제).")
	@ApiErrorCodes({"T11-001", "T11-003"})
	@DeleteMapping("/{categoryId}")
	@ResponseStatus(HttpStatus.NO_CONTENT)
	public GlobalApiResponse<Void> delete(
			@AuthenticationPrincipal CustomUserDetails userDetails,
			@PathVariable Long categoryId) {
		categoryService.delete(userDetails.getUserId(), categoryId);
		return GlobalApiResponse.noContent("카테고리 삭제 완료");
	}

	@Operation(summary = "카테고리 수정", description = "카테고리 이름·색상을 부분 수정한다. null 필드는 변경하지 않는다.")
	@ApiErrorCodes({"T12-001", "T12-002", "T12-004"})
	@PatchMapping("/{categoryId}")
	public GlobalApiResponse<CategoryResp> update(
			@AuthenticationPrincipal CustomUserDetails userDetails,
			@PathVariable Long categoryId,
			@RequestBody CategoryUpdateReq req) {
		return GlobalApiResponse.ok("카테고리 수정 완료",
				categoryService.update(userDetails.getUserId(), categoryId, req));
	}
}
