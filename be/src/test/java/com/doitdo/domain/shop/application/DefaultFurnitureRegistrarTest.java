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
import org.springframework.transaction.annotation.Transactional;

@ExtendWith(MockitoExtension.class)
class DefaultFurnitureRegistrarTest {

	@Mock
	private FurnitureRepository furnitureRepository;

	@Mock
	private UserFurnitureRepository userFurnitureRepository;

	@Mock
	private RoomFurniturePlacementRepository roomFurniturePlacementRepository;

	@Test
	void registerForIsTransactional() throws NoSuchMethodException {
		Transactional transactional = DefaultFurnitureRegistrar.class
				.getMethod("registerFor", Long.class)
				.getAnnotation(Transactional.class);

		assertThat(transactional).isNotNull();
	}

	@Test
	void registerForGrantsAndPlacesDefaultBackground() {
		DefaultFurnitureRegistrar registrar = new DefaultFurnitureRegistrar(
				furnitureRepository,
				userFurnitureRepository,
				roomFurniturePlacementRepository
		);
		Long userId = 1L;
		Furniture background = furniture(57L, "DEFAULT_BACKGROUND", "BACKGROUND", 0, 0, 0);
		UserFurniture savedBackground = userFurniture(100L, userId, 57L);

		given(furnitureRepository.findByCodeAndIsDeletedFalse("DEFAULT_BACKGROUND")).willReturn(Optional.of(background));
		given(userFurnitureRepository.findByUserIdAndFurnitureId(userId, 57L)).willReturn(Optional.empty());
		given(userFurnitureRepository.save(any(UserFurniture.class))).willReturn(savedBackground);

		registrar.registerFor(userId);

		ArgumentCaptor<UserFurniture> userFurnitureCaptor = ArgumentCaptor.forClass(UserFurniture.class);
		verify(userFurnitureRepository, times(1)).save(userFurnitureCaptor.capture());
		assertThat(userFurnitureCaptor.getAllValues())
				.extracting(UserFurniture::getFurnitureId)
				.containsExactly(57L);

		ArgumentCaptor<RoomFurniturePlacement> placementCaptor =
				ArgumentCaptor.forClass(RoomFurniturePlacement.class);
		verify(roomFurniturePlacementRepository, times(1)).save(placementCaptor.capture());
		assertThat(placementCaptor.getAllValues())
				.extracting(RoomFurniturePlacement::getUserFurnitureId)
				.containsExactly(100L);
		assertThat(placementCaptor.getAllValues())
				.extracting(RoomFurniturePlacement::getX)
				.containsExactly(0);
		assertThat(placementCaptor.getAllValues())
				.extracting(RoomFurniturePlacement::getY)
				.containsExactly(0);
	}

	@Test
	void registerForPlacesExistingDefaultFurnitureWithoutGrantingDuplicate() {
		DefaultFurnitureRegistrar registrar = new DefaultFurnitureRegistrar(
				furnitureRepository,
				userFurnitureRepository,
				roomFurniturePlacementRepository
		);
		Long userId = 1L;
		Furniture background = furniture(57L, "DEFAULT_BACKGROUND", "BACKGROUND", 0, 0, 0);
		UserFurniture ownedBackground = userFurniture(100L, userId, 57L);

		given(furnitureRepository.findByCodeAndIsDeletedFalse("DEFAULT_BACKGROUND")).willReturn(Optional.of(background));
		given(userFurnitureRepository.findByUserIdAndFurnitureId(userId, 57L)).willReturn(Optional.of(ownedBackground));

		registrar.registerFor(userId);

		verify(userFurnitureRepository, never()).save(any(UserFurniture.class));
		ArgumentCaptor<RoomFurniturePlacement> placementCaptor =
				ArgumentCaptor.forClass(RoomFurniturePlacement.class);
		verify(roomFurniturePlacementRepository, times(1)).save(placementCaptor.capture());
		assertThat(placementCaptor.getAllValues())
				.extracting(RoomFurniturePlacement::getUserFurnitureId)
				.containsExactly(100L);
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
