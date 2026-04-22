package com.doitdo.domain.inventory.api.dto.resp;

public record EquipItemResp(

	Long tamagotchiId,
	Long equipedUserItemId,
	Long itemId,
	String itemName
) {
}
