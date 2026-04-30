package com.doitdo.domain.todo.api.dto.req;

import jakarta.validation.constraints.Size;

/**
 * T12 PATCH /categories/{categoryId} 카테고리 부분 수정 요청 DTO.
 * name, colorId 모두 nullable — null 이면 해당 필드를 변경하지 않는다.
 */
public record CategoryUpdateReq(
		@Size(max = 10)
		String name,
		Integer colorId
) {
}
