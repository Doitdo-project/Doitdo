package com.doitdo.domain.shop.api.dto.resp;

import com.doitdo.domain.shop.entity.FurnitureTheme;

public record FurnitureThemeResp(
	String themeCode,
	String themeName,
	String thumbnailUrl,
	int furnitureCount
) {

	public static FurnitureThemeResp from(FurnitureTheme theme, long furnitureCount) {
		return new FurnitureThemeResp(
			theme.getThemeCode(),
			theme.getThemeName(),
			theme.getThumbnailUrl(),
			(int)furnitureCount
		);
	}
}
