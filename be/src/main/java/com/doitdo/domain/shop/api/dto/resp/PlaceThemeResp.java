package com.doitdo.domain.shop.api.dto.resp;

import java.util.List;

public record PlaceThemeResp(
	String themeCode,
	String themeName,
	int placedCount,
	List<RoomFurniturePlacementResp> items
) {
}
