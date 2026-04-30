package com.doitdo.domain.todo.api.dto.req;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * T10 POST /categories 카테고리 생성 요청 DTO.
 * 노션 API 문서의 body 필드명은 "color" 이지만 엔티티 colorId (PaletteColor FK, Integer) 와의
 * 일관성을 위해 필드명을 colorId 로 통일한다.
 */
public record CategoryCreateReq(

		@NotBlank
		@Size(max = 10)
		String name,

		@NotNull
		Integer colorId
) {
}
