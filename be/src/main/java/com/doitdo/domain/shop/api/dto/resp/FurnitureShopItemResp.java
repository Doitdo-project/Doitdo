package com.doitdo.domain.shop.api.dto.resp;

import com.doitdo.domain.shop.entity.Furniture;

public record FurnitureShopItemResp(
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
	boolean owned,
	boolean soldOut
) {

	public static FurnitureShopItemResp from(Furniture furniture, boolean owned) {
		boolean soldOut = owned || !Boolean.TRUE.equals(furniture.getIsOnSale());
		return new FurnitureShopItemResp(
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
			owned,
			soldOut
		);
	}
}
