package com.doitdo.domain.shop.application;

import com.doitdo.domain.shop.api.dto.req.UpdateRoomFurniturePlacementReq;
import com.doitdo.domain.shop.api.dto.resp.PlaceThemeResp;
import com.doitdo.domain.shop.api.dto.resp.RoomFurniturePlacementResp;
import com.doitdo.domain.shop.api.dto.resp.RoomResp;

public interface RoomFurniturePlacementService {

	RoomResp getMyRoom(Long userId);

	RoomFurniturePlacementResp placeFurniture(Long userId, Long userFurnitureId);

	PlaceThemeResp placeTheme(Long userId, String themeCode);

	RoomFurniturePlacementResp updatePlacement(Long userId, Long placementId, UpdateRoomFurniturePlacementReq req);

	void removePlacement(Long userId, Long placementId);
}
