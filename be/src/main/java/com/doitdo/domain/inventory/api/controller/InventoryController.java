package com.doitdo.domain.inventory.api.controller;

import com.doitdo.domain.auth.application.CustomUserDetails;
import com.doitdo.domain.inventory.api.dto.resp.InventoryResp;
import com.doitdo.domain.inventory.application.InventoryService;
import com.doitdo.global.api.response.GlobalApiResponse;
import com.doitdo.global.swagger.ApiErrorCodes;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "inventory", description = "인벤토리 관련 API")
@RestController
@RequestMapping("/api/tamagotchis")
@RequiredArgsConstructor
public class InventoryController {

	private final InventoryService inventoryService;

	@Operation(summary = "내 인벤토리 조회", description = "특정 다마고치 기준으로 보유 아이템과 장착 상태를 조회")
	@ApiErrorCodes({"M08-001", "M08-002", "M08-003"})
	@GetMapping("/{tamagotchiId}/inventory")
	public GlobalApiResponse<InventoryResp> getInventory(
		@AuthenticationPrincipal CustomUserDetails userDetails,
		@PathVariable Long tamagotchiId
	) {
		return GlobalApiResponse.ok(inventoryService.getInventory(userDetails.getUserId(), tamagotchiId));
	}
}
