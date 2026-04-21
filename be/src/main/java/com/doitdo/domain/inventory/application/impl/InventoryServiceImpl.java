package com.doitdo.domain.inventory.application.impl;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.doitdo.domain.inventory.api.dto.resp.EquipItemResp;
import com.doitdo.domain.inventory.api.dto.resp.InventoryItemResp;
import com.doitdo.domain.inventory.api.dto.resp.InventoryResp;
import com.doitdo.domain.inventory.application.InventoryService;
import com.doitdo.domain.inventory.entity.Item;
import com.doitdo.domain.inventory.entity.UserItem;
import com.doitdo.domain.inventory.repository.ItemRepository;
import com.doitdo.domain.inventory.repository.UserItemRepository;
import com.doitdo.domain.tamagotchi.entity.UserCharacter;
import com.doitdo.domain.tamagotchi.repository.UserCharacterRepository;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.TamagotchiErrorCode;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class InventoryServiceImpl implements InventoryService {

	private final UserItemRepository userItemRepository;
	private final ItemRepository itemRepository;
	private final UserCharacterRepository userCharacterRepository;

	@Override
	@Transactional(readOnly = true)
	public InventoryResp getInventory(Long userId, Long tamagotchiId) {
		UserCharacter userCharacter = userCharacterRepository
			.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId)
			.orElseThrow(() -> new CustomException(TamagotchiErrorCode.M08_002));

		if (!userCharacter.getUserCharacterId().equals(tamagotchiId)) {
			throw new CustomException(TamagotchiErrorCode.M08_002);
		}

		List<InventoryItemResp> items = userItemRepository.findAllByUserId(userId).stream()
			.map(userItem -> itemRepository.findById(userItem.getItemId())
				.map(item -> new InventoryItemResp(
					userItem.getUserItemId(),
					item.getItemId(),
					item.getCode(),
					item.getName(),
					item.getImgUrl(),
					item.getThumbnailUrl(),
					userItem.getAcquiredAt(),
					userItem.getUserItemId().equals(userCharacter.getEquipedItemsId())
				))
				.orElse(null))
			.filter(java.util.Objects::nonNull)
			.toList();

		return new InventoryResp(tamagotchiId, userCharacter.getEquipedItemsId(), items);
	}

	@Override
	@Transactional
	public EquipItemResp equipItem(Long userId, Long tamagotchiId, Long userItemId) {
		UserCharacter userCharacter = userCharacterRepository
			.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId)
			.orElseThrow(() -> new CustomException(TamagotchiErrorCode.M06_003));

		if (!userCharacter.getUserCharacterId().equals(tamagotchiId)) {
			throw new CustomException(TamagotchiErrorCode.M06_003);
		}

		UserItem userItem = userItemRepository.findByUserIdAndUserItemId(userId, userItemId)
			.orElseThrow(() -> new CustomException(TamagotchiErrorCode.M06_003));

		Item item = itemRepository.findById(userItem.getItemId())
			.orElseThrow(() -> new CustomException(TamagotchiErrorCode.M06_002));

		userCharacter.equipItem(userItemId);

		return new EquipItemResp(
			tamagotchiId,
			userItemId,
			item.getItemId(),
			item.getName()
		);
	}

	@Override
	@Transactional
	public void unequipItem(Long userId, Long tamagotchiId, Long userItemId) {
		UserCharacter userCharacter = userCharacterRepository
			.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId)
			.orElseThrow(() -> new CustomException(TamagotchiErrorCode.M07_003));

		if (!userCharacter.getUserCharacterId().equals(tamagotchiId)) {
			throw new CustomException(TamagotchiErrorCode.M07_003);
		}

		UserItem userItem = userItemRepository.findByUserIdAndUserItemId(userId, userItemId)
			.orElseThrow(() -> new CustomException(TamagotchiErrorCode.M07_002));

		if (userCharacter.getEquipedItemsId() == null
			|| !userCharacter.getEquipedItemsId().equals(userItem.getUserItemId())) {
			throw new CustomException(TamagotchiErrorCode.M07_003);
		}

		userCharacter.unequipItem();
	}
}
