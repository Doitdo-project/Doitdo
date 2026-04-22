package com.doitdo.domain.tamagotchi.api.controller;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.doitdo.domain.auth.application.CustomUserDetails;
import com.doitdo.domain.tamagotchi.api.dto.req.ApproveIndependenceReq;
import com.doitdo.domain.tamagotchi.api.dto.req.UpdateCharacterNameReq;
import com.doitdo.domain.tamagotchi.api.dto.resp.CurrentCharacterResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.EncyclopediaResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.EvolutionResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.FarewellResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.HatchCharacterResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.UpdateCharacterNameResp;
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

	@Operation(summary = "캐릭터 이름 설정", description = "현재 활성 다마고치의 이름을 변경")
	@ApiErrorCodes({"M01-001", "M01-002", "M01-003", "M01-004"})
	@PatchMapping("/me/name")
	public GlobalApiResponse<UpdateCharacterNameResp> updateName(
		@AuthenticationPrincipal CustomUserDetails userDetails,
		@RequestBody UpdateCharacterNameReq request
	) {
		return GlobalApiResponse.ok(tamagotchiService.updateName(userDetails.getUserId(), request.name()));
	}

	@Operation(summary = "현재 캐릭터 조회", description = "현재 활성 상태의 캐릭터 정보를 조회")
	@ApiErrorCodes({"M04-001", "M04-002", "M04-003"})
	@GetMapping("/me")
	public GlobalApiResponse<CurrentCharacterResp> getCurrentCharacter(
		@AuthenticationPrincipal CustomUserDetails userDetails
	) {
		return GlobalApiResponse.ok(tamagotchiService.getCurrentCharacter(userDetails.getUserId()));
	}

	@Operation(summary = "알 깨기", description = "현재 알 상태의 다마고치를 부화")
	@ApiErrorCodes({"M02-001", "M02-002", "M02-003", "M02-004"})
	@PostMapping("/me/hatch")
	public GlobalApiResponse<HatchCharacterResp> hatch(
		@AuthenticationPrincipal CustomUserDetails userDetails
	) {
		return GlobalApiResponse.ok(tamagotchiService.hatch(userDetails.getUserId()));
	}

	@Operation(summary = "다마고치 진화", description = "현재 다마고치의 성장 단계를 다음 단계로 진화")
	@ApiErrorCodes({"M05-001", "M05-002", "M05-003", "M05-004", "M05-005"})
	@PostMapping("/{userCharacterId}/evolution")
	public GlobalApiResponse<EvolutionResp> evolve(
		@AuthenticationPrincipal CustomUserDetails userDetails,
		@PathVariable Long userCharacterId
	) {
		return GlobalApiResponse.ok(tamagotchiService.evolve(userDetails.getUserId(), userCharacterId));
	}

	@Operation(summary = "독립 승인", description = "현재 성체 다마고치를 독립 처리하고 다음 알을 배정")
	@ApiErrorCodes({"M00-001", "M00-002", "M00-003", "M00-004"})
	@PostMapping("/me/farewell")
	public GlobalApiResponse<FarewellResp> approveIndependence(
		@AuthenticationPrincipal CustomUserDetails userDetails,
		@RequestBody ApproveIndependenceReq request
	) {
		return GlobalApiResponse.ok(tamagotchiService.approveIndependence(userDetails.getUserId(), request.approved()));
	}
}
