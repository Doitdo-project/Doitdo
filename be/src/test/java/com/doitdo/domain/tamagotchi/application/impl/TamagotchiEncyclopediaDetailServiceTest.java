package com.doitdo.domain.tamagotchi.application.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.BDDMockito.given;

import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;

import com.doitdo.domain.tamagotchi.api.dto.resp.EncyclopediaDetailCharacterResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.EncyclopediaDetailResp;
import com.doitdo.domain.tamagotchi.entity.Character;
import com.doitdo.domain.tamagotchi.entity.CharacterSpeciesBackground;
import com.doitdo.domain.tamagotchi.repository.CharacterRepository;
import com.doitdo.domain.tamagotchi.repository.CharacterSpeciesBackgroundRepository;
import com.doitdo.domain.tamagotchi.repository.CharacterUnlockRepository;
import com.doitdo.domain.tamagotchi.repository.UserCharacterRepository;
import com.doitdo.domain.user.repository.UserRepository;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.TamagotchiErrorCode;

@ExtendWith(MockitoExtension.class)
class TamagotchiEncyclopediaDetailServiceTest {

	@Mock
	private CharacterRepository characterRepository;

	@Mock
	private CharacterUnlockRepository characterUnlockRepository;

	@Mock
	private UserCharacterRepository userCharacterRepository;

	@Mock
	private UserRepository userRepository;

	@Mock
	private CharacterSpeciesBackgroundRepository characterSpeciesBackgroundRepository;

	private TamagotchiServiceImpl service() {
		return new TamagotchiServiceImpl(
			characterRepository,
			characterUnlockRepository,
			userCharacterRepository,
			characterSpeciesBackgroundRepository,
			userRepository
		);
	}

	@Test
	void getEncyclopediaDetailReturnsStageCharactersBackgroundAndEncounterCount() {
		TamagotchiServiceImpl service = service();
		Long userId = 1L;
		String species = "SLIME";

		Character baby = Character.builder()
			.characterId(1L)
			.species(species)
			.name("슬라임 베이비")
			.stage(Character.Stage.BABY)
			.thumbnailUrl("https://cdn.example.com/slime-baby.png")
			.requiredExp(100)
			.build();
		Character teen = Character.builder()
			.characterId(2L)
			.species(species)
			.name("슬라임 틴")
			.stage(Character.Stage.TEEN)
			.thumbnailUrl("https://cdn.example.com/slime-teen.png")
			.requiredExp(200)
			.build();
		Character adult = Character.builder()
			.characterId(3L)
			.species(species)
			.name("슬라임 어덜트")
			.stage(Character.Stage.ADULT)
			.thumbnailUrl("https://cdn.example.com/slime-adult.png")
			.requiredExp(300)
			.build();
		CharacterSpeciesBackground background = CharacterSpeciesBackground.builder()
			.species(species)
			.birthBackground("진흙 속에서 태어난 전설의 생명체")
			.build();

		given(characterRepository.findBySpecies(species)).willReturn(List.of(baby, teen, adult));
		given(characterSpeciesBackgroundRepository.findById(species)).willReturn(Optional.of(background));
		given(userCharacterRepository.countByUserIdAndSpecies(userId, species)).willReturn(4L);

		EncyclopediaDetailResp resp = service.getEncyclopediaDetail(userId, species);

		assertThat(resp.species()).isEqualTo(species);
		assertThat(resp.birthBackground()).isEqualTo("진흙 속에서 태어난 전설의 생명체");
		assertThat(resp.encounterCount()).isEqualTo(4L);
		assertThat(resp.baby()).isEqualTo(new EncyclopediaDetailCharacterResp(1L, "슬라임 베이비", "https://cdn.example.com/slime-baby.png"));
		assertThat(resp.teen()).isEqualTo(new EncyclopediaDetailCharacterResp(2L, "슬라임 틴", "https://cdn.example.com/slime-teen.png"));
		assertThat(resp.adult()).isEqualTo(new EncyclopediaDetailCharacterResp(3L, "슬라임 어덜트", "https://cdn.example.com/slime-adult.png"));
	}

	@Test
	void getEncyclopediaDetailRejectsMissingSpecies() {
		TamagotchiServiceImpl service = service();
		String species = "SLIME";

		given(characterRepository.findBySpecies(species)).willReturn(List.of());

		assertThatThrownBy(() -> service.getEncyclopediaDetail(1L, species))
			.isInstanceOf(CustomException.class)
			.satisfies(throwable -> {
				CustomException exception = (CustomException)throwable;
				assertThat(exception.getErrorCode()).isEqualTo(TamagotchiErrorCode.M03_002);
				assertThat(exception.getErrorCode().getHttpStatus()).isEqualTo(HttpStatus.NOT_FOUND);
			});
	}
}
