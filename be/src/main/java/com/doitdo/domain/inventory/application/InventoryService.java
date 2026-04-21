package com.doitdo.domain.inventory.application;

import com.doitdo.domain.inventory.api.dto.resp.InventoryResp;

public interface InventoryService {

	InventoryResp getInventory(Long userId, Long tamagotchiId);
}
