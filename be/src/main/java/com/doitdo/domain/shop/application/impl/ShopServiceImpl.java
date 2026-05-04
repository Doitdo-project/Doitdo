package com.doitdo.domain.shop.application.impl;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.doitdo.domain.shop.api.dto.resp.FurnitureShopItemResp;
import com.doitdo.domain.shop.api.dto.resp.FurnitureShopResp;
import com.doitdo.domain.shop.api.dto.resp.PurchaseFurnitureResp;
import com.doitdo.domain.shop.api.dto.resp.UserFurnitureItemResp;
import com.doitdo.domain.shop.api.dto.resp.UserFurnitureResp;
import com.doitdo.domain.shop.application.ShopService;
import com.doitdo.domain.shop.entity.Furniture;
import com.doitdo.domain.shop.entity.FurniturePurchaseLog;
import com.doitdo.domain.shop.entity.UserFurniture;
import com.doitdo.domain.shop.repository.FurniturePurchaseLogRepository;
import com.doitdo.domain.shop.repository.FurnitureRepository;
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
	private final UserFurnitureRepository userFurnitureRepository;
	private final FurniturePurchaseLogRepository furniturePurchaseLogRepository;
	private final UserWalletRepository userWalletRepository;

	@Override
	@Transactional(readOnly = true)
	public FurnitureShopResp listFurnitures(Long userId, String category) {
		List<Furniture> furnitures = category == null || category.isBlank()
			? furnitureRepository.findAllByIsDeletedFalseOrderByFurnitureIdAsc()
			: furnitureRepository.findAllByCategoryAndIsDeletedFalseOrderByFurnitureIdAsc(category);
		Set<Long> ownedFurnitureIds = new HashSet<>(userFurnitureRepository.findFurnitureIdsByUserId(userId));
		List<FurnitureShopItemResp> items = furnitures.stream()
			.map(furniture -> FurnitureShopItemResp.from(
				furniture,
				ownedFurnitureIds.contains(furniture.getFurnitureId())
			))
			.toList();

		return new FurnitureShopResp(items);
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

		UserFurniture userFurniture = userFurnitureRepository.save(UserFurniture.create(userId, furnitureId));
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
}
