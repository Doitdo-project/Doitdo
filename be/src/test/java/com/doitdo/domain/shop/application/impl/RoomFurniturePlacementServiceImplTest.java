package com.doitdo.domain.shop.application.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verify;

import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.doitdo.domain.shop.api.dto.req.UpdateRoomFurniturePlacementReq;
import com.doitdo.domain.shop.api.dto.resp.RoomFurniturePlacementResp;
import com.doitdo.domain.shop.entity.Furniture;
import com.doitdo.domain.shop.entity.RoomFurniturePlacement;
import com.doitdo.domain.shop.entity.UserFurniture;
import com.doitdo.domain.shop.repository.FurnitureRepository;
import com.doitdo.domain.shop.repository.RoomFurniturePlacementRepository;
import com.doitdo.domain.shop.repository.UserFurnitureRepository;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.ShopErrorCode;

@ExtendWith(MockitoExtension.class)
class RoomFurniturePlacementServiceImplTest {

	@Mock
	private RoomFurniturePlacementRepository roomFurniturePlacementRepository;

	@Mock
	private UserFurnitureRepository userFurnitureRepository;

	@Mock
	private FurnitureRepository furnitureRepository;

	@Test
	void getMyRoom_returnsPlacedFurniture() {
		RoomFurniturePlacementServiceImpl service = new RoomFurniturePlacementServiceImpl(
			roomFurniturePlacementRepository,
			userFurnitureRepository,
			furnitureRepository
		);
		Long userId = 1L;
		UserFurniture userFurniture = userFurniture(20L, userId, 10L);
		Furniture furniture = furniture(10L, "의자");
		RoomFurniturePlacement placement = placement(30L, userId, 20L, 120, 300, 5, 0);

		given(roomFurniturePlacementRepository.findAllByUserIdOrderByDisplayOrder(userId))
			.willReturn(List.of(placement));
		given(userFurnitureRepository.findById(20L)).willReturn(Optional.of(userFurniture));
		given(furnitureRepository.findByFurnitureIdAndIsDeletedFalse(10L)).willReturn(Optional.of(furniture));

		List<RoomFurniturePlacementResp> items = service.getMyRoom(userId).items();

		assertThat(items).hasSize(1);
		assertThat(items.get(0).placementId()).isEqualTo(30L);
		assertThat(items.get(0).userFurnitureId()).isEqualTo(20L);
		assertThat(items.get(0).furnitureId()).isEqualTo(10L);
		assertThat(items.get(0).x()).isEqualTo(120);
		assertThat(items.get(0).y()).isEqualTo(300);
	}

	@Test
	void placeFurniture_usesFurnitureDefaultPosition() {
		RoomFurniturePlacementServiceImpl service = new RoomFurniturePlacementServiceImpl(
			roomFurniturePlacementRepository,
			userFurnitureRepository,
			furnitureRepository
		);
		Long userId = 1L;
		UserFurniture userFurniture = userFurniture(20L, userId, 10L);
		Furniture furniture = furniture(10L, "의자");
		RoomFurniturePlacement saved = placement(30L, userId, 20L, 120, 300, 5, 0);

		given(userFurnitureRepository.findByUserIdAndUserFurnitureId(userId, 20L))
			.willReturn(Optional.of(userFurniture));
		given(furnitureRepository.findByFurnitureIdAndIsDeletedFalse(10L)).willReturn(Optional.of(furniture));
		given(roomFurniturePlacementRepository.save(any(RoomFurniturePlacement.class))).willReturn(saved);

		RoomFurniturePlacementResp resp = service.placeFurniture(userId, 20L);

		assertThat(resp.placementId()).isEqualTo(30L);
		assertThat(resp.x()).isEqualTo(120);
		assertThat(resp.y()).isEqualTo(300);
		assertThat(resp.zIndex()).isEqualTo(5);
	}

