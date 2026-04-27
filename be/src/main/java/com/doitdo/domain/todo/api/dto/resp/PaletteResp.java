package com.doitdo.domain.todo.api.dto.resp;

import java.util.List;

/**
 * 팔레트 응답 DTO.
 * colors 는 color_order 오름차순 hex 배열.
 */
public record PaletteResp(Long paletteId, String paletteName, List<String> colors) {
}
