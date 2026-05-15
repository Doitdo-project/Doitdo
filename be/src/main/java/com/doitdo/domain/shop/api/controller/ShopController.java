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
import com.doitdo.domain.shop.api.dto.resp.FurnitureThemeListResp;
import com.doitdo.domain.shop.api.dto.resp.PlaceThemeResp;
import com.doitdo.domain.shop.api.dto.resp.PurchaseFurnitureResp;
import com.doitdo.domain.shop.api.dto.resp.PurchaseThemeResp;
import com.doitdo.domain.shop.api.dto.resp.RoomFurniturePlacementResp;
import com.doitdo.domain.shop.api.dto.resp.RoomResp;
import com.doitdo.domain.shop.api.dto.resp.ShopEntryResp;
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

	@Operation(summary = "상점 진입 데이터 조회",
		description = "상점 진입 시 필요한 가구 목록과 현재 내 방 배치 정보를 한 번에 조회한다. "
			+ "furnitures 는 구매/보유/배치 상태를 포함하고, room 은 실제 저장된 방 배치만 포함한다.")
	@GetMapping("/shop/entry")
	public GlobalApiResponse<ShopEntryResp> getShopEntry(
		@AuthenticationPrincipal CustomUserDetails userDetails,
		@RequestParam(required = false) String category
	) {
		Long userId = userDetails.getUserId();
		return GlobalApiResponse.ok(new ShopEntryResp(
			shopService.listFurnitures(userId, category),
			roomFurniturePlacementService.getMyRoom(userId)
		));
	}

	@Operation(summary = "상점 가구 목록 조회",
		description = "상점의 판매 가능 가구 목록을 조회한다. category query 가 있으면 해당 카테고리만 조회한다. "
			+ "현재 사용자가 이미 보유한 가구는 owned=true, 방에 배치 중인 가구는 placed=true 로 표시한다. "
			+ "status 는 PURCHASABLE, PLACEABLE, PLACED 중 하나로 반환한다.")
	@GetMapping("/shop/furnitures")
	public GlobalApiResponse<FurnitureShopResp> listFurnitures(
		@AuthenticationPrincipal CustomUserDetails userDetails,
		@RequestParam(required = false) String category
	) {
		return GlobalApiResponse.ok(shopService.listFurnitures(userDetails.getUserId(), category));
	}

	@Operation(summary = "가구 테마 목록 조회",
		description = "상점에서 선택 가능한 가구 테마 목록을 조회한다. 활성 테마만 displayOrder 오름차순으로 반환한다.")
	@GetMapping("/shop/themes")
	public GlobalApiResponse<FurnitureThemeListResp> listThemes(
		@AuthenticationPrincipal CustomUserDetails userDetails
	) {
		return GlobalApiResponse.ok(shopService.listThemes(userDetails.getUserId()));
	}

	@Operation(summary = "가구 구매",
		description = "월렛 잔액으로 가구를 구매한다. 가구 존재/판매 여부, 중복 보유 여부, 월렛 존재 여부, 잔액을 검증한다. "
			+ "구매 성공 시 월렛 차감, 보유 가구 생성, 구매 로그 저장을 한 트랜잭션으로 처리한다.")
	@ApiErrorCodes({"S00-001", "S00-002", "S00-003", "S00-004", "S00-005"})
	@PostMapping("/shop/furnitures/{furnitureId}/purchase")
	public GlobalApiResponse<PurchaseFurnitureResp> purchaseFurniture(
		@AuthenticationPrincipal CustomUserDetails userDetails,
		@PathVariable Long furnitureId
	) {
		return GlobalApiResponse.ok("가구 구매 완료",
			shopService.purchaseFurniture(userDetails.getUserId(), furnitureId));
	}

	@Operation(summary = "가구 테마 구매",
		description = "테마에 포함된 가구 중 현재 사용자가 보유하지 않은 가구만 구매한다. 구매 성공 시 자동 배치는 하지 않는다.")
	@ApiErrorCodes({"S03-001", "S03-002", "S03-003", "S03-010", "S00-003", "S00-005"})
	@PostMapping("/shop/themes/{themeCode}/purchase")
	public GlobalApiResponse<PurchaseThemeResp> purchaseTheme(
		@AuthenticationPrincipal CustomUserDetails userDetails,
		@PathVariable String themeCode
	) {
		return GlobalApiResponse.ok("테마 구매 완료",
			shopService.purchaseTheme(userDetails.getUserId(), themeCode));
	}

	@Operation(summary = "내 보유 가구 목록 조회",
		description = "현재 사용자가 구매해 보유 중인 가구 목록을 조회한다. user_furnitures 기준으로 조회하고 각 보유 가구의 Furniture 정보를 함께 반환한다.")
	@GetMapping("/users/me/furnitures")
	public GlobalApiResponse<UserFurnitureResp> listMyFurnitures(
		@AuthenticationPrincipal CustomUserDetails userDetails
	) {
		return GlobalApiResponse.ok(shopService.listMyFurnitures(userDetails.getUserId()));
	}

	@Operation(summary = "가구 방 미리보기",
		description = "상점의 특정 가구를 현재 사용자의 방에 배치했을 때의 미리보기 목록을 조회한다. 실제 배치는 저장하지 않는다. "
			+ "미리보기 대상과 같은 카테고리의 기존 배치는 응답에서 제외하고 preview=true 항목으로 대상 가구를 포함한다.")
	@ApiErrorCodes({"S00-001"})
	@GetMapping("/shop/furnitures/{furnitureId}/preview-room")
	public GlobalApiResponse<RoomResp> previewRoom(
		@AuthenticationPrincipal CustomUserDetails userDetails,
		@PathVariable Long furnitureId
	) {
		return GlobalApiResponse.ok(shopService.previewRoom(userDetails.getUserId(), furnitureId));
	}

	@Operation(summary = "가구 테마 방 미리보기",
		description = "테마에 포함된 여러 가구를 현재 사용자의 방에 배치했을 때의 미리보기 목록을 조회한다. 실제 배치는 저장하지 않는다. "
			+ "테마에 포함된 카테고리의 기존 배치는 응답에서 제외하고, 테마 가구는 preview=true 항목으로 포함한다.")
	@ApiErrorCodes({"S03-001", "S03-002"})
	@GetMapping("/shop/themes/{themeCode}/preview-room")
	public GlobalApiResponse<RoomResp> previewThemeRoom(
		@AuthenticationPrincipal CustomUserDetails userDetails,
		@PathVariable String themeCode
	) {
		return GlobalApiResponse.ok(shopService.previewThemeRoom(userDetails.getUserId(), themeCode));
	}

	@Operation(summary = "내 방 조회",
		description = "현재 사용자의 방에 배치된 가구 목록을 조회한다. room_furniture_placements 를 zIndex 오름차순, placementId 오름차순으로 정렬하고 "
			+ "각 배치 정보에 보유 가구와 가구 마스터 정보를 붙여 반환한다.")
	@GetMapping("/users/me/room")
	public GlobalApiResponse<RoomResp> getMyRoom(
		@AuthenticationPrincipal CustomUserDetails userDetails
	) {
		return GlobalApiResponse.ok(roomFurniturePlacementService.getMyRoom(userDetails.getUserId()));
	}

	@Operation(summary = "보유 가구 배치",
		description = "현재 사용자가 보유한 가구를 방에 배치한다. userId 와 userFurnitureId 로 본인 보유 가구인지 확인한다. "
			+ "같은 카테고리의 기존 배치가 있으면 기존 placement 를 제거하고 새 가구로 교체한다. "
			+ "배치 좌표는 가구 마스터의 defaultX/defaultY/zIndex 를 사용하고 rotation 은 0으로 저장한다.")
	@ApiErrorCodes({"S01-001", "S00-001"})
	@PostMapping("/users/me/room/furnitures/{userFurnitureId}/placements")
	public GlobalApiResponse<RoomFurniturePlacementResp> placeFurniture(
		@AuthenticationPrincipal CustomUserDetails userDetails,
		@PathVariable Long userFurnitureId
	) {
		return GlobalApiResponse.ok("가구 배치 완료",
			roomFurniturePlacementService.placeFurniture(userDetails.getUserId(), userFurnitureId));
	}

	@Operation(summary = "가구 테마 일괄 배치",
		description = "현재 사용자가 보유한 테마 가구를 방에 한 번에 배치한다. 같은 카테고리의 기존 배치는 제거하고 테마 가구로 교체한다.")
	@ApiErrorCodes({"S03-001", "S03-002", "S03-003", "S03-011", "S00-001"})
	@PostMapping("/users/me/room/themes/{themeCode}/placements")
	public GlobalApiResponse<PlaceThemeResp> placeTheme(
		@AuthenticationPrincipal CustomUserDetails userDetails,
		@PathVariable String themeCode
	) {
		return GlobalApiResponse.ok("테마 배치 완료",
			roomFurniturePlacementService.placeTheme(userDetails.getUserId(), themeCode));
	}

	@Operation(summary = "배치 가구 위치 수정",
		description = "현재 사용자의 방에 배치된 가구 위치를 수정한다. placementId 와 userId 로 본인 배치인지 확인한 뒤 "
			+ "x, y, zIndex, rotation 값을 업데이트한다.")
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

	@Operation(summary = "방 가구 배치 제거",
		description = "현재 사용자의 방에서 가구 배치만 제거한다. placementId 와 userId 로 본인 배치인지 확인한다. "
			+ "UserFurniture 는 삭제하지 않고 RoomFurniturePlacement row 만 삭제한다.")
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
