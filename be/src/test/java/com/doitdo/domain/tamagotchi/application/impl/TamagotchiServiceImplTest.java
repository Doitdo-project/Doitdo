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

import com.doitdo.domain.tamagotchi.api.dto.resp.EncyclopediaResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.EvolutionResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.FarewellResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.HatchCharacterResp;
import com.doitdo.domain.tamagotchi.entity.Character;
import com.doitdo.domain.tamagotchi.entity.CharacterUnlock;
import com.doitdo.domain.tamagotchi.entity.UserCharacter;
import com.doitdo.domain.tamagotchi.repository.CharacterRepository;
import com.doitdo.domain.tamagotchi.repository.CharacterUnlockRepository;
import com.doitdo.domain.tamagotchi.repository.UserCharacterRepository;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.TamagotchiErrorCode;

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

	@Test
	void hatchUpdatesEggToBabyAndReturnsCurrentCharacter() {
		TamagotchiServiceImpl service = new TamagotchiServiceImpl(
			characterRepository,
			characterUnlockRepository,
			userCharacterRepository
		);
		Long userId = 1L;
		UserCharacter eggUserCharacter = UserCharacter.builder()
			.userCharacterId(10L)
			.userId(userId)
			.characterId(1L)
			.name("꼬물이")
			.growthPercent(0)
			.isActive(true)
			.isDeleted(false)
			.build();
		Character eggCharacter = Character.builder()
			.characterId(1L)
			.species("SLIME")
			.stage(Character.Stage.EGG)
			.thumbnailUrl("https://cdn.example.com/egg.png")
			.build();
		Character babyCharacter = Character.builder()
			.characterId(2L)
			.species("SLIME")
			.stage(Character.Stage.BABY)
			.thumbnailUrl("https://cdn.example.com/slime.png")
			.build();

		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId))
			.willReturn(Optional.of(eggUserCharacter));
		given(characterRepository.findById(1L)).willReturn(Optional.of(eggCharacter));
		given(characterRepository.findFirstBySpeciesAndStageOrderByCharacterIdAsc("SLIME", Character.Stage.BABY))
			.willReturn(Optional.of(babyCharacter));

		HatchCharacterResp resp = service.hatch(userId);

		assertThat(resp.characterId()).isEqualTo(2L);
		assertThat(resp.stage()).isEqualTo("BABY");
		assertThat(resp.name()).isEqualTo("꼬물이");
	}

	@Test
	void hatchRejectsNonEggCharacter() {
		TamagotchiServiceImpl service = new TamagotchiServiceImpl(
			characterRepository,
			characterUnlockRepository,
			userCharacterRepository
		);
		Long userId = 1L;
		UserCharacter userCharacter = UserCharacter.builder()
			.userCharacterId(10L)
			.userId(userId)
			.characterId(1L)
			.name("SLIME")
			.growthPercent(0)
			.isActive(true)
			.isDeleted(false)
			.build();
		Character babyCharacter = Character.builder()
			.characterId(1L)
			.species("SLIME")
			.stage(Character.Stage.BABY)
			.thumbnailUrl("https://cdn.example.com/slime.png")
			.build();

		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId))
			.willReturn(Optional.of(userCharacter));
		given(characterRepository.findById(1L)).willReturn(Optional.of(babyCharacter));

		assertThatThrownBy(() -> service.hatch(userId))
			.isInstanceOf(CustomException.class)
			.satisfies(throwable -> {
				CustomException exception = (CustomException)throwable;
				assertThat(exception.getErrorCode()).isEqualTo(TamagotchiErrorCode.M02_003);
				assertThat(exception.getErrorCode().getHttpStatus()).isEqualTo(HttpStatus.UNPROCESSABLE_ENTITY);
			});
	}

	@Test
	void hatchFailsWhenBabyCharacterIsMissing() {
		TamagotchiServiceImpl service = new TamagotchiServiceImpl(
			characterRepository,
			characterUnlockRepository,
			userCharacterRepository
		);
		Long userId = 1L;
		UserCharacter eggUserCharacter = UserCharacter.builder()
			.userCharacterId(10L)
			.userId(userId)
			.characterId(1L)
			.name(null)
			.growthPercent(0)
			.isActive(true)
			.isDeleted(false)
			.build();
		Character eggCharacter = Character.builder()
			.characterId(1L)
			.species("SLIME")
			.stage(Character.Stage.EGG)
			.thumbnailUrl("https://cdn.example.com/egg.png")
			.build();

		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId))
			.willReturn(Optional.of(eggUserCharacter));
		given(characterRepository.findById(1L)).willReturn(Optional.of(eggCharacter));
		given(characterRepository.findFirstBySpeciesAndStageOrderByCharacterIdAsc("SLIME", Character.Stage.BABY))
			.willReturn(Optional.empty());

		assertThatThrownBy(() -> service.hatch(userId))
			.isInstanceOf(CustomException.class)
			.satisfies(throwable -> {
				CustomException exception = (CustomException)throwable;
				assertThat(exception.getErrorCode()).isEqualTo(TamagotchiErrorCode.M02_004);
				assertThat(exception.getErrorCode().getHttpStatus()).isEqualTo(HttpStatus.INTERNAL_SERVER_ERROR);
			});
	}

	@Test
	void evolveUpdatesBabyToTeenAndReturnsEvolutionResp() {
		TamagotchiServiceImpl service = new TamagotchiServiceImpl(
			characterRepository,
			characterUnlockRepository,
			userCharacterRepository
		);
		Long userId = 1L;
		UserCharacter userCharacter = UserCharacter.builder()
			.userCharacterId(20L)
			.userId(userId)
			.characterId(2L)
			.name("꼬물이")
			.growthPercent(120)
			.isActive(true)
			.isDeleted(false)
			.build();
		Character babyCharacter = Character.builder()
			.characterId(2L)
			.species("SLIME")
			.stage(Character.Stage.BABY)
			.thumbnailUrl("https://cdn.example.com/slime-baby.png")
			.build();
		Character teenCharacter = Character.builder()
			.characterId(3L)
			.species("SLIME")
			.stage(Character.Stage.TEEN)
			.thumbnailUrl("https://cdn.example.com/slime-teen.png")
			.build();

		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId))
			.willReturn(Optional.of(userCharacter));
		given(characterRepository.findById(2L)).willReturn(Optional.of(babyCharacter));
		given(characterRepository.findFirstBySpeciesAndStageOrderByCharacterIdAsc("SLIME", Character.Stage.TEEN))
			.willReturn(Optional.of(teenCharacter));

		EvolutionResp resp = service.evolve(userId, 20L);

		assertThat(resp.tamagotchiId()).isEqualTo(20L);
		assertThat(resp.beforeStage()).isEqualTo("BABY");
		assertThat(resp.afterStage()).isEqualTo("TEEN");
		assertThat(resp.currentExp()).isEqualTo(0);
		assertThat(resp.requiredExp()).isEqualTo(100);
		assertThat(resp.animationUrl()).isEqualTo("https://cdn.example.com/tamagotchi/animations/baby-to-teen");
		assertThat(resp.characterImageUrl()).isEqualTo("https://cdn.example.com/slime-teen.png");
		assertThat(resp.evolvedAt()).isNotBlank();
	}

	@Test
	void approveIndependenceUpdatesAdultToEggAndReturnsFarewellResp() {
		TamagotchiServiceImpl service = new TamagotchiServiceImpl(
			characterRepository,
			characterUnlockRepository,
			userCharacterRepository
		);
		Long userId = 1L;
		UserCharacter adultUserCharacter = UserCharacter.builder()
			.userCharacterId(30L)
			.userId(userId)
			.characterId(4L)
			.name("꼬물이")
			.growthPercent(0)
			.isActive(true)
			.isDeleted(false)
			.build();
		Character adultCharacter = Character.builder()
			.characterId(4L)
			.species("SLIME")
			.stage(Character.Stage.ADULT)
			.thumbnailUrl("https://cdn.example.com/slime-adult.png")
			.build();
		Character eggCharacter = Character.builder()
			.characterId(1L)
			.species("DRAGON")
			.stage(Character.Stage.EGG)
			.thumbnailUrl("https://cdn.example.com/slime-egg.png")
			.build();

		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId))
			.willReturn(Optional.of(adultUserCharacter));
		given(characterRepository.findById(4L)).willReturn(Optional.of(adultCharacter));
		given(characterRepository.findFirstByStageOrderByCharacterIdAsc(Character.Stage.EGG))
			.willReturn(Optional.of(eggCharacter));

		FarewellResp resp = service.approveIndependence(userId, true);

		assertThat(resp.farewellId()).isEqualTo(30L);
		assertThat(resp.nextCharacterAssigned()).isTrue();
		assertThat(resp.nextCharacterStage()).isEqualTo("EGG");
		assertThat(resp.animationUrl()).isNotBlank();
	}

	@Test
	void approveIndependenceRejectsAlreadyIndependentEggCharacter() {
		TamagotchiServiceImpl service = new TamagotchiServiceImpl(
			characterRepository,
			characterUnlockRepository,
			userCharacterRepository
		);
		Long userId = 1L;
		UserCharacter eggUserCharacter = UserCharacter.builder()
			.userCharacterId(30L)
			.userId(userId)
			.characterId(1L)
			.name("SLIME")
			.growthPercent(0)
			.isActive(true)
			.isDeleted(false)
			.build();
		Character eggCharacter = Character.builder()
			.characterId(1L)
			.species("SLIME")
			.stage(Character.Stage.EGG)
			.thumbnailUrl("https://cdn.example.com/slime-egg.png")
			.build();

		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId))
			.willReturn(Optional.of(eggUserCharacter));
		given(characterRepository.findById(1L)).willReturn(Optional.of(eggCharacter));

		assertThatThrownBy(() -> service.approveIndependence(userId, true))
			.isInstanceOf(CustomException.class)
			.satisfies(throwable -> {
				CustomException exception = (CustomException)throwable;
				assertThat(exception.getErrorCode()).isEqualTo(TamagotchiErrorCode.M00_003);
				assertThat(exception.getErrorCode().getHttpStatus()).isEqualTo(HttpStatus.CONFLICT);
			});
	}

	@Test
	void approveIndependenceRejectsNonAdultCharacter() {
		TamagotchiServiceImpl service = new TamagotchiServiceImpl(
			characterRepository,
			characterUnlockRepository,
			userCharacterRepository
		);
		Long userId = 1L;
		UserCharacter teenUserCharacter = UserCharacter.builder()
			.userCharacterId(30L)
			.userId(userId)
			.characterId(1L)
			.name("SLIME")
			.growthPercent(0)
			.isActive(true)
			.isDeleted(false)
			.build();
		Character teenCharacter = Character.builder()
			.characterId(1L)
			.species("SLIME")
			.stage(Character.Stage.TEEN)
			.thumbnailUrl("https://cdn.example.com/slime-teen.png")
			.build();

		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId))
			.willReturn(Optional.of(teenUserCharacter));
		given(characterRepository.findById(1L)).willReturn(Optional.of(teenCharacter));

		assertThatThrownBy(() -> service.approveIndependence(userId, true))
			.isInstanceOf(CustomException.class)
			.satisfies(throwable -> {
				CustomException exception = (CustomException)throwable;
				assertThat(exception.getErrorCode()).isEqualTo(TamagotchiErrorCode.M00_002);
				assertThat(exception.getErrorCode().getHttpStatus()).isEqualTo(HttpStatus.UNPROCESSABLE_ENTITY);
			});
	}
}
