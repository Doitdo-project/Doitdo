package com.doitdo.domain.shop.application.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.doitdo.domain.shop.api.dto.req.UpdateRoomFurniturePlacementReq;
import com.doitdo.domain.shop.api.dto.resp.PlaceThemeResp;
import com.doitdo.domain.shop.api.dto.resp.RoomFurniturePlacementResp;
import com.doitdo.domain.shop.application.DefaultFurnitureRegistrar;
import com.doitdo.domain.shop.entity.Furniture;
import com.doitdo.domain.shop.entity.FurnitureTheme;
import com.doitdo.domain.shop.entity.RoomFurniturePlacement;
import com.doitdo.domain.shop.entity.UserFurniture;
import com.doitdo.domain.shop.repository.FurnitureRepository;
import com.doitdo.domain.shop.repository.FurnitureThemeRepository;
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

	@Mock
	private FurnitureThemeRepository furnitureThemeRepository;

	@Mock
	private DefaultFurnitureRegistrar defaultFurnitureRegistrar;

	private RoomFurniturePlacementServiceImpl buildService() {
		return new RoomFurniturePlacementServiceImpl(
			roomFurniturePlacementRepository,
			userFurnitureRepository,
			furnitureRepository,
			furnitureThemeRepository,
			defaultFurnitureRegistrar
		);
	}

	@Test
	void getMyRoom_returnsPlacedFurniture() {
		RoomFurniturePlacementServiceImpl service = buildService();
		Long userId = 1L;
		UserFurniture userFurniture = userFurniture(20L, userId, 10L);
		Furniture furniture = furniture(10L, "기본 배경", "BACKGROUND");
		RoomFurniturePlacement placement = placement(30L, userId, 20L, 120, 300, 5, 0);

		given(roomFurniturePlacementRepository.findAllByUserIdOrderByZIndexAscPlacementIdAsc(userId))
			.willReturn(List.of(placement));
		given(userFurnitureRepository.findAllById(List.of(20L))).willReturn(List.of(userFurniture));
		given(furnitureRepository.findAllById(List.of(10L))).willReturn(List.of(furniture));
		given(userFurnitureRepository.findById(20L)).willReturn(Optional.of(userFurniture));
		given(furnitureRepository.findByFurnitureIdAndIsDeletedFalse(10L)).willReturn(Optional.of(furniture));

		List<RoomFurniturePlacementResp> items = service.getMyRoom(userId).items();

		assertThat(items).hasSize(1);
		assertThat(items.get(0).placementId()).isEqualTo(30L);
		assertThat(items.get(0).userFurnitureId()).isEqualTo(20L);
		assertThat(items.get(0).furnitureId()).isEqualTo(10L);
		assertThat(items.get(0).zIndex()).isEqualTo(5);
	}

	@Test
	void getMyRoom_registersDefaultFurnitureWhenBackgroundIsMissing() {
		RoomFurniturePlacementServiceImpl service = buildService();
		Long userId = 1L;
		UserFurniture chairUserFurniture = userFurniture(19L, userId, 10L);
		UserFurniture backgroundUserFurniture = userFurniture(20L, userId, 57L);
		Furniture chair = furniture(10L, "의자", "CHAIR");
		Furniture background = furniture(57L, "기본 배경", "BACKGROUND");
		RoomFurniturePlacement chairPlacement = placement(29L, userId, 19L, 120, 300, 5, 0);
		RoomFurniturePlacement backgroundPlacement = placement(30L, userId, 20L, 0, 0, 0, 0);

		given(roomFurniturePlacementRepository.findAllByUserIdOrderByZIndexAscPlacementIdAsc(userId))
			.willReturn(List.of(chairPlacement), List.of(backgroundPlacement, chairPlacement));
		given(userFurnitureRepository.findAllById(List.of(19L))).willReturn(List.of(chairUserFurniture));
		given(furnitureRepository.findAllById(List.of(10L))).willReturn(List.of(chair));
		given(userFurnitureRepository.findById(20L)).willReturn(Optional.of(backgroundUserFurniture));
		given(userFurnitureRepository.findById(19L)).willReturn(Optional.of(chairUserFurniture));
		given(furnitureRepository.findByFurnitureIdAndIsDeletedFalse(57L)).willReturn(Optional.of(background));
		given(furnitureRepository.findByFurnitureIdAndIsDeletedFalse(10L)).willReturn(Optional.of(chair));

		List<RoomFurniturePlacementResp> items = service.getMyRoom(userId).items();

		verify(defaultFurnitureRegistrar).registerFor(userId);
		assertThat(items).hasSize(2);
		assertThat(items).extracting(RoomFurniturePlacementResp::category).containsExactly("BACKGROUND", "CHAIR");
	}

	@Test
	void placeFurniture_usesFurnitureDefaultPosition() {
		RoomFurniturePlacementServiceImpl service = buildService();
		Long userId = 1L;
		UserFurniture userFurniture = userFurniture(20L, userId, 10L);
		Furniture furniture = furniture(10L, "의자");
		RoomFurniturePlacement saved = placement(30L, userId, 20L, 120, 300, 5, 0);

		given(userFurnitureRepository.findByUserIdAndUserFurnitureId(userId, 20L))
			.willReturn(Optional.of(userFurniture));
		given(furnitureRepository.findByFurnitureIdAndIsDeletedFalse(10L)).willReturn(Optional.of(furniture));
		given(roomFurniturePlacementRepository.findAllByUserIdOrderByZIndexAscPlacementIdAsc(userId)).willReturn(List.of());
		given(roomFurniturePlacementRepository.save(any(RoomFurniturePlacement.class))).willReturn(saved);

		RoomFurniturePlacementResp resp = service.placeFurniture(userId, 20L);

		assertThat(resp.placementId()).isEqualTo(30L);
		assertThat(resp.zIndex()).isEqualTo(5);
	}

	@Test
	void placeFurniture_replacesExistingSameCategoryPlacement() {
		RoomFurniturePlacementServiceImpl service = buildService();
		Long userId = 1L;
		UserFurniture oldUserFurniture = userFurniture(20L, userId, 10L);
		UserFurniture newUserFurniture = userFurniture(21L, userId, 11L);
		Furniture oldClock = furniture(10L, "기존 시계", "CLOCK");
		Furniture newClock = furniture(11L, "새 시계", "CLOCK");
		RoomFurniturePlacement oldPlacement = placement(30L, userId, 20L, 120, 300, 5, 0);
		RoomFurniturePlacement saved = placement(31L, userId, 21L, 120, 300, 5, 0);

		given(userFurnitureRepository.findByUserIdAndUserFurnitureId(userId, 21L))
			.willReturn(Optional.of(newUserFurniture));
		given(furnitureRepository.findByFurnitureIdAndIsDeletedFalse(11L)).willReturn(Optional.of(newClock));
		given(roomFurniturePlacementRepository.findAllByUserIdOrderByZIndexAscPlacementIdAsc(userId))
			.willReturn(List.of(oldPlacement));
		given(userFurnitureRepository.findById(20L)).willReturn(Optional.of(oldUserFurniture));
		given(furnitureRepository.findByFurnitureIdAndIsDeletedFalse(10L)).willReturn(Optional.of(oldClock));
		given(roomFurniturePlacementRepository.save(any(RoomFurniturePlacement.class))).willReturn(saved);

		RoomFurniturePlacementResp resp = service.placeFurniture(userId, 21L);

		verify(roomFurniturePlacementRepository).delete(oldPlacement);
		assertThat(resp.placementId()).isEqualTo(31L);
		assertThat(resp.userFurnitureId()).isEqualTo(21L);
	}

	@Test
	void placeFurniture_returnsExistingPlacementWhenSameFurnitureAlreadyPlaced() {
		RoomFurniturePlacementServiceImpl service = buildService();
		Long userId = 1L;
		UserFurniture userFurniture = userFurniture(20L, userId, 10L);
		Furniture clock = furniture(10L, "시계", "CLOCK");
		RoomFurniturePlacement existingPlacement = placement(30L, userId, 20L, 120, 300, 5, 0);

		given(userFurnitureRepository.findByUserIdAndUserFurnitureId(userId, 20L))
			.willReturn(Optional.of(userFurniture));
		given(furnitureRepository.findByFurnitureIdAndIsDeletedFalse(10L)).willReturn(Optional.of(clock));
		given(roomFurniturePlacementRepository.findAllByUserIdOrderByZIndexAscPlacementIdAsc(userId))
			.willReturn(List.of(existingPlacement));
		given(userFurnitureRepository.findById(20L)).willReturn(Optional.of(userFurniture));

		RoomFurniturePlacementResp resp = service.placeFurniture(userId, 20L);

		verify(roomFurniturePlacementRepository, never()).delete(existingPlacement);
		verify(roomFurniturePlacementRepository, never()).save(any(RoomFurniturePlacement.class));
		assertThat(resp.placementId()).isEqualTo(30L);
	}

	@Test
	void updatePlacement_changesPosition() {
		RoomFurniturePlacementServiceImpl service = buildService();
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

		assertThat(placement.getX()).isEqualTo(200);
		assertThat(placement.getY()).isEqualTo(350);
		assertThat(resp.zIndex()).isEqualTo(9);
		assertThat(resp.rotation()).isEqualTo(15);
	}

	@Test
	void removePlacement_deletesOnlyPlacement() {
		RoomFurniturePlacementServiceImpl service = buildService();
		Long userId = 1L;
		RoomFurniturePlacement placement = placement(30L, userId, 20L, 120, 300, 5, 0);

		given(roomFurniturePlacementRepository.findByPlacementIdAndUserId(30L, userId))
			.willReturn(Optional.of(placement));

		service.removePlacement(userId, 30L);

		verify(roomFurniturePlacementRepository).delete(placement);
	}

	@Test
	void placeFurniture_rejectsOtherUsersFurniture() {
		RoomFurniturePlacementServiceImpl service = buildService();

		given(userFurnitureRepository.findByUserIdAndUserFurnitureId(1L, 20L)).willReturn(Optional.empty());

		assertThatThrownBy(() -> service.placeFurniture(1L, 20L))
			.isInstanceOf(CustomException.class)
			.extracting(ex -> ((CustomException)ex).getErrorCode())
			.isEqualTo(ShopErrorCode.USER_FURNITURE_NOT_FOUND);
	}

	@Test
	void placeTheme_replacesSameCategoryPlacementsWithOwnedThemeFurnitures() {
		RoomFurniturePlacementServiceImpl service = buildService();
		Long userId = 1L;
		FurnitureTheme moon = furnitureTheme("MOON", "달빛");
		Furniture oldBed = furniture(10L, "기존 침대", "BED");
		Furniture moonBed = furniture(11L, "달빛 침대", "BED");
		Furniture moonDesk = furniture(12L, "달빛 책상", "DESK");
		UserFurniture oldBedUserFurniture = userFurniture(20L, userId, 10L);
		UserFurniture moonBedUserFurniture = userFurniture(21L, userId, 11L);
		UserFurniture moonDeskUserFurniture = userFurniture(22L, userId, 12L);
		RoomFurniturePlacement oldBedPlacement = placement(30L, userId, 20L, 100, 200, 1, 0);
		RoomFurniturePlacement savedBedPlacement = placement(31L, userId, 21L, 120, 300, 5, 0);
		RoomFurniturePlacement savedDeskPlacement = placement(32L, userId, 22L, 120, 300, 5, 0);

		given(furnitureThemeRepository.findByThemeCodeAndIsActiveTrue("MOON")).willReturn(Optional.of(moon));
		given(furnitureRepository.findAllByThemeCodeAndIsDeletedFalseOrderByZIndexAscFurnitureIdAsc("MOON"))
			.willReturn(List.of(moonBed, moonDesk));
		given(userFurnitureRepository.findAllByUserIdOrderByUserFurnitureIdAsc(userId))
			.willReturn(List.of(oldBedUserFurniture, moonBedUserFurniture, moonDeskUserFurniture));
		given(roomFurniturePlacementRepository.findAllByUserIdOrderByZIndexAscPlacementIdAsc(userId))
			.willReturn(List.of(oldBedPlacement));
		given(userFurnitureRepository.findById(20L)).willReturn(Optional.of(oldBedUserFurniture));
		given(furnitureRepository.findByFurnitureIdAndIsDeletedFalse(10L)).willReturn(Optional.of(oldBed));
		given(roomFurniturePlacementRepository.save(any(RoomFurniturePlacement.class)))
			.willReturn(savedBedPlacement, savedDeskPlacement);

		PlaceThemeResp resp = service.placeTheme(userId, "moon");

		verify(roomFurniturePlacementRepository).delete(oldBedPlacement);
		assertThat(resp.themeCode()).isEqualTo("MOON");
		assertThat(resp.placedCount()).isEqualTo(2);
		assertThat(resp.items()).extracting(RoomFurniturePlacementResp::userFurnitureId)
			.containsExactly(21L, 22L);
	}

	@Test
	void placeTheme_rejectsWhenThemeFurnitureIsNotOwned() {
		RoomFurniturePlacementServiceImpl service = buildService();
		Long userId = 1L;
		FurnitureTheme moon = furnitureTheme("MOON", "달빛");
		Furniture moonBed = furniture(11L, "달빛 침대", "BED");

		given(furnitureThemeRepository.findByThemeCodeAndIsActiveTrue("MOON")).willReturn(Optional.of(moon));
		given(furnitureRepository.findAllByThemeCodeAndIsDeletedFalseOrderByZIndexAscFurnitureIdAsc("MOON"))
			.willReturn(List.of(moonBed));
		given(userFurnitureRepository.findAllByUserIdOrderByUserFurnitureIdAsc(userId)).willReturn(List.of());

		assertThatThrownBy(() -> service.placeTheme(userId, "MOON"))
			.isInstanceOf(CustomException.class)
			.extracting(ex -> ((CustomException)ex).getErrorCode())
			.isEqualTo(ShopErrorCode.USER_FURNITURE_NOT_FOUND);
		verify(roomFurniturePlacementRepository, never()).save(any(RoomFurniturePlacement.class));
	}

	private UserFurniture userFurniture(Long userFurnitureId, Long userId, Long furnitureId) {
		return UserFurniture.builder()
			.userFurnitureId(userFurnitureId)
			.userId(userId)
			.furnitureId(furnitureId)
			.build();
	}

	private FurnitureTheme furnitureTheme(String themeCode, String themeName) {
		return FurnitureTheme.builder()
			.themeCode(themeCode)
			.themeName(themeName)
			.thumbnailUrl("https://cdn.example.com/" + themeCode + ".png")
			.displayOrder(1)
			.isActive(true)
			.build();
	}

	private Furniture furniture(Long furnitureId, String name) {
		return furniture(furnitureId, name, "CHAIR");
	}

	private Furniture furniture(Long furnitureId, String name, String category) {
		return Furniture.builder()
			.furnitureId(furnitureId)
			.code("FURNITURE_" + furnitureId)
			.name(name)
			.description(name + " 설명")
			.category(category)
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
