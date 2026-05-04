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
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;

import com.doitdo.domain.shop.api.dto.resp.FurnitureShopItemResp;
import com.doitdo.domain.shop.api.dto.resp.FurnitureShopStatus;
import com.doitdo.domain.shop.api.dto.resp.PurchaseFurnitureResp;
import com.doitdo.domain.shop.api.dto.resp.RoomResp;
import com.doitdo.domain.shop.entity.Furniture;
import com.doitdo.domain.shop.entity.FurniturePurchaseLog;
import com.doitdo.domain.shop.entity.RoomFurniturePlacement;
import com.doitdo.domain.shop.entity.UserFurniture;
import com.doitdo.domain.shop.repository.FurniturePurchaseLogRepository;
import com.doitdo.domain.shop.repository.FurnitureRepository;
import com.doitdo.domain.shop.repository.RoomFurniturePlacementRepository;
import com.doitdo.domain.shop.repository.UserFurnitureRepository;
import com.doitdo.domain.user.entity.UserWallet;
import com.doitdo.domain.user.repository.UserWalletRepository;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.ShopErrorCode;

@ExtendWith(MockitoExtension.class)
class ShopServiceImplTest {

	@Mock
	private FurnitureRepository furnitureRepository;

	@Mock
	private UserFurnitureRepository userFurnitureRepository;

	@Mock
	private FurniturePurchaseLogRepository furniturePurchaseLogRepository;

	@Mock
	private UserWalletRepository userWalletRepository;

	@Mock
	private RoomFurniturePlacementRepository roomFurniturePlacementRepository;

	@Test
	void listFurnitures_marksOwnedFurnitureAsSoldOut() {
		ShopServiceImpl service = new ShopServiceImpl(
			furnitureRepository,
			userFurnitureRepository,
			furniturePurchaseLogRepository,
			userWalletRepository,
			roomFurniturePlacementRepository
		);
		Long userId = 1L;
		Furniture chair = furniture(10L, "CHAIR_001", "의자", "CHAIR", 100, true);
		Furniture desk = furniture(11L, "DESK_001", "책상", "DESK", 200, true);

		given(furnitureRepository.findAllByIsDeletedFalseOrderByFurnitureIdAsc())
			.willReturn(List.of(chair, desk));
		given(userFurnitureRepository.findFurnitureIdsByUserId(userId))
			.willReturn(List.of(10L));
		given(userFurnitureRepository.findAllByUserIdOrderByUserFurnitureIdAsc(userId))
			.willReturn(List.of(userFurniture(20L, userId, 10L)));
		given(roomFurniturePlacementRepository.findAllByUserIdOrderByZIndexAscPlacementIdAsc(userId))
			.willReturn(List.of());

		List<FurnitureShopItemResp> resp = service.listFurnitures(userId, null).items();

		assertThat(resp).hasSize(2);
		assertThat(resp.get(0).furnitureId()).isEqualTo(10L);
		assertThat(resp.get(0).owned()).isTrue();
		assertThat(resp.get(0).soldOut()).isTrue();
		assertThat(resp.get(0).placed()).isFalse();
		assertThat(resp.get(0).status()).isEqualTo(FurnitureShopStatus.PLACEABLE);
		assertThat(resp.get(1).furnitureId()).isEqualTo(11L);
		assertThat(resp.get(1).owned()).isFalse();
		assertThat(resp.get(1).soldOut()).isFalse();
		assertThat(resp.get(1).status()).isEqualTo(FurnitureShopStatus.PURCHASABLE);
	}

	@Test
	void listFurnitures_marksPlacedFurnitureAsPlaced() {
		ShopServiceImpl service = new ShopServiceImpl(
			furnitureRepository,
			userFurnitureRepository,
			furniturePurchaseLogRepository,
			userWalletRepository,
			roomFurniturePlacementRepository
		);
		Long userId = 1L;
		Furniture clock = furniture(10L, "CLOCK_001", "시계", "CLOCK", 100, true);
		UserFurniture userFurniture = userFurniture(20L, userId, 10L);
		RoomFurniturePlacement placement = placement(30L, userId, 20L, 120, 300, 5, 0);

		given(furnitureRepository.findAllByIsDeletedFalseOrderByFurnitureIdAsc()).willReturn(List.of(clock));
		given(userFurnitureRepository.findFurnitureIdsByUserId(userId)).willReturn(List.of(10L));
		given(userFurnitureRepository.findAllByUserIdOrderByUserFurnitureIdAsc(userId)).willReturn(List.of(userFurniture));
		given(roomFurniturePlacementRepository.findAllByUserIdOrderByZIndexAscPlacementIdAsc(userId)).willReturn(List.of(placement));

		FurnitureShopItemResp resp = service.listFurnitures(userId, null).items().get(0);

		assertThat(resp.owned()).isTrue();
		assertThat(resp.placed()).isTrue();
		assertThat(resp.status()).isEqualTo(FurnitureShopStatus.PLACED);
	}

