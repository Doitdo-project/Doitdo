package com.doitdo.domain.shop.api.dto.resp;

import java.time.LocalDateTime;

import com.doitdo.domain.shop.entity.Furniture;
import com.doitdo.domain.shop.entity.UserFurniture;

public record UserFurnitureItemResp(
	Long userFurnitureId,
	Long furnitureId,
	String code,
	String name,
	String description,
	String category,
	Integer price,
	String imageUrl,
	String thumbnailUrl,
	Integer defaultX,
	Integer defaultY,
	Integer width,
	Integer height,
	Integer zIndex,
	LocalDateTime acquiredAt
) {

	public static UserFurnitureItemResp from(UserFurniture userFurniture, Furniture furniture) {
		return new UserFurnitureItemResp(
			userFurniture.getUserFurnitureId(),
			furniture.getFurnitureId(),
			furniture.getCode(),
			furniture.getName(),
			furniture.getDescription(),
			furniture.getCategory(),
			furniture.getPrice(),
			furniture.getImageUrl(),
			furniture.getThumbnailUrl(),
			furniture.getDefaultX(),
			furniture.getDefaultY(),
			furniture.getWidth(),
			furniture.getHeight(),
			furniture.getZIndex(),
			userFurniture.getCreatedAt()
		);
	}
}
