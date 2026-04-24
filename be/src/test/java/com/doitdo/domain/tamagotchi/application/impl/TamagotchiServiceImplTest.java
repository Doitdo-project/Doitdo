package com.doitdo.domain.tamagotchi.application.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentCaptor.forClass;
import static org.mockito.Mockito.never;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.then;
import static org.mockito.ArgumentMatchers.any;

import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;

import com.doitdo.domain.tamagotchi.api.dto.resp.EncyclopediaResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.EvolutionResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.FarewellResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.HatchCharacterResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.CurrentCharacterResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.UpdateCharacterNameResp;
import com.doitdo.domain.tamagotchi.entity.Character;
import com.doitdo.domain.tamagotchi.entity.CharacterUnlock;
import com.doitdo.domain.tamagotchi.entity.UserCharacter;
import com.doitdo.domain.tamagotchi.repository.CharacterRepository;
import com.doitdo.domain.tamagotchi.repository.CharacterUnlockRepository;
import com.doitdo.domain.tamagotchi.repository.UserCharacterRepository;
import com.doitdo.domain.user.entity.User;
import com.doitdo.domain.user.repository.UserRepository;
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

	@Mock
	private UserRepository userRepository;

	private TamagotchiServiceImpl service() {
		return new TamagotchiServiceImpl(
			characterRepository,
			characterUnlockRepository,
			userCharacterRepository,
			userRepository
		);
	}

	@Test
	void receiveEggCreatesFirstEggWhenUserHasNoActiveCharacter() {
		TamagotchiServiceImpl service = service();
		Long userId = 1L;
		User user = User.builder()
			.userId(userId)
			.email("user@example.com")
			.username("user")
			.password("password")
			.streakCount(0)
			.isDeleted(false)
			.build();
		Character eggCharacter = Character.builder()
			.characterId(1L)
			.species("SLIME")
			.name("\uB69C\uC787")
			.stage(Character.Stage.EGG)
			.requiredExp(0)
			.thumbnailUrl("https://cdn.example.com/egg.png")
			.build();
		UserCharacter savedUserCharacter = UserCharacter.builder()
			.userCharacterId(10L)
			.userId(userId)
			.characterId(1L)
			.name("\uB69C\uC787")
			.currentExp(0)
			.isActive(true)
			.isDeleted(false)
			.build();

		given(userRepository.findByIdForUpdate(userId)).willReturn(Optional.of(user));
		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId))
			.willReturn(Optional.empty());
		given(characterRepository.findFirstByStageOrderByCharacterIdAsc(Character.Stage.EGG))
			.willReturn(Optional.of(eggCharacter));
		given(userCharacterRepository.save(any(UserCharacter.class))).willReturn(savedUserCharacter);

		CurrentCharacterResp resp = service.receiveEgg(userId);

		assertThat(resp.userCharacterId()).isEqualTo(10L);
		assertThat(resp.characterId()).isEqualTo(1L);
		assertThat(resp.stage()).isEqualTo("EGG");
		assertThat(resp.thumbnailUrl()).isEqualTo("https://cdn.example.com/egg.png");
		assertThat(resp.growthPercent()).isEqualTo(0);
		assertThat(resp.currentExp()).isEqualTo(0);
		assertThat(resp.requiredExp()).isEqualTo(0);
		assertThat(resp.canEvolve()).isFalse();
		assertThat(resp.canFarewell()).isFalse();
		assertThat(resp.name()).isEqualTo("\uB69C\uC787");
		assertThat(resp.equippedUserItemId()).isNull();
		ArgumentCaptor<UserCharacter> captor = forClass(UserCharacter.class);
		then(userCharacterRepository).should().save(captor.capture());
		assertThat(captor.getValue().getName()).isEqualTo("\uB69C\uC787");
	}
	@Test
	void receiveEggReturnsCurrentCharacterWithoutSavingWhenActiveCharacterExists() {
		TamagotchiServiceImpl service = service();
		Long userId = 1L;
		User user = User.builder()
			.userId(userId)
			.email("user@example.com")
			.username("user")
			.password("password")
			.streakCount(0)
			.isDeleted(false)
			.build();
		UserCharacter userCharacter = UserCharacter.builder()
			.userCharacterId(10L)
			.userId(userId)
			.characterId(2L)
			.name("rabi")
			.currentExp(20)
			.isActive(true)
			.isDeleted(false)
			.build();
		Character babyCharacter = Character.builder()
			.characterId(2L)
			.species("SLIME")
			.stage(Character.Stage.BABY)
			.requiredExp(100)
			.thumbnailUrl("https://cdn.example.com/slime.png")
			.build();

		given(userRepository.findByIdForUpdate(userId)).willReturn(Optional.of(user));
		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId))
			.willReturn(Optional.of(userCharacter));
		given(characterRepository.findById(2L)).willReturn(Optional.of(babyCharacter));

		CurrentCharacterResp resp = service.receiveEgg(userId);

		assertThat(resp.userCharacterId()).isEqualTo(10L);
		assertThat(resp.characterId()).isEqualTo(2L);
		assertThat(resp.stage()).isEqualTo("BABY");
		assertThat(resp.thumbnailUrl()).isEqualTo("https://cdn.example.com/slime.png");
		assertThat(resp.growthPercent()).isEqualTo(20);
		assertThat(resp.currentExp()).isEqualTo(20);
		assertThat(resp.requiredExp()).isEqualTo(100);
		assertThat(resp.canEvolve()).isFalse(); // 20 < 100
		assertThat(resp.canFarewell()).isFalse();
		then(userCharacterRepository).should(never()).save(any(UserCharacter.class));
	}

	@Test
	void updateNameChangesCurrentUserCharacterName() {
		TamagotchiServiceImpl service = service();
		Long userId = 1L;
		UserCharacter userCharacter = UserCharacter.builder()
			.userCharacterId(10L)
			.userId(userId)
			.characterId(1L)
			.name("old")
			.currentExp(0)
			.isActive(true)
			.isDeleted(false)
			.build();

		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId))
			.willReturn(Optional.of(userCharacter));

		UpdateCharacterNameResp resp = service.updateName(userId, "rabi");

		assertThat(resp.characterId()).isEqualTo(1L);
		assertThat(resp.name()).isEqualTo("rabi");
		assertThat(userCharacter.getName()).isEqualTo("rabi");
	}

	@Test
	void updateNameRejectsBlankName() {
		TamagotchiServiceImpl service = service();

		assertThatThrownBy(() -> service.updateName(1L, " "))
			.isInstanceOf(CustomException.class)
			.satisfies(throwable -> {
				CustomException exception = (CustomException)throwable;
				assertThat(exception.getErrorCode()).isEqualTo(TamagotchiErrorCode.M01_003);
				assertThat(exception.getErrorCode().getHttpStatus()).isEqualTo(HttpStatus.UNPROCESSABLE_ENTITY);
			});
	}

	@Test
	void getEncyclopediaReturnsOnlyAdultCharactersWithUnlockedStatusAndName() {
		TamagotchiServiceImpl service = service();
		Long userId = 1L;

		Character slime = Character.builder()
			.characterId(1L)
			.species("SLIME")
			.name("슬라임")
			.stage(Character.Stage.BABY)
			.requiredExp(100)
			.thumbnailUrl("https://cdn.example.com/slime.png")
			.build();
		Character rabbit = Character.builder()
			.characterId(2L)
			.species("RABBIT")
			.name("토끼")
			.stage(Character.Stage.TEEN)
			.requiredExp(200)
			.thumbnailUrl("https://cdn.example.com/rabbit.png")
			.build();
		Character dragon = Character.builder()
			.characterId(3L)
			.species("DRAGON")
			.name("드래곤")
			.stage(Character.Stage.ADULT)
			.requiredExp(300)
			.thumbnailUrl("https://cdn.example.com/dragon.png")
			.build();
		CharacterUnlock unlock = CharacterUnlock.builder()
			.userId(userId)
			.characterId(3L)
			.build();

		given(characterRepository.findAll()).willReturn(List.of(slime, rabbit, dragon));
		given(characterUnlockRepository.findByUserId(userId)).willReturn(List.of(unlock));

		EncyclopediaResp resp = service.getEncyclopedia(userId);

		assertThat(resp.items()).hasSize(1);
		assertThat(resp.items().get(0).characterId()).isEqualTo(3L);
		assertThat(resp.items().get(0).name()).isEqualTo("드래곤");
		assertThat(resp.items().get(0).species()).isEqualTo("DRAGON");
		assertThat(resp.items().get(0).stage()).isEqualTo("ADULT");
		assertThat(resp.items().get(0).thumbnailUrl()).isEqualTo("https://cdn.example.com/dragon.png");
		assertThat(resp.items().get(0).unlocked()).isTrue();
	}

	@Test
	void hatchUpdatesEggToBabyAndReturnsCurrentCharacter() {
		TamagotchiServiceImpl service = service();
		Long userId = 1L;
		UserCharacter eggUserCharacter = UserCharacter.builder()
			.userCharacterId(10L)
			.userId(userId)
			.characterId(1L)
			.name("rabi")
			.currentExp(0)
			.isActive(true)
			.isDeleted(false)
			.build();
		Character eggCharacter = Character.builder()
			.characterId(1L)
			.species("SLIME")
			.stage(Character.Stage.EGG)
			.requiredExp(0)
			.thumbnailUrl("https://cdn.example.com/egg.png")
			.build();
		Character babyCharacter = Character.builder()
			.characterId(2L)
			.species("SLIME")
			.stage(Character.Stage.BABY)
			.requiredExp(100)
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
		assertThat(resp.name()).isEqualTo("rabi");
		assertThat(resp.thumbnailUrl()).isEqualTo("https://cdn.example.com/slime.png");
	}

	@Test
	void hatchRejectsNonEggCharacter() {
		TamagotchiServiceImpl service = service();
		Long userId = 1L;
		UserCharacter userCharacter = UserCharacter.builder()
			.userCharacterId(10L)
			.userId(userId)
			.characterId(1L)
			.name("SLIME")
			.currentExp(0)
			.isActive(true)
			.isDeleted(false)
			.build();
		Character babyCharacter = Character.builder()
			.characterId(1L)
			.species("SLIME")
			.stage(Character.Stage.BABY)
			.requiredExp(100)
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
		TamagotchiServiceImpl service = service();
		Long userId = 1L;
		UserCharacter eggUserCharacter = UserCharacter.builder()
			.userCharacterId(10L)
			.userId(userId)
			.characterId(1L)
			.name(null)
			.currentExp(0)
			.isActive(true)
			.isDeleted(false)
			.build();
		Character eggCharacter = Character.builder()
			.characterId(1L)
			.species("SLIME")
			.stage(Character.Stage.EGG)
			.requiredExp(0)
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
		TamagotchiServiceImpl service = service();
		Long userId = 1L;
		// currentExp=100 ??곗쨮 BABY requiredExp=100 ??苑???筌욊쑵??揶쎛??
		UserCharacter userCharacter = UserCharacter.builder()
			.userCharacterId(20L)
			.userId(userId)
			.characterId(2L)
			.name("rabi")
			.currentExp(100)
			.isActive(true)
			.isDeleted(false)
			.build();
		Character babyCharacter = Character.builder()
			.characterId(2L)
			.species("SLIME")
			.stage(Character.Stage.BABY)
			.requiredExp(100)
			.thumbnailUrl("https://cdn.example.com/slime-baby.png")
			.build();
		// TEEN ??requiredExp=200
		Character teenCharacter = Character.builder()
			.characterId(3L)
			.species("SLIME")
			.stage(Character.Stage.TEEN)
			.requiredExp(200)
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
		assertThat(resp.currentExp()).isEqualTo(0); // 筌욊쑵??筌욊낱???귐딅?
		assertThat(resp.requiredExp()).isEqualTo(200); // TEEN requiredExp
		assertThat(resp.animationUrl()).isEqualTo("https://cdn.example.com/tamagotchi/animations/baby-to-teen");
		assertThat(resp.characterImageUrl()).isEqualTo("https://cdn.example.com/slime-teen.png");
		assertThat(resp.evolvedAt()).isNotBlank();
	}

	@Test
	void evolveFailsWhenExpInsufficient() {
		TamagotchiServiceImpl service = service();
		Long userId = 1L;
		// currentExp=50 < requiredExp=100 ??M05_006
		UserCharacter userCharacter = UserCharacter.builder()
			.userCharacterId(20L)
			.userId(userId)
			.characterId(2L)
			.name("rabi")
			.currentExp(50)
			.isActive(true)
			.isDeleted(false)
			.build();
		Character babyCharacter = Character.builder()
			.characterId(2L)
			.species("SLIME")
			.stage(Character.Stage.BABY)
			.requiredExp(100)
			.thumbnailUrl("https://cdn.example.com/slime-baby.png")
			.build();

		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId))
			.willReturn(Optional.of(userCharacter));
		given(characterRepository.findById(2L)).willReturn(Optional.of(babyCharacter));

		assertThatThrownBy(() -> service.evolve(userId, 20L))
			.isInstanceOf(CustomException.class)
			.satisfies(throwable -> {
				CustomException exception = (CustomException)throwable;
				assertThat(exception.getErrorCode()).isEqualTo(TamagotchiErrorCode.M05_006);
				assertThat(exception.getErrorCode().getHttpStatus()).isEqualTo(HttpStatus.CONFLICT);
			});
	}

	@Test
	void evolveFailsWhenRequiredExpIsNull() {
		TamagotchiServiceImpl service = service();
		Long userId = 1L;
		// requiredExp=null ??M05_005 (筌띾뜆?졿뉩紐껋쟿??곷?沃섎챷?욜뙴?
		UserCharacter userCharacter = UserCharacter.builder()
			.userCharacterId(20L)
			.userId(userId)
			.characterId(2L)
			.name("rabi")
			.currentExp(100)
			.isActive(true)
			.isDeleted(false)
			.build();
		Character babyCharacter = Character.builder()
			.characterId(2L)
			.species("SLIME")
			.stage(Character.Stage.BABY)
			.requiredExp(null)
			.thumbnailUrl("https://cdn.example.com/slime-baby.png")
			.build();

		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId))
			.willReturn(Optional.of(userCharacter));
		given(characterRepository.findById(2L)).willReturn(Optional.of(babyCharacter));

		assertThatThrownBy(() -> service.evolve(userId, 20L))
			.isInstanceOf(CustomException.class)
			.satisfies(throwable -> {
				CustomException exception = (CustomException)throwable;
				assertThat(exception.getErrorCode()).isEqualTo(TamagotchiErrorCode.M05_005);
			});
	}

	@Test
	void approveIndependenceUpdatesAdultToEggAndReturnsFarewellResp() {
		TamagotchiServiceImpl service = service();
		Long userId = 1L;
		UserCharacter adultUserCharacter = UserCharacter.builder()
			.userCharacterId(30L)
			.userId(userId)
			.characterId(4L)
			.name("rabi")
			.currentExp(0)
			.isActive(true)
			.isDeleted(false)
			.build();
		Character adultCharacter = Character.builder()
			.characterId(4L)
			.species("SLIME")
			.stage(Character.Stage.ADULT)
			.requiredExp(300)
			.thumbnailUrl("https://cdn.example.com/slime-adult.png")
			.build();
		Character eggCharacter = Character.builder()
			.characterId(1L)
			.species("DRAGON")
			.stage(Character.Stage.EGG)
			.requiredExp(0)
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
		TamagotchiServiceImpl service = service();
		Long userId = 1L;
		UserCharacter eggUserCharacter = UserCharacter.builder()
			.userCharacterId(30L)
			.userId(userId)
			.characterId(1L)
			.name("SLIME")
			.currentExp(0)
			.isActive(true)
			.isDeleted(false)
			.build();
		Character eggCharacter = Character.builder()
			.characterId(1L)
			.species("SLIME")
			.stage(Character.Stage.EGG)
			.requiredExp(0)
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
		TamagotchiServiceImpl service = service();
		Long userId = 1L;
		UserCharacter teenUserCharacter = UserCharacter.builder()
			.userCharacterId(30L)
			.userId(userId)
			.characterId(1L)
			.name("SLIME")
			.currentExp(0)
			.isActive(true)
			.isDeleted(false)
			.build();
		Character teenCharacter = Character.builder()
			.characterId(1L)
			.species("SLIME")
			.stage(Character.Stage.TEEN)
			.requiredExp(200)
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
