package com.doitdo.domain.tamagotchi.api.controller;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.doitdo.domain.auth.application.CustomUserDetails;
import com.doitdo.domain.tamagotchi.api.dto.resp.EncyclopediaResp;
import com.doitdo.domain.tamagotchi.application.TamagotchiService;
import com.doitdo.global.api.response.GlobalApiResponse;
import com.doitdo.global.swagger.ApiErrorCodes;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;

@Tag(name = "tamagotchi", description = "다마고치 관련 API")
@RestController
@RequestMapping("/api/characters")
@RequiredArgsConstructor
public class TamagotchiController {

	private final TamagotchiService tamagotchiService;

	@Operation(summary = "도감 조회", description = "사용자의 캐릭터 도감 목록과 해금 여부를 조회")
	@ApiErrorCodes({"M03-001", "M03-002", "M03-003"})
	@GetMapping("/encyclopedia")
	public GlobalApiResponse<EncyclopediaResp> getEncyclopedia(
		@AuthenticationPrincipal CustomUserDetails userDetails
	) {
		return GlobalApiResponse.ok(tamagotchiService.getEncyclopedia(userDetails.getUserId()));
	}
}