	@Test
	void purchaseFurniture_spendsWalletAndCreatesUserFurnitureAndLog() {
		ShopServiceImpl service = new ShopServiceImpl(
			furnitureRepository,
			userFurnitureRepository,
			furniturePurchaseLogRepository,
			userWalletRepository,
			roomFurniturePlacementRepository
		);
		Long userId = 1L;
		Long furnitureId = 10L;
		Furniture furniture = furniture(furnitureId, "CHAIR_001", "의자", "CHAIR", 100, true);
		UserWallet wallet = UserWallet.builder()
			.userId(userId)
			.balance(150)
			.build();
		UserFurniture savedUserFurniture = UserFurniture.builder()
			.userFurnitureId(20L)
			.userId(userId)
			.furnitureId(furnitureId)
			.build();

		given(furnitureRepository.findByFurnitureIdAndIsDeletedFalse(furnitureId))
			.willReturn(Optional.of(furniture));
		given(userFurnitureRepository.existsByUserIdAndFurnitureId(userId, furnitureId))
			.willReturn(false);
		given(userWalletRepository.findByUserIdForUpdate(userId)).willReturn(Optional.of(wallet));
		given(userFurnitureRepository.save(any(UserFurniture.class))).willReturn(savedUserFurniture);

		PurchaseFurnitureResp resp = service.purchaseFurniture(userId, furnitureId);

		assertThat(resp.furnitureId()).isEqualTo(furnitureId);
		assertThat(resp.userFurnitureId()).isEqualTo(20L);
		assertThat(resp.owned()).isTrue();
		assertThat(resp.soldOut()).isTrue();
		assertThat(resp.balance()).isEqualTo(50);

		ArgumentCaptor<FurniturePurchaseLog> logCaptor = ArgumentCaptor.forClass(FurniturePurchaseLog.class);
		verify(furniturePurchaseLogRepository).save(logCaptor.capture());
		assertThat(logCaptor.getValue().getUserId()).isEqualTo(userId);
		assertThat(logCaptor.getValue().getFurnitureId()).isEqualTo(furnitureId);
		assertThat(logCaptor.getValue().getPrice()).isEqualTo(100);
		assertThat(logCaptor.getValue().getBalanceAfterPurchase()).isEqualTo(50);
	}

	@Test
	void purchaseFurniture_rejectsAlreadyOwnedFurniture() {
		ShopServiceImpl service = new ShopServiceImpl(
			furnitureRepository,
			userFurnitureRepository,
			furniturePurchaseLogRepository,
			userWalletRepository,
			roomFurniturePlacementRepository
		);
		Long userId = 1L;
		Long furnitureId = 10L;

		given(furnitureRepository.findByFurnitureIdAndIsDeletedFalse(furnitureId))
			.willReturn(Optional.of(furniture(furnitureId, "CHAIR_001", "의자", "CHAIR", 100, true)));
		given(userFurnitureRepository.existsByUserIdAndFurnitureId(userId, furnitureId))
			.willReturn(true);

		assertThatThrownBy(() -> service.purchaseFurniture(userId, furnitureId))
			.isInstanceOf(CustomException.class)
			.extracting(ex -> ((CustomException)ex).getErrorCode())
			.isEqualTo(ShopErrorCode.FURNITURE_ALREADY_OWNED);
		verify(userWalletRepository, never()).findByUserIdForUpdate(userId);
		verify(userFurnitureRepository, never()).save(any(UserFurniture.class));
	}

	@Test
	void purchaseFurniture_convertsDuplicateUserFurnitureSaveFailureToAlreadyOwned() {
		ShopServiceImpl service = new ShopServiceImpl(
			furnitureRepository,
			userFurnitureRepository,
			furniturePurchaseLogRepository,
			userWalletRepository,
			roomFurniturePlacementRepository
		);
		Long userId = 1L;
		Long furnitureId = 10L;
		UserWallet wallet = UserWallet.builder()
			.userId(userId)
			.balance(150)
			.build();

		given(furnitureRepository.findByFurnitureIdAndIsDeletedFalse(furnitureId))
			.willReturn(Optional.of(furniture(furnitureId, "CHAIR_001", "chair", "CHAIR", 100, true)));
		given(userFurnitureRepository.existsByUserIdAndFurnitureId(userId, furnitureId))
			.willReturn(false);
		given(userWalletRepository.findByUserIdForUpdate(userId)).willReturn(Optional.of(wallet));
		given(userFurnitureRepository.save(any(UserFurniture.class)))
			.willThrow(new DataIntegrityViolationException("duplicate user furniture"));

		assertThatThrownBy(() -> service.purchaseFurniture(userId, furnitureId))
			.isInstanceOf(CustomException.class)
			.extracting(ex -> ((CustomException)ex).getErrorCode())
			.isEqualTo(ShopErrorCode.FURNITURE_ALREADY_OWNED);
		verify(furniturePurchaseLogRepository, never()).save(any(FurniturePurchaseLog.class));
	}

