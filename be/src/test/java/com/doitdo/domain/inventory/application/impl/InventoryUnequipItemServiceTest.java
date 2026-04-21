package com.doitdo.domain.inventory.application.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.BDDMockito.given;

import java.time.LocalDateTime;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.doitdo.domain.inventory.entity.UserItem;
import com.doitdo.domain.inventory.repository.ItemRepository;
import com.doitdo.domain.inventory.repository.UserItemRepository;
import com.doitdo.domain.tamagotchi.entity.UserCharacter;
import com.doitdo.domain.tamagotchi.repository.UserCharacterRepository;

@ExtendWith(MockitoExtension.class)
class InventoryUnequipItemServiceTest {

	@Mock
	private UserItemRepository userItemRepository;

	@Mock
	private ItemRepository itemRepository;

	@Mock
	private UserCharacterRepository userCharacterRepository;

	@Test
	void unequipItemClearsCurrentEquippedItem() {
		InventoryServiceImpl service = new InventoryServiceImpl(
			userItemRepository,
			itemRepository,
			userCharacterRepository
		);

		Long userId = 1L;
		Long tamagotchiId = 10L;
		Long userItemId = 42L;
		UserCharacter userCharacter = UserCharacter.builder()
			.userCharacterId(tamagotchiId)
			.userId(userId)
			.characterId(2L)
			.equipedItemsId(userItemId)
			.name("saesangi")
			.growthPercent(45)
			.isActive(true)
			.isDeleted(false)
			.build();
		UserItem userItem = UserItem.builder()
			.userItemId(userItemId)
			.userId(userId)
			.itemId(9L)
			.acquiredAt(LocalDateTime.parse("2026-04-15T10:00:00"))
			.build();

		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId))
			.willReturn(Optional.of(userCharacter));
		given(userItemRepository.findByUserIdAndUserItemId(userId, userItemId)).willReturn(Optional.of(userItem));

		service.unequipItem(userId, tamagotchiId, userItemId);

		assertThat(userCharacter.getEquipedItemsId()).isNull();
	}
}
