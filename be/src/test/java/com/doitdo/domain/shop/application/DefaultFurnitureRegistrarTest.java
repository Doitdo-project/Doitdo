package com.doitdo.domain.shop.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

import com.doitdo.domain.shop.entity.Furniture;
import com.doitdo.domain.shop.entity.RoomFurniturePlacement;
import com.doitdo.domain.shop.entity.UserFurniture;
import com.doitdo.domain.shop.repository.FurnitureRepository;
import com.doitdo.domain.shop.repository.RoomFurniturePlacementRepository;
import com.doitdo.domain.shop.repository.UserFurnitureRepository;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class DefaultFurnitureRegistrarTest {

	@Mock
	private FurnitureRepository furnitureRepository;

	@Mock
	private UserFurnitureRepository userFurnitureRepository;

	@Mock
	private RoomFurniturePlacementRepository roomFurniturePlacementRepository;

	@Test
	void registerForGrantsAndPlacesDefaultWallAndFloor() {
		DefaultFurnitureRegistrar registrar = new DefaultFurnitureRegistrar(
				furnitureRepository,
				userFurnitureRepository,
				roomFurniturePlacementRepository
		);
		Long userId = 1L;
		Furniture wall = furniture(57L, "DEFAULT_WALL", "WALL", 0, 0, 0);
		Furniture floor = furniture(58L, "DEFAULT_FLOOR", "FLOOR", 0, 420, 1);
		UserFurniture savedWall = userFurniture(100L, userId, 57L);
		UserFurniture savedFloor = userFurniture(101L, userId, 58L);

		given(furnitureRepository.findByCode("DEFAULT_WALL")).willReturn(Optional.of(wall));
		given(furnitureRepository.findByCode("DEFAULT_FLOOR")).willReturn(Optional.of(floor));
		given(userFurnitureRepository.findByUserIdAndFurnitureId(userId, 57L)).willReturn(Optional.empty());
		given(userFurnitureRepository.findByUserIdAndFurnitureId(userId, 58L)).willReturn(Optional.empty());
		given(userFurnitureRepository.save(any(UserFurniture.class))).willReturn(savedWall, savedFloor);

		registrar.registerFor(userId);

		ArgumentCaptor<UserFurniture> userFurnitureCaptor = ArgumentCaptor.forClass(UserFurniture.class);
		verify(userFurnitureRepository, times(2)).save(userFurnitureCaptor.capture());
		assertThat(userFurnitureCaptor.getAllValues())
				.extracting(UserFurniture::getFurnitureId)
				.containsExactly(57L, 58L);

		ArgumentCaptor<RoomFurniturePlacement> placementCaptor =
				ArgumentCaptor.forClass(RoomFurniturePlacement.class);
		verify(roomFurniturePlacementRepository, times(2)).save(placementCaptor.capture());
		assertThat(placementCaptor.getAllValues())
				.extracting(RoomFurniturePlacement::getUserFurnitureId)
				.containsExactly(100L, 101L);
		assertThat(placementCaptor.getAllValues())
				.extracting(RoomFurniturePlacement::getX)
				.containsExactly(0, 0);
		assertThat(placementCaptor.getAllValues())
				.extracting(RoomFurniturePlacement::getY)
				.containsExactly(0, 420);
	}

	@Test
	void registerForPlacesExistingDefaultFurnitureWithoutGrantingDuplicate() {
		DefaultFurnitureRegistrar registrar = new DefaultFurnitureRegistrar(
				furnitureRepository,
				userFurnitureRepository,
				roomFurniturePlacementRepository
		);
		Long userId = 1L;
		Furniture wall = furniture(57L, "DEFAULT_WALL", "WALL", 0, 0, 0);
		Furniture floor = furniture(58L, "DEFAULT_FLOOR", "FLOOR", 0, 420, 1);
		UserFurniture ownedWall = userFurniture(100L, userId, 57L);
		UserFurniture ownedFloor = userFurniture(101L, userId, 58L);

		given(furnitureRepository.findByCode("DEFAULT_WALL")).willReturn(Optional.of(wall));
		given(furnitureRepository.findByCode("DEFAULT_FLOOR")).willReturn(Optional.of(floor));
		given(userFurnitureRepository.findByUserIdAndFurnitureId(userId, 57L)).willReturn(Optional.of(ownedWall));
		given(userFurnitureRepository.findByUserIdAndFurnitureId(userId, 58L)).willReturn(Optional.of(ownedFloor));

		registrar.registerFor(userId);

		verify(userFurnitureRepository, never()).save(any(UserFurniture.class));
		ArgumentCaptor<RoomFurniturePlacement> placementCaptor =
				ArgumentCaptor.forClass(RoomFurniturePlacement.class);
		verify(roomFurniturePlacementRepository, times(2)).save(placementCaptor.capture());
		assertThat(placementCaptor.getAllValues())
				.extracting(RoomFurniturePlacement::getUserFurnitureId)
				.containsExactly(100L, 101L);
	}

	private Furniture furniture(Long furnitureId, String code, String category, Integer defaultX, Integer defaultY,
			Integer zIndex) {
		return Furniture.builder()
				.furnitureId(furnitureId)
				.code(code)
				.name(code)
				.description(code)
				.category(category)
				.price(0)
				.imageUrl("https://example.com/" + code + ".webp")
				.thumbnailUrl("https://example.com/" + code + ".webp")
				.defaultX(defaultX)
				.defaultY(defaultY)
				.width(390)
				.height(220)
				.zIndex(zIndex)
				.isOnSale(false)
				.isDeleted(false)
				.build();
	}

	private UserFurniture userFurniture(Long userFurnitureId, Long userId, Long furnitureId) {
		return UserFurniture.builder()
				.userFurnitureId(userFurnitureId)
				.userId(userId)
				.furnitureId(furnitureId)
				.build();
	}
}
