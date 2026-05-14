package com.doitdo.domain.shop.application;

import com.doitdo.domain.shop.api.dto.resp.FurnitureShopResp;
import com.doitdo.domain.shop.api.dto.resp.FurnitureThemeListResp;
import com.doitdo.domain.shop.api.dto.resp.PurchaseFurnitureResp;
import com.doitdo.domain.shop.api.dto.resp.RoomResp;
import com.doitdo.domain.shop.api.dto.resp.UserFurnitureResp;

public interface ShopService {

	FurnitureShopResp listFurnitures(Long userId, String category);

	FurnitureThemeListResp listThemes();

	PurchaseFurnitureResp purchaseFurniture(Long userId, Long furnitureId);

	UserFurnitureResp listMyFurnitures(Long userId);

	RoomResp previewRoom(Long userId, Long furnitureId);

	RoomResp previewThemeRoom(Long userId, String themeCode);
}
