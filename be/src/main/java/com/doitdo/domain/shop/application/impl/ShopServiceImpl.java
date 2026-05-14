package com.doitdo.domain.shop.application.impl;

import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.doitdo.domain.shop.api.dto.resp.FurnitureShopItemResp;
import com.doitdo.domain.shop.api.dto.resp.FurnitureShopResp;
import com.doitdo.domain.shop.api.dto.resp.FurnitureThemeListResp;
import com.doitdo.domain.shop.api.dto.resp.FurnitureThemeResp;
import com.doitdo.domain.shop.api.dto.resp.PurchaseFurnitureResp;
import com.doitdo.domain.shop.api.dto.resp.RoomFurniturePlacementResp;
import com.doitdo.domain.shop.api.dto.resp.RoomResp;
import com.doitdo.domain.shop.api.dto.resp.UserFurnitureItemResp;
import com.doitdo.domain.shop.api.dto.resp.UserFurnitureResp;
import com.doitdo.domain.shop.application.ShopService;
import com.doitdo.domain.shop.entity.Furniture;
import com.doitdo.domain.shop.entity.FurniturePurchaseLog;
import com.doitdo.domain.shop.entity.FurnitureTheme;
import com.doitdo.domain.shop.entity.RoomFurniturePlacement;
import com.doitdo.domain.shop.entity.UserFurniture;
import com.doitdo.domain.shop.repository.FurniturePurchaseLogRepository;
import com.doitdo.domain.shop.repository.FurnitureRepository;
import com.doitdo.domain.shop.repository.FurnitureThemeRepository;
import com.doitdo.domain.shop.repository.RoomFurniturePlacementRepository;
import com.doitdo.domain.shop.repository.UserFurnitureRepository;
import com.doitdo.domain.user.entity.UserWallet;
import com.doitdo.domain.user.repository.UserWalletRepository;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.ShopErrorCode;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class ShopServiceImpl implements ShopService {

	private final FurnitureRepository furnitureRepository;
	private final FurnitureThemeRepository furnitureThemeRepository;
	private final UserFurnitureRepository userFurnitureRepository;
	private final FurniturePurchaseLogRepository furniturePurchaseLogRepository;
	private final UserWalletRepository userWalletRepository;
	private final RoomFurniturePlacementRepository roomFurniturePlacementRepository;

	@Override
	@Transactional(readOnly = true)
	public FurnitureShopResp listFurnitures(Long userId, String category) {
		List<Furniture> furnitures = category == null || category.isBlank()
			? furnitureRepository.findAllByIsDeletedFalseOrderByFurnitureIdAsc()
			: furnitureRepository.findAllByCategoryAndIsDeletedFalseOrderByFurnitureIdAsc(
				category.trim().toUpperCase(Locale.ROOT));
		Set<Long> ownedFurnitureIds = new HashSet<>(userFurnitureRepository.findFurnitureIdsByUserId(userId));
		Set<Long> placedFurnitureIds = findPlacedFurnitureIds(userId);
		List<FurnitureShopItemResp> items = furnitures.stream()
			.map(furniture -> FurnitureShopItemResp.from(
				furniture,
				ownedFurnitureIds.contains(furniture.getFurnitureId()),
				placedFurnitureIds.contains(furniture.getFurnitureId())
			))
			.toList();

		return new FurnitureShopResp(items);
	}

	@Override
	@Transactional(readOnly = true)
	public FurnitureThemeListResp listThemes() {
		List<FurnitureThemeResp> items = furnitureThemeRepository
			.findAllByIsActiveTrueOrderByDisplayOrderAscThemeCodeAsc()
			.stream()
			.map(theme -> FurnitureThemeResp.from(
				theme,
				furnitureRepository.countByThemeCodeAndIsDeletedFalse(theme.getThemeCode())
			))
			.toList();

		return new FurnitureThemeListResp(items);
	}

	@Override
	@Transactional
	public PurchaseFurnitureResp purchaseFurniture(Long userId, Long furnitureId) {
		Furniture furniture = furnitureRepository.findByFurnitureIdAndIsDeletedFalse(furnitureId)
			.orElseThrow(() -> new CustomException(ShopErrorCode.FURNITURE_NOT_FOUND));
		if (!Boolean.TRUE.equals(furniture.getIsOnSale())) {
			throw new CustomException(ShopErrorCode.FURNITURE_NOT_ON_SALE);
		}
		if (userFurnitureRepository.existsByUserIdAndFurnitureId(userId, furnitureId)) {
			throw new CustomException(ShopErrorCode.FURNITURE_ALREADY_OWNED);
		}

		UserWallet wallet = userWalletRepository.findByUserIdForUpdate(userId)
			.orElseThrow(() -> new CustomException(ShopErrorCode.WALLET_NOT_FOUND));
		wallet.spend(furniture.getPrice());

		UserFurniture userFurniture;
		try {
			userFurniture = userFurnitureRepository.saveAndFlush(UserFurniture.create(userId, furnitureId));
		} catch (DataIntegrityViolationException e) {
			throw new CustomException(ShopErrorCode.FURNITURE_ALREADY_OWNED);
		}
		furniturePurchaseLogRepository.save(FurniturePurchaseLog.create(
			userId,
			userFurniture.getUserFurnitureId(),
			furnitureId,
			furniture.getPrice(),
			wallet.getBalance()
		));

		return new PurchaseFurnitureResp(furnitureId, userFurniture.getUserFurnitureId(), true, true,
			wallet.getBalance());
	}

	@Override
	@Transactional(readOnly = true)
	public UserFurnitureResp listMyFurnitures(Long userId) {
		List<UserFurnitureItemResp> items = userFurnitureRepository.findAllByUserIdOrderByUserFurnitureIdAsc(userId)
			.stream()
			.map(userFurniture -> {
				Furniture furniture = furnitureRepository.findByFurnitureIdAndIsDeletedFalse(
						userFurniture.getFurnitureId())
					.orElseThrow(() -> new CustomException(ShopErrorCode.FURNITURE_NOT_FOUND));
				return UserFurnitureItemResp.from(userFurniture, furniture);
			})
			.toList();

		return new UserFurnitureResp(items);
	}

	@Override
	@Transactional(readOnly = true)
	public RoomResp previewRoom(Long userId, Long furnitureId) {
		Furniture previewFurniture = findFurniture(furnitureId);
		List<RoomFurniturePlacementResp> items = roomFurniturePlacementRepository
			.findAllByUserIdOrderByZIndexAscPlacementIdAsc(userId)
			.stream()
			.map(this::toRoomResp)
			.filter(item -> !previewFurniture.getCategory().equals(item.category()))
			.toList();

		List<RoomFurniturePlacementResp> previewItems = new java.util.ArrayList<>(items);
		previewItems.add(RoomFurniturePlacementResp.preview(previewFurniture));
		return new RoomResp(previewItems);
	}

	@Override
	@Transactional(readOnly = true)
	public RoomResp previewThemeRoom(Long userId, String themeCode) {
		String normalizedThemeCode = themeCode.trim().toUpperCase(Locale.ROOT);
		furnitureThemeRepository.findByThemeCodeAndIsActiveTrue(normalizedThemeCode)
			.orElseThrow(() -> new CustomException(ShopErrorCode.THEME_NOT_FOUND));
		List<Furniture> themeFurnitures = furnitureRepository
			.findAllByThemeCodeAndIsDeletedFalseOrderByZIndexAscFurnitureIdAsc(normalizedThemeCode);
		if (themeFurnitures.isEmpty()) {
			throw new CustomException(ShopErrorCode.THEME_NOT_FOUND);
		}
		validateUniqueCategories(themeFurnitures);

		Set<String> themeCategories = themeFurnitures.stream()
			.map(Furniture::getCategory)
			.collect(Collectors.toSet());
		List<RoomFurniturePlacementResp> items = roomFurniturePlacementRepository
			.findAllByUserIdOrderByZIndexAscPlacementIdAsc(userId)
			.stream()
			.map(this::toRoomResp)
			.filter(item -> !themeCategories.contains(item.category()))
			.toList();

		List<RoomFurniturePlacementResp> previewItems = new java.util.ArrayList<>(items);
		themeFurnitures.stream()
			.map(RoomFurniturePlacementResp::preview)
			.forEach(previewItems::add);
		return new RoomResp(previewItems);
	}

	private void validateUniqueCategories(List<Furniture> furnitures) {
		Set<String> categories = new HashSet<>();
		for (Furniture furniture : furnitures) {
			if (!categories.add(furniture.getCategory())) {
				throw new CustomException(ShopErrorCode.THEME_CATEGORY_DUPLICATED);
			}
		}
	}

	private Set<Long> findPlacedFurnitureIds(Long userId) {
		List<UserFurniture> userFurnitures = userFurnitureRepository.findAllByUserIdOrderByUserFurnitureIdAsc(userId);
		java.util.Map<Long, Long> furnitureIdByUserFurnitureId = userFurnitures.stream()
			.collect(java.util.stream.Collectors.toMap(UserFurniture::getUserFurnitureId, UserFurniture::getFurnitureId));

		return roomFurniturePlacementRepository.findAllByUserIdOrderByZIndexAscPlacementIdAsc(userId)
			.stream()
			.map(RoomFurniturePlacement::getUserFurnitureId)
			.map(furnitureIdByUserFurnitureId::get)
			.filter(java.util.Objects::nonNull)
			.collect(java.util.stream.Collectors.toSet());
	}

	private RoomFurniturePlacementResp toRoomResp(RoomFurniturePlacement placement) {
		UserFurniture userFurniture = userFurnitureRepository.findById(placement.getUserFurnitureId())
			.orElseThrow(() -> new CustomException(ShopErrorCode.USER_FURNITURE_NOT_FOUND));
		Furniture furniture = findFurniture(userFurniture.getFurnitureId());
		return RoomFurniturePlacementResp.from(placement, furniture);
	}

	private Furniture findFurniture(Long furnitureId) {
		return furnitureRepository.findByFurnitureIdAndIsDeletedFalse(furnitureId)
			.orElseThrow(() -> new CustomException(ShopErrorCode.FURNITURE_NOT_FOUND));
	}
}
