package com.doitdo.domain.todo.api.dto.resp;

import com.doitdo.domain.todo.entity.Category;
import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * 카테고리 응답 DTO.
 * 노션 API 예시에서 응답 필드명이 "categoryName" 으로 표기되어 있어
 * JSON 직렬화 시 categoryName 으로 출력한다.
 */
public record CategoryResp(
		Long categoryId,

		@JsonProperty("categoryName")
		String name,

		Integer colorId
) {
	public static CategoryResp from(Category c) {
		return new CategoryResp(c.getCategoryId(), c.getCategoryName(), c.getColorId());
	}
}
