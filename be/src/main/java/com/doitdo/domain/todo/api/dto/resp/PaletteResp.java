package com.doitdo.domain.todo.api.dto.resp;

import java.util.List;

/**
 * 팔레트 응답 DTO.
 *
 * <p>colors 는 color_order 오름차순으로, 각 항목은 {@link Color} (colorId + hex) 객체.
 * colorId 를 함께 노출해야 FE 가 카테고리 색 변경 PATCH 시 정확한 color_id 를 보낼 수 있다
 * (예전에는 hex 만 반환해 FE 가 인덱스 계산으로 color_id 를 추측 → 실제 DB color_id 와
 * 어긋나 잘못된 색이 저장되는 버그가 있었음).
 */
public record PaletteResp(Long paletteId, String paletteName, List<Color> colors) {

	public record Color(Integer colorId, String color) {}
}
