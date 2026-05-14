package com.doitdo.domain.shop.api.dto.resp;

import com.doitdo.domain.shop.entity.Furniture;
import com.doitdo.domain.shop.entity.UserFurniture;

public record PurchaseThemeFurnitureResp(
	Long userFurnitureId,
	Long furnitureId,
	String name,
	Integer price
) {

	public static PurchaseThemeFurnitureResp from(UserFurniture userFurniture, Furniture furniture) {
		return new PurchaseThemeFurnitureResp(
			userFurniture.getUserFurnitureId(),
			furniture.getFurnitureId(),
			furniture.getName(),
			furniture.getPrice()
		);
	}
}
