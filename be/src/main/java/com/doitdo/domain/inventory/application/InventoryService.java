package com.doitdo.domain.inventory.application;

import com.doitdo.domain.inventory.api.dto.resp.InventoryResp;
import com.doitdo.domain.inventory.api.dto.resp.EquipItemResp;

public interface InventoryService {

	InventoryResp getInventory(Long userId, Long tamagotchiId);

	EquipItemResp equipItem(Long userId, Long tamagotchiId, Long userItemId);

	void unequipItem(Long userId, Long tamagotchiId, Long userItemId);
}
