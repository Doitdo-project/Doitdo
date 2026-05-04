package com.doitdo.domain.shop.application.impl;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.doitdo.domain.shop.api.dto.req.UpdateRoomFurniturePlacementReq;
import com.doitdo.domain.shop.api.dto.resp.RoomFurniturePlacementResp;
import com.doitdo.domain.shop.api.dto.resp.RoomResp;
import com.doitdo.domain.shop.application.RoomFurniturePlacementService;
import com.doitdo.domain.shop.entity.Furniture;
import com.doitdo.domain.shop.entity.RoomFurniturePlacement;
import com.doitdo.domain.shop.entity.UserFurniture;
import com.doitdo.domain.shop.repository.FurnitureRepository;
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

	@Override
	@Transactional(readOnly = true)
	public RoomResp getMyRoom(Long userId) {
		List<RoomFurniturePlacementResp> items = roomFurniturePlacementRepository
			.findAllByUserIdOrderByZIndexAscPlacementIdAsc(userId)
			.stream()
			.map(this::toResp)
			.toList();

		return new RoomResp(items);
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
