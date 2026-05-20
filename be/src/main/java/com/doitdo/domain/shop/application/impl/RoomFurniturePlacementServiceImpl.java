package com.doitdo.domain.shop.application.impl;

import java.util.List;
import java.util.HashSet;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.doitdo.domain.shop.api.dto.req.UpdateRoomFurniturePlacementReq;
import com.doitdo.domain.shop.api.dto.resp.PlaceThemeResp;
import com.doitdo.domain.shop.api.dto.resp.RoomFurniturePlacementResp;
import com.doitdo.domain.shop.api.dto.resp.RoomResp;
import com.doitdo.domain.shop.application.DefaultFurnitureRegistrar;
import com.doitdo.domain.shop.application.RoomFurniturePlacementService;
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

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class RoomFurniturePlacementServiceImpl implements RoomFurniturePlacementService {

	private final RoomFurniturePlacementRepository roomFurniturePlacementRepository;
	private final UserFurnitureRepository userFurnitureRepository;
	private final FurnitureRepository furnitureRepository;
	private final FurnitureThemeRepository furnitureThemeRepository;
	private final DefaultFurnitureRegistrar defaultFurnitureRegistrar;

	@Override
	@Transactional
	public RoomResp getMyRoom(Long userId) {
		List<RoomFurniturePlacement> placements =
			roomFurniturePlacementRepository.findAllByUserIdOrderByZIndexAscPlacementIdAsc(userId);
		if (missingBackground(placements)) {
			defaultFurnitureRegistrar.registerFor(userId);
			placements = roomFurniturePlacementRepository.findAllByUserIdOrderByZIndexAscPlacementIdAsc(userId);
		}

		List<RoomFurniturePlacementResp> items = placements.stream()
				.map(this::toResp)
				.toList();

		return new RoomResp(items);
	}

	private boolean missingBackground(List<RoomFurniturePlacement> placements) {
		List<Long> userFurnitureIds = placements.stream()
				.map(RoomFurniturePlacement::getUserFurnitureId)
				.toList();
		Map<Long, UserFurniture> userFurnitureById = userFurnitureRepository.findAllById(userFurnitureIds)
				.stream()
				.collect(Collectors.toMap(UserFurniture::getUserFurnitureId, Function.identity()));
		List<Long> furnitureIds = userFurnitureById.values()
				.stream()
				.map(UserFurniture::getFurnitureId)
				.toList();
		Map<Long, Furniture> furnitureById = furnitureRepository.findAllById(furnitureIds)
				.stream()
				.collect(Collectors.toMap(Furniture::getFurnitureId, Function.identity()));

		Set<String> categories = placements.stream()
				.map(RoomFurniturePlacement::getUserFurnitureId)
				.map(userFurnitureById::get)
				.filter(Objects::nonNull)
				.map(UserFurniture::getFurnitureId)
				.map(furnitureById::get)
				.filter(Objects::nonNull)
				.map(Furniture::getCategory)
				.collect(Collectors.toSet());
		return !categories.contains("BACKGROUND");
	}

	@Override
	@Transactional
	public RoomFurniturePlacementResp placeFurniture(Long userId, Long userFurnitureId) {
		UserFurniture userFurniture = findMyUserFurniture(userId, userFurnitureId);
		Furniture furniture = findFurniture(userFurniture.getFurnitureId());
		java.util.Optional<RoomFurniturePlacement> currentPlacement = roomFurniturePlacementRepository
			.findAllByUserIdOrderByZIndexAscPlacementIdAsc(userId)
			.stream()
			.filter(placement -> isSameCategoryPlacement(placement, furniture))
			.findFirst();
		if (currentPlacement.isPresent()) {
			RoomFurniturePlacement placement = currentPlacement.get();
			if (placement.getUserFurnitureId().equals(userFurnitureId)) {
				return RoomFurniturePlacementResp.from(placement, furniture);
			}
			roomFurniturePlacementRepository.delete(placement);
		}
		RoomFurniturePlacement placement = roomFurniturePlacementRepository.save(
			RoomFurniturePlacement.create(userId, userFurnitureId, furniture)
		);

		return RoomFurniturePlacementResp.from(placement, furniture);
	}

	@Override
	@Transactional
	public PlaceThemeResp placeTheme(Long userId, String themeCode) {
		String normalizedThemeCode = themeCode.trim().toUpperCase(java.util.Locale.ROOT);
		FurnitureTheme theme = furnitureThemeRepository.findByThemeCodeAndIsActiveTrue(normalizedThemeCode)
			.orElseThrow(() -> new CustomException(ShopErrorCode.THEME_NOT_FOUND));
		List<Furniture> themeFurnitures = furnitureRepository
			.findAllByThemeCodeAndIsDeletedFalseOrderByZIndexAscFurnitureIdAsc(normalizedThemeCode);
		if (themeFurnitures.isEmpty()) {
			throw new CustomException(ShopErrorCode.THEME_EMPTY);
		}
		validateUniqueCategories(themeFurnitures);

		Map<Long, UserFurniture> ownedByFurnitureId = userFurnitureRepository
			.findAllByUserIdOrderByUserFurnitureIdAsc(userId)
			.stream()
			.collect(Collectors.toMap(UserFurniture::getFurnitureId, Function.identity()));
		Map<Long, UserFurniture> ownedByUserFurnitureId = ownedByFurnitureId.values()
			.stream()
			.collect(Collectors.toMap(UserFurniture::getUserFurnitureId, Function.identity()));
		for (Furniture furniture : themeFurnitures) {
			if (!ownedByFurnitureId.containsKey(furniture.getFurnitureId())) {
				throw new CustomException(ShopErrorCode.THEME_NOT_FULLY_OWNED);
			}
		}

		Set<String> themeCategories = themeFurnitures.stream()
			.map(Furniture::getCategory)
			.collect(Collectors.toSet());
		List<RoomFurniturePlacement> currentPlacements =
			roomFurniturePlacementRepository.findAllByUserIdOrderByZIndexAscPlacementIdAsc(userId);
		List<Long> placedFurnitureIds = currentPlacements.stream()
			.map(RoomFurniturePlacement::getUserFurnitureId)
			.map(ownedByUserFurnitureId::get)
			.filter(Objects::nonNull)
			.map(UserFurniture::getFurnitureId)
			.toList();
		Map<Long, Furniture> furnitureById = furnitureRepository.findAllById(placedFurnitureIds)
			.stream()
			.collect(Collectors.toMap(Furniture::getFurnitureId, Function.identity()));
		for (RoomFurniturePlacement placement : currentPlacements) {
			UserFurniture userFurniture = ownedByUserFurnitureId.get(placement.getUserFurnitureId());
			Furniture furniture = userFurniture == null ? null : furnitureById.get(userFurniture.getFurnitureId());
			if (furniture != null && themeCategories.contains(furniture.getCategory())) {
				roomFurniturePlacementRepository.delete(placement);
			}
		}

		List<RoomFurniturePlacementResp> items = new java.util.ArrayList<>();
		for (Furniture furniture : themeFurnitures) {
			UserFurniture userFurniture = ownedByFurnitureId.get(furniture.getFurnitureId());
			RoomFurniturePlacement placement = roomFurniturePlacementRepository.save(
				RoomFurniturePlacement.create(userId, userFurniture.getUserFurnitureId(), furniture)
			);
			items.add(RoomFurniturePlacementResp.from(placement, furniture));
		}

		return new PlaceThemeResp(theme.getThemeCode(), theme.getThemeName(), items.size(), items);
	}

	@Override
	@Transactional
	public RoomFurniturePlacementResp updatePlacement(Long userId, Long placementId,
		UpdateRoomFurniturePlacementReq req) {
		RoomFurniturePlacement placement = findMyPlacement(userId, placementId);
		placement.updatePosition(req.x(), req.y(), req.zIndex(), req.rotation());

		return toResp(placement);
	}

	@Override
	@Transactional
	public void removePlacement(Long userId, Long placementId) {
		RoomFurniturePlacement placement = findMyPlacement(userId, placementId);
		roomFurniturePlacementRepository.delete(placement);
	}

	private RoomFurniturePlacementResp toResp(RoomFurniturePlacement placement) {
		UserFurniture userFurniture = userFurnitureRepository.findById(placement.getUserFurnitureId())
			.orElseThrow(() -> new CustomException(ShopErrorCode.USER_FURNITURE_NOT_FOUND));
		Furniture furniture = findFurniture(userFurniture.getFurnitureId());
		return RoomFurniturePlacementResp.from(placement, furniture);
	}

	private void validateUniqueCategories(List<Furniture> furnitures) {
		Set<String> categories = new HashSet<>();
		for (Furniture furniture : furnitures) {
			if (!categories.add(furniture.getCategory())) {
				throw new CustomException(ShopErrorCode.THEME_CATEGORY_DUPLICATED);
			}
		}
	}

	private UserFurniture findMyUserFurniture(Long userId, Long userFurnitureId) {
		return userFurnitureRepository.findByUserIdAndUserFurnitureId(userId, userFurnitureId)
			.orElseThrow(() -> new CustomException(ShopErrorCode.USER_FURNITURE_NOT_FOUND));
	}

	private RoomFurniturePlacement findMyPlacement(Long userId, Long placementId) {
		return roomFurniturePlacementRepository.findByPlacementIdAndUserId(placementId, userId)
			.orElseThrow(() -> new CustomException(ShopErrorCode.PLACEMENT_NOT_FOUND));
	}

	private boolean isSameCategoryPlacement(RoomFurniturePlacement placement, Furniture furniture) {
		UserFurniture placedUserFurniture = userFurnitureRepository.findById(placement.getUserFurnitureId())
			.orElseThrow(() -> new CustomException(ShopErrorCode.USER_FURNITURE_NOT_FOUND));
		Furniture placedFurniture = findFurniture(placedUserFurniture.getFurnitureId());
		return furniture.getCategory().equals(placedFurniture.getCategory());
	}

	private Furniture findFurniture(Long furnitureId) {
		return furnitureRepository.findByFurnitureIdAndIsDeletedFalse(furnitureId)
			.orElseThrow(() -> new CustomException(ShopErrorCode.FURNITURE_NOT_FOUND));
	}
}
