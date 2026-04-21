package com.doitdo.domain.tamagotchi.application.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.BDDMockito.given;

import java.util.List;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.doitdo.domain.tamagotchi.api.dto.resp.EncyclopediaResp;
import com.doitdo.domain.tamagotchi.entity.Character;
import com.doitdo.domain.tamagotchi.entity.CharacterUnlock;
import com.doitdo.domain.tamagotchi.repository.CharacterRepository;
import com.doitdo.domain.tamagotchi.repository.CharacterUnlockRepository;
import com.doitdo.domain.tamagotchi.repository.UserCharacterRepository;

@ExtendWith(MockitoExtension.class)
class TamagotchiServiceImplTest {

	@Mock
	private CharacterRepository characterRepository;

	@Mock
	private CharacterUnlockRepository characterUnlockRepository;

	@Mock
	private UserCharacterRepository userCharacterRepository;

	@Test
	void getEncyclopediaReturnsAllCharactersWithUnlockedStatus() {
		TamagotchiServiceImpl service = new TamagotchiServiceImpl(
			characterRepository,
			characterUnlockRepository,
			userCharacterRepository
		);
		Long userId = 1L;

		Character slime = Character.builder()
			.characterId(1L)
			.species("SLIME")
			.stage(Character.Stage.BABY)
			.thumbnailUrl("https://cdn.example.com/slime.png")
			.build();
		Character rabbit = Character.builder()
			.characterId(2L)
			.species("RABBIT")
			.stage(Character.Stage.TEEN)
			.thumbnailUrl("https://cdn.example.com/rabbit.png")
			.build();
		CharacterUnlock unlock = CharacterUnlock.builder()
			.userId(userId)
			.characterId(1L)
			.build();

		given(characterRepository.findAll()).willReturn(List.of(slime, rabbit));
		given(characterUnlockRepository.findByUserId(userId)).willReturn(List.of(unlock));

		EncyclopediaResp resp = service.getEncyclopedia(userId);

		assertThat(resp.items()).hasSize(2);
		assertThat(resp.items().get(0).characterId()).isEqualTo(1L);
		assertThat(resp.items().get(0).species()).isEqualTo("SLIME");
		assertThat(resp.items().get(0).stage()).isEqualTo("BABY");
		assertThat(resp.items().get(0).thumbnailUrl()).isEqualTo("https://cdn.example.com/slime.png");
		assertThat(resp.items().get(0).unlocked()).isTrue();
		assertThat(resp.items().get(1).characterId()).isEqualTo(2L);
		assertThat(resp.items().get(1).unlocked()).isFalse();
	}
}