	@Test
	void updatePlacement_changesPosition() {
		RoomFurniturePlacementServiceImpl service = new RoomFurniturePlacementServiceImpl(
			roomFurniturePlacementRepository,
			userFurnitureRepository,
			furnitureRepository
		);
		Long userId = 1L;
		RoomFurniturePlacement placement = placement(30L, userId, 20L, 120, 300, 5, 0);
		UserFurniture userFurniture = userFurniture(20L, userId, 10L);
		Furniture furniture = furniture(10L, "의자");

		given(roomFurniturePlacementRepository.findByPlacementIdAndUserId(30L, userId))
			.willReturn(Optional.of(placement));
		given(userFurnitureRepository.findById(20L)).willReturn(Optional.of(userFurniture));
		given(furnitureRepository.findByFurnitureIdAndIsDeletedFalse(10L)).willReturn(Optional.of(furniture));

		RoomFurniturePlacementResp resp = service.updatePlacement(
			userId,
			30L,
			new UpdateRoomFurniturePlacementReq(200, 350, 9, 15)
		);

		assertThat(resp.x()).isEqualTo(200);
		assertThat(resp.y()).isEqualTo(350);
		assertThat(resp.zIndex()).isEqualTo(9);
		assertThat(resp.rotation()).isEqualTo(15);
	}

	@Test
	void removePlacement_deletesOnlyPlacement() {
		RoomFurniturePlacementServiceImpl service = new RoomFurniturePlacementServiceImpl(
			roomFurniturePlacementRepository,
			userFurnitureRepository,
			furnitureRepository
		);
		Long userId = 1L;
		RoomFurniturePlacement placement = placement(30L, userId, 20L, 120, 300, 5, 0);

		given(roomFurniturePlacementRepository.findByPlacementIdAndUserId(30L, userId))
			.willReturn(Optional.of(placement));

		service.removePlacement(userId, 30L);

		verify(roomFurniturePlacementRepository).delete(placement);
	}

	@Test
	void placeFurniture_rejectsOtherUsersFurniture() {
		RoomFurniturePlacementServiceImpl service = new RoomFurniturePlacementServiceImpl(
			roomFurniturePlacementRepository,
			userFurnitureRepository,
			furnitureRepository
		);

		given(userFurnitureRepository.findByUserIdAndUserFurnitureId(1L, 20L)).willReturn(Optional.empty());

		assertThatThrownBy(() -> service.placeFurniture(1L, 20L))
			.isInstanceOf(CustomException.class)
			.extracting(ex -> ((CustomException)ex).getErrorCode())
			.isEqualTo(ShopErrorCode.USER_FURNITURE_NOT_FOUND);
	}

	private UserFurniture userFurniture(Long userFurnitureId, Long userId, Long furnitureId) {
		return UserFurniture.builder()
			.userFurnitureId(userFurnitureId)
			.userId(userId)
			.furnitureId(furnitureId)
			.build();
	}

	private Furniture furniture(Long furnitureId, String name) {
		return Furniture.builder()
			.furnitureId(furnitureId)
			.code("FURNITURE_" + furnitureId)
			.name(name)
			.description(name + " 설명")
			.category("CHAIR")
			.price(100)
			.imageUrl("https://cdn.example.com/furniture.png")
			.thumbnailUrl("https://cdn.example.com/furniture_thumb.png")
			.defaultX(120)
			.defaultY(300)
			.width(80)
			.height(90)
			.zIndex(5)
			.isOnSale(true)
			.isDeleted(false)
			.build();
	}

	private RoomFurniturePlacement placement(Long placementId, Long userId, Long userFurnitureId, Integer x, Integer y,
		Integer zIndex, Integer rotation) {
		return RoomFurniturePlacement.builder()
			.placementId(placementId)
			.userId(userId)
			.userFurnitureId(userFurnitureId)
			.x(x)
			.y(y)
			.zIndex(zIndex)
			.rotation(rotation)
			.build();
	}
}
