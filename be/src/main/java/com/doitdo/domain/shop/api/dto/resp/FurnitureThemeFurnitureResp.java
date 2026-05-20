package com.doitdo.domain.shop.api.dto.resp;

import com.doitdo.domain.shop.entity.Furniture;

public record FurnitureThemeFurnitureResp(
	Long furnitureId,
	String name,
	Integer price,
	String thumbnailUrl,
	boolean owned
) {

	public static FurnitureThemeFurnitureResp from(Furniture furniture, boolean owned) {
		return new FurnitureThemeFurnitureResp(
			furniture.getFurnitureId(),
			furniture.getName(),
			furniture.getPrice(),
			furniture.getThumbnailUrl(),
			owned
		);
	}
}
