package com.doitdo.domain.shop.application;

import com.doitdo.domain.shop.entity.Furniture;
import com.doitdo.domain.shop.entity.RoomFurniturePlacement;
import com.doitdo.domain.shop.entity.UserFurniture;
import com.doitdo.domain.shop.repository.FurnitureRepository;
import com.doitdo.domain.shop.repository.RoomFurniturePlacementRepository;
import com.doitdo.domain.shop.repository.UserFurnitureRepository;
import com.doitdo.global.exception.CommonErrorCode;
import com.doitdo.global.exception.CustomException;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class DefaultFurnitureRegistrar {

	private static final List<String> DEFAULT_FURNITURE_CODES = List.of(
			"DEFAULT_WALL", "DEFAULT_FLOOR"
	);

	private final FurnitureRepository furnitureRepository;
	private final UserFurnitureRepository userFurnitureRepository;
	private final RoomFurniturePlacementRepository roomFurniturePlacementRepository;

	public void registerFor(Long userId) {
		for (String code : DEFAULT_FURNITURE_CODES) {
			Furniture furniture = furnitureRepository.findByCode(code)
					.orElseThrow(() -> new CustomException(CommonErrorCode.INTERNAL_SERVER_ERROR,
							"기본 가구가 초기화되지 않았습니다. code=" + code));
			UserFurniture userFurniture = userFurnitureRepository.save(
					UserFurniture.create(userId, furniture.getFurnitureId()));
			roomFurniturePlacementRepository.save(
					RoomFurniturePlacement.create(userId, userFurniture.getUserFurnitureId(), furniture));
		}
	}
}
