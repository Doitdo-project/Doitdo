package com.doitdo.domain.tamagotchi.application.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.BDDMockito.given;

import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.doitdo.domain.tamagotchi.api.dto.resp.CurrentCharacterResp;
import com.doitdo.domain.tamagotchi.entity.Character;
import com.doitdo.domain.tamagotchi.entity.UserCharacter;
import com.doitdo.domain.tamagotchi.repository.CharacterRepository;
import com.doitdo.domain.tamagotchi.repository.CharacterUnlockRepository;
import com.doitdo.domain.tamagotchi.repository.UserCharacterRepository;
import com.doitdo.domain.user.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class TamagotchiCurrentCharacterServiceImplTest {

	@Mock
	private UserCharacterRepository userCharacterRepository;

	@Mock
	private CharacterRepository characterRepository;

	@Mock
	private CharacterUnlockRepository characterUnlockRepository;

	@Mock
	private UserRepository userRepository;

	@Test
	void getCurrentCharacterReturnsActiveCharacterState() {
		TamagotchiServiceImpl service = new TamagotchiServiceImpl(
			characterRepository,
			characterUnlockRepository,
			userCharacterRepository,
			userRepository
		);

		Long userId = 1L;
		UserCharacter userCharacter = UserCharacter.builder()
			.userCharacterId(10L)
			.userId(userId)
			.characterId(2L)
			.name("saesangi")
			.currentExp(45)
			.equipedItemsId(42L)
			.isActive(true)
			.isDeleted(false)
			.build();
		Character character = Character.builder()
			.characterId(2L)
			.species("SLIME")
			.stage(Character.Stage.BABY)
			.requiredExp(100)
			.thumbnailUrl("https://cdn.example.com/slime.png")
			.build();

		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId))
			.willReturn(Optional.of(userCharacter));
		given(characterRepository.findById(2L)).willReturn(Optional.of(character));

		CurrentCharacterResp resp = service.getCurrentCharacter(userId);

		assertThat(resp.userCharacterId()).isEqualTo(10L);
		assertThat(resp.characterId()).isEqualTo(2L);
		assertThat(resp.name()).isEqualTo("saesangi");
		assertThat(resp.stage()).isEqualTo("BABY");
		assertThat(resp.thumbnailUrl()).isEqualTo("https://cdn.example.com/slime.png");
		assertThat(resp.growthPercent()).isEqualTo(45); // 45/100 * 100 = 45
		assertThat(resp.currentExp()).isEqualTo(45);
		assertThat(resp.requiredExp()).isEqualTo(100);
		assertThat(resp.canEvolve()).isFalse(); // 45 < 100
		assertThat(resp.canFarewell()).isFalse();
		assertThat(resp.equippedUserItemId()).isEqualTo(42L);
	}
}
