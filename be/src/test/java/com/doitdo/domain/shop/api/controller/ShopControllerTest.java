package com.doitdo.domain.shop.api.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verify;

import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.doitdo.domain.auth.application.CustomUserDetails;
import com.doitdo.domain.shop.api.dto.req.UpdateRoomFurniturePlacementReq;
import com.doitdo.domain.shop.api.dto.resp.RoomFurniturePlacementResp;
import com.doitdo.domain.shop.api.dto.resp.RoomResp;
import com.doitdo.domain.shop.application.RoomFurniturePlacementService;
import com.doitdo.domain.shop.application.ShopService;
import com.doitdo.domain.user.entity.User;
import com.doitdo.global.api.response.GlobalApiResponse;

@ExtendWith(MockitoExtension.class)
class ShopControllerTest {

	@Mock
	private ShopService shopService;

	@Mock
	private RoomFurniturePlacementService roomFurniturePlacementService;

	private ShopController controller;
	private CustomUserDetails userDetails;

	@BeforeEach
	void setUp() {
		controller = new ShopController(shopService, roomFurniturePlacementService);
		User user = User.builder()
			.userId(1L)
			.email("test@example.com")
			.username("testuser")
			.password("password")
			.isDeleted(false)
			.build();
		userDetails = new CustomUserDetails(user);
	}

	@Test
	void getMyRoom_returnsPlacedFurnitureList() {
		RoomResp resp = new RoomResp(List.of(
			new RoomFurniturePlacementResp(3L, 10L, 1L, "나무 의자", "https://cdn.example.com/chair.png",
				120, 300, 80, 90, 5, 0)
		));
		given(roomFurniturePlacementService.getMyRoom(1L)).willReturn(resp);

		GlobalApiResponse<RoomResp> response = controller.getMyRoom(userDetails);

		assertThat(response.getStatus()).isEqualTo(200);
		assertThat(response.getData().items()).hasSize(1);
		assertThat(response.getData().items().get(0).placementId()).isEqualTo(3L);
	}

	@Test
	void placeFurniture_returnsCreatedPlacement() {
		RoomFurniturePlacementResp resp = new RoomFurniturePlacementResp(
			3L, 10L, 1L, "나무 의자", "https://cdn.example.com/chair.png", 120, 300, 80, 90, 5, 0
		);
		given(roomFurniturePlacementService.placeFurniture(1L, 10L)).willReturn(resp);

		GlobalApiResponse<RoomFurniturePlacementResp> response = controller.placeFurniture(userDetails, 10L);

		assertThat(response.getStatus()).isEqualTo(200);
		assertThat(response.getMessage()).isEqualTo("가구 배치 완료");
		assertThat(response.getData().userFurnitureId()).isEqualTo(10L);
	}

	@Test
	void updatePlacement_returnsUpdatedPlacement() {
		UpdateRoomFurniturePlacementReq req = new UpdateRoomFurniturePlacementReq(200, 350, 9, 15);
		RoomFurniturePlacementResp resp = new RoomFurniturePlacementResp(
			3L, 10L, 1L, "나무 의자", "https://cdn.example.com/chair.png", 200, 350, 80, 90, 9, 15
		);
		given(roomFurniturePlacementService.updatePlacement(1L, 3L, req)).willReturn(resp);

		GlobalApiResponse<RoomFurniturePlacementResp> response = controller.updatePlacement(userDetails, 3L, req);

		assertThat(response.getStatus()).isEqualTo(200);
		assertThat(response.getData().x()).isEqualTo(200);
		assertThat(response.getData().rotation()).isEqualTo(15);
	}

	@Test
	void removePlacement_returnsNoContentAndDeletesOnlyPlacement() {
		GlobalApiResponse<Void> response = controller.removePlacement(userDetails, 3L);

		assertThat(response.getStatus()).isEqualTo(204);
		assertThat(response.getMessage()).isEqualTo("가구 배치 제거 완료");
		verify(roomFurniturePlacementService).removePlacement(1L, 3L);
	}
}
