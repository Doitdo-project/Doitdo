package com.doitdo.domain.shop.api.dto.req;

public record UpdateRoomFurniturePlacementReq(
	Integer x,
	Integer y,
	Integer zIndex,
	Integer rotation
) {
}
