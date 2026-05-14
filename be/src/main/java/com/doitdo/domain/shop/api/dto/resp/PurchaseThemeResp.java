package com.doitdo.domain.shop.api.dto.resp;

import java.util.List;

public record PurchaseThemeResp(
	String themeCode,
	String themeName,
	int purchasedCount,
	int skippedOwnedCount,
	int totalPaid,
	Integer balance,
	List<PurchaseThemeFurnitureResp> purchasedFurnitures
) {
}
