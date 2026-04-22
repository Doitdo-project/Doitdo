package com.doitdo.domain.inventory.api.dto.resp;

import java.util.List;

public record InventoryResp(

	Long tamagotchiId,
	Long equipedUserItemId,
	List<InventoryItemResp> items
) {
}
