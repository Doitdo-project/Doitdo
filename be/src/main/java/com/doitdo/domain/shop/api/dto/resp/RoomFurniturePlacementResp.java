package com.doitdo.domain.shop.api.dto.resp;

import com.doitdo.domain.shop.entity.Furniture;
import com.doitdo.domain.shop.entity.RoomFurniturePlacement;

public record RoomFurniturePlacementResp(
	Long placementId,
	Long userFurnitureId,
	Long furnitureId,
	String name,
	String category,
	String imageUrl,
	Integer width,
	Integer height,
	Integer zIndex,
	Integer rotation,
	boolean preview
) {

	public static RoomFurniturePlacementResp from(RoomFurniturePlacement placement, Furniture furniture) {
		return new RoomFurniturePlacementResp(
			placement.getPlacementId(),
			placement.getUserFurnitureId(),
			furniture.getFurnitureId(),
			furniture.getName(),
			furniture.getCategory(),
			furniture.getImageUrl(),
			furniture.getWidth(),
			furniture.getHeight(),
			placement.getZIndex(),
			placement.getRotation(),
			false
		);
	}

	public static RoomFurniturePlacementResp preview(Furniture furniture) {
		return new RoomFurniturePlacementResp(
			null,
			null,
			furniture.getFurnitureId(),
			furniture.getName(),
			furniture.getCategory(),
			furniture.getImageUrl(),
			furniture.getWidth(),
			furniture.getHeight(),
			furniture.getZIndex(),
			0,
			true
		);
	}
}
