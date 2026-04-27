package com.doitdo.domain.inventory.application.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.BDDMockito.given;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.doitdo.domain.inventory.api.dto.resp.InventoryResp;
import com.doitdo.domain.inventory.entity.Item;
import com.doitdo.domain.inventory.entity.UserItem;
import com.doitdo.domain.inventory.repository.ItemRepository;
import com.doitdo.domain.inventory.repository.UserItemRepository;
import com.doitdo.domain.tamagotchi.entity.UserCharacter;
import com.doitdo.domain.tamagotchi.repository.UserCharacterRepository;

@ExtendWith(MockitoExtension.class)
class InventoryServiceImplTest {

	@Mock
	private UserItemRepository userItemRepository;

	@Mock
	private ItemRepository itemRepository;

	@Mock
	private UserCharacterRepository userCharacterRepository;

	@Test
	void getInventoryReturnsItemsForCurrentTamagotchi() {
		InventoryServiceImpl service = new InventoryServiceImpl(
			userItemRepository,
			itemRepository,
			userCharacterRepository
		);

		Long userId = 1L;
		Long tamagotchiId = 10L;
		UserCharacter userCharacter = UserCharacter.builder()
			.userCharacterId(tamagotchiId)
			.userId(userId)
			.characterId(2L)
			.equipedItemsId(42L)
			.name("saesangi")
			.currentExp(45)
			.isActive(true)
			.isDeleted(false)
			.build();
		UserItem userItem = UserItem.builder()
			.userItemId(42L)
			.userId(userId)
			.itemId(9L)
			.acquiredAt(LocalDateTime.parse("2026-04-15T10:00:00"))
			.build();
		Item item = Item.builder()
			.itemId(9L)
			.code("HAT_001")
			.name("wizard hat")
			.price(100)
			.imgUrl("https://cdn.example.com/items/9.png")
			.thumbnailUrl("https://cdn.example.com/items/9_thumb.png")
			.isDeleted(false)
			.build();

		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId))
			.willReturn(Optional.of(userCharacter));
		given(userItemRepository.findAllByUserId(userId)).willReturn(List.of(userItem));
		given(itemRepository.findById(9L)).willReturn(Optional.of(item));

		InventoryResp resp = service.getInventory(userId, tamagotchiId);

		assertThat(resp.tamagotchiId()).isEqualTo(tamagotchiId);
		assertThat(resp.equipedUserItemId()).isEqualTo(42L);
		assertThat(resp.items()).hasSize(1);
		assertThat(resp.items().get(0).userItemId()).isEqualTo(42L);
		assertThat(resp.items().get(0).equipped()).isTrue();
	}
}