	@Test
	void purchaseFurniture_rejectsInsufficientBalance() {
		ShopServiceImpl service = new ShopServiceImpl(
			furnitureRepository,
			userFurnitureRepository,
			furniturePurchaseLogRepository,
			userWalletRepository,
			roomFurniturePlacementRepository
		);
		Long userId = 1L;
		Long furnitureId = 10L;
		UserWallet wallet = UserWallet.builder()
			.userId(userId)
			.balance(50)
			.build();

		given(furnitureRepository.findByFurnitureIdAndIsDeletedFalse(furnitureId))
			.willReturn(Optional.of(furniture(furnitureId, "CHAIR_001", "의자", "CHAIR", 100, true)));
		given(userFurnitureRepository.existsByUserIdAndFurnitureId(userId, furnitureId))
			.willReturn(false);
		given(userWalletRepository.findByUserIdForUpdate(userId)).willReturn(Optional.of(wallet));

		assertThatThrownBy(() -> service.purchaseFurniture(userId, furnitureId))
			.isInstanceOf(CustomException.class)
			.extracting(ex -> ((CustomException)ex).getErrorCode())
			.isEqualTo(ShopErrorCode.INSUFFICIENT_BALANCE);
		verify(userFurnitureRepository, never()).save(any(UserFurniture.class));
		verify(furniturePurchaseLogRepository, never()).save(any(FurniturePurchaseLog.class));
	}

	@Test
	void previewRoom_excludesSameCategoryPlacementAndAddsPreviewFurniture() {
		ShopServiceImpl service = new ShopServiceImpl(
			furnitureRepository,
			userFurnitureRepository,
			furniturePurchaseLogRepository,
			userWalletRepository,
			roomFurniturePlacementRepository
		);
		Long userId = 1L;
		Furniture oldClock = furniture(10L, "CLOCK_OLD", "기존 시계", "CLOCK", 100, true);
		Furniture bed = furniture(11L, "BED_001", "침대", "BED", 200, true);
		Furniture previewClock = furniture(12L, "CLOCK_NEW", "새 시계", "CLOCK", 150, true);
		UserFurniture oldClockUserFurniture = userFurniture(20L, userId, 10L);
		UserFurniture bedUserFurniture = userFurniture(21L, userId, 11L);
		RoomFurniturePlacement oldClockPlacement = placement(30L, userId, 20L, 10, 20, 1, 0);
		RoomFurniturePlacement bedPlacement = placement(31L, userId, 21L, 30, 40, 2, 0);

		given(furnitureRepository.findByFurnitureIdAndIsDeletedFalse(12L)).willReturn(Optional.of(previewClock));
		given(roomFurniturePlacementRepository.findAllByUserIdOrderByZIndexAscPlacementIdAsc(userId))
			.willReturn(List.of(oldClockPlacement, bedPlacement));
		given(userFurnitureRepository.findById(20L)).willReturn(Optional.of(oldClockUserFurniture));
		given(userFurnitureRepository.findById(21L)).willReturn(Optional.of(bedUserFurniture));
		given(furnitureRepository.findByFurnitureIdAndIsDeletedFalse(10L)).willReturn(Optional.of(oldClock));
		given(furnitureRepository.findByFurnitureIdAndIsDeletedFalse(11L)).willReturn(Optional.of(bed));

		RoomResp resp = service.previewRoom(userId, 12L);

		assertThat(resp.items()).hasSize(2);
		assertThat(resp.items()).extracting("furnitureId").containsExactly(11L, 12L);
		assertThat(resp.items().get(0).preview()).isFalse();
		assertThat(resp.items().get(1).preview()).isTrue();
	}

	private Furniture furniture(Long furnitureId, String code, String name, String category, Integer price,
		boolean isOnSale) {
		return Furniture.builder()
			.furnitureId(furnitureId)
			.code(code)
			.name(name)
			.description(name + " 설명")
			.category(category)
			.price(price)
			.imageUrl("https://cdn.example.com/" + code + ".png")
			.thumbnailUrl("https://cdn.example.com/" + code + "_thumb.png")
			.defaultX(10)
			.defaultY(20)
			.width(80)
			.height(90)
			.zIndex(1)
			.isOnSale(isOnSale)
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
