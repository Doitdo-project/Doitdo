package com.doitdo.domain.shop.api.controller;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.doitdo.domain.auth.application.CustomUserDetails;
import com.doitdo.domain.shop.api.dto.req.UpdateRoomFurniturePlacementReq;
import com.doitdo.domain.shop.api.dto.resp.FurnitureShopResp;
import com.doitdo.domain.shop.api.dto.resp.PurchaseFurnitureResp;
import com.doitdo.domain.shop.api.dto.resp.RoomFurniturePlacementResp;
import com.doitdo.domain.shop.api.dto.resp.RoomResp;
import com.doitdo.domain.shop.api.dto.resp.UserFurnitureResp;
import com.doitdo.domain.shop.application.RoomFurniturePlacementService;
import com.doitdo.domain.shop.application.ShopService;
import com.doitdo.global.api.response.GlobalApiResponse;
import com.doitdo.global.swagger.ApiErrorCodes;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;

@Tag(name = "shop", description = "상점 관련 API")
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class ShopController {

	private final ShopService shopService;
	private final RoomFurniturePlacementService roomFurniturePlacementService;

	@Operation(summary = "상점 가구 목록 조회", description = "상점의 가구 목록을 조회하고 보유한 가구는 품절 상태로 표시")
	@GetMapping("/shop/furnitures")
	public GlobalApiResponse<FurnitureShopResp> listFurnitures(
		@AuthenticationPrincipal CustomUserDetails userDetails,
		@RequestParam(required = false) String category
	) {
		return GlobalApiResponse.ok(shopService.listFurnitures(userDetails.getUserId(), category));
	}

	@Operation(summary = "가구 구매", description = "월렛 잔액으로 가구를 구매")
	@ApiErrorCodes({"S00-001", "S00-002", "S00-003", "S00-004", "S00-005"})
	@PostMapping("/shop/furnitures/{furnitureId}/purchase")
	public GlobalApiResponse<PurchaseFurnitureResp> purchaseFurniture(
		@AuthenticationPrincipal CustomUserDetails userDetails,
		@PathVariable Long furnitureId
	) {
		return GlobalApiResponse.ok("가구 구매 완료",
			shopService.purchaseFurniture(userDetails.getUserId(), furnitureId));
	}

	@Operation(summary = "내 보유 가구 목록 조회", description = "사용자가 구매해 보유 중인 가구 목록을 조회")
	@GetMapping("/users/me/furnitures")
	public GlobalApiResponse<UserFurnitureResp> listMyFurnitures(
		@AuthenticationPrincipal CustomUserDetails userDetails
	) {
		return GlobalApiResponse.ok(shopService.listMyFurnitures(userDetails.getUserId()));
	}

	@Operation(summary = "내 방 조회", description = "사용자의 방에 배치된 가구 목록을 조회")
	@GetMapping("/users/me/room")
	public GlobalApiResponse<RoomResp> getMyRoom(
		@AuthenticationPrincipal CustomUserDetails userDetails
	) {
		return GlobalApiResponse.ok(roomFurniturePlacementService.getMyRoom(userDetails.getUserId()));
	}

	@Operation(summary = "보유 가구 배치", description = "보유한 가구를 기본 좌표로 방에 배치")
	@ApiErrorCodes({"S01-001", "S00-001"})
	@PostMapping("/users/me/room/furnitures/{userFurnitureId}/placements")
	public GlobalApiResponse<RoomFurniturePlacementResp> placeFurniture(
		@AuthenticationPrincipal CustomUserDetails userDetails,
		@PathVariable Long userFurnitureId
	) {
		return GlobalApiResponse.ok("가구 배치 완료",
			roomFurniturePlacementService.placeFurniture(userDetails.getUserId(), userFurnitureId));
	}

	@Operation(summary = "배치 가구 위치 수정", description = "방에 배치된 가구의 좌표와 레이어를 수정")
	@ApiErrorCodes({"S02-001", "S01-001", "S00-001"})
	@PatchMapping("/users/me/room/placements/{placementId}")
	public GlobalApiResponse<RoomFurniturePlacementResp> updatePlacement(
		@AuthenticationPrincipal CustomUserDetails userDetails,
		@PathVariable Long placementId,
		@RequestBody UpdateRoomFurniturePlacementReq req
	) {
		return GlobalApiResponse.ok(
			roomFurniturePlacementService.updatePlacement(userDetails.getUserId(), placementId, req));
	}

	@Operation(summary = "방 가구 배치 제거", description = "보유 가구는 유지하고 방 배치만 제거")
	@ApiErrorCodes({"S02-001"})
	@DeleteMapping("/users/me/room/placements/{placementId}")
	public GlobalApiResponse<Void> removePlacement(
		@AuthenticationPrincipal CustomUserDetails userDetails,
		@PathVariable Long placementId
	) {
		roomFurniturePlacementService.removePlacement(userDetails.getUserId(), placementId);
		return GlobalApiResponse.noContent("가구 배치 제거 완료");
	}
}
