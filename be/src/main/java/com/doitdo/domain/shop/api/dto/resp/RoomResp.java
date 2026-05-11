package com.doitdo.domain.shop.api.dto.resp;

import java.util.List;

public record RoomResp(
	List<RoomFurniturePlacementResp> items
) {
}
