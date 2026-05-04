package com.doitdo.domain.shop.api.dto.resp;

import com.doitdo.domain.shop.entity.Furniture;
import com.doitdo.domain.shop.entity.RoomFurniturePlacement;

public record RoomFurniturePlacementResp(
	Long placementId,
	Long userFurnitureId,
	Long furnitureId,
	String name,
	String imageUrl,
	Integer x,
	Integer y,
	Integer width,
	Integer height,
	Integer zIndex,
	Integer rotation
) {

	public static RoomFurniturePlacementResp from(RoomFurniturePlacement placement, Furniture furniture) {
		return new RoomFurniturePlacementResp(
			placement.getPlacementId(),
			placement.getUserFurnitureId(),
			furniture.getFurnitureId(),
			furniture.getName(),
			furniture.getImageUrl(),
			placement.getX(),
			placement.getY(),
			furniture.getWidth(),
			furniture.getHeight(),
			placement.getZIndex(),
			placement.getRotation()
		);
	}
}
