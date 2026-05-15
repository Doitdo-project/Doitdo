package com.doitdo.domain.shop.api.dto.resp;

import java.util.List;
import java.util.Set;

import com.doitdo.domain.shop.entity.Furniture;
import com.doitdo.domain.shop.entity.FurnitureTheme;

public record FurnitureThemeResp(
	String themeCode,
	String themeName,
	String thumbnailUrl,
	int furnitureCount,
	int ownedCount,
	int totalPrice,
	int purchasePrice,
	boolean alreadyOwned,
	List<FurnitureThemeFurnitureResp> furnitures
) {

	public static FurnitureThemeResp from(FurnitureTheme theme, List<Furniture> furnitures, Set<Long> ownedFurnitureIds) {
		List<FurnitureThemeFurnitureResp> furnitureItems = furnitures.stream()
			.map(furniture -> FurnitureThemeFurnitureResp.from(
				furniture,
				ownedFurnitureIds.contains(furniture.getFurnitureId())
			))
			.toList();
		int totalPrice = furnitures.stream()
			.mapToInt(Furniture::getPrice)
			.sum();
		int purchasePrice = furnitures.stream()
			.filter(furniture -> !ownedFurnitureIds.contains(furniture.getFurnitureId()))
			.mapToInt(Furniture::getPrice)
			.sum();
		int ownedCount = (int)furnitures.stream()
			.filter(furniture -> ownedFurnitureIds.contains(furniture.getFurnitureId()))
			.count();

		return new FurnitureThemeResp(
			theme.getThemeCode(),
			theme.getThemeName(),
			theme.getThumbnailUrl(),
			furnitures.size(),
			ownedCount,
			totalPrice,
			purchasePrice,
			!furnitures.isEmpty() && ownedCount == furnitures.size(),
			furnitureItems
		);
	}
}
