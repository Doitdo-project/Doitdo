package com.doitdo.domain.todo.api.dto.resp;

import com.doitdo.domain.todo.entity.Category;
import java.util.List;
import java.util.Map;

public record CategoryListResp(List<CategoryResp> items) {

	/** colorHex 포함 변환 (N+1 회피를 위해 미리 빌드된 Map 사용) */
	public static CategoryListResp from(List<Category> categories, Map<Integer, String> colorIdToHex) {
		return new CategoryListResp(
				categories.stream()
						.map(c -> CategoryResp.from(c,
								c.getColorId() != null ? colorIdToHex.get(c.getColorId()) : null))
						.toList()
		);
	}
}
