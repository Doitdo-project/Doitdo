package com.doitdo.domain.todo.api.dto.resp;

import com.doitdo.domain.todo.entity.Category;
import java.util.List;

public record CategoryListResp(List<CategoryResp> items) {

	public static CategoryListResp from(List<Category> categories) {
		return new CategoryListResp(
				categories.stream().map(CategoryResp::from).toList()
		);
	}
}
