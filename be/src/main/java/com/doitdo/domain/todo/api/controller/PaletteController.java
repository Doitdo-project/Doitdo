package com.doitdo.domain.todo.api.controller;

import com.doitdo.domain.todo.api.dto.resp.PaletteResp;
import com.doitdo.domain.todo.application.PaletteService;
import com.doitdo.global.api.response.GlobalApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "팔레트")
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/palettes")
public class PaletteController {

	private final PaletteService paletteService;

	@Operation(summary = "팔레트 목록 조회", description = "전체 팔레트와 각 팔레트의 색상 hex 배열을 반환한다.")
	@GetMapping
	public GlobalApiResponse<List<PaletteResp>> list() {
		return GlobalApiResponse.ok("팔레트 목록 조회 성공", paletteService.list());
	}
}
