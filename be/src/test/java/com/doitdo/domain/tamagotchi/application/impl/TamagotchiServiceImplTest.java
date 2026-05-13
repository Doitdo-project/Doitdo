package com.doitdo.domain.tamagotchi.application.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentCaptor.forClass;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.then;
import static org.mockito.ArgumentMatchers.any;

import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.http.HttpStatus;

import com.doitdo.domain.tamagotchi.api.dto.resp.EncyclopediaResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.EvolutionResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.FarewellResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.HatchCharacterResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.CharacterActionUrlResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.CurrentCharacterResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.UpdateCharacterNameResp;
import com.doitdo.domain.tamagotchi.entity.CharacterAction;
import com.doitdo.domain.tamagotchi.entity.Character;
import com.doitdo.domain.tamagotchi.entity.CharacterUnlock;
import com.doitdo.domain.tamagotchi.entity.UserCharacterHistory;
import com.doitdo.domain.tamagotchi.entity.UserCharacter;
import com.doitdo.domain.tamagotchi.repository.CharacterActionRepository;
import com.doitdo.domain.tamagotchi.repository.CharacterRepository;
import com.doitdo.domain.tamagotchi.repository.CharacterSpeciesBackgroundRepository;
import com.doitdo.domain.tamagotchi.repository.CharacterUnlockRepository;
import com.doitdo.domain.tamagotchi.repository.UserCharacterHistoryRepository;
import com.doitdo.domain.tamagotchi.repository.UserCharacterRepository;
import com.doitdo.domain.user.application.CreditEarnService;
import com.doitdo.domain.user.entity.UserWallet;
import com.doitdo.domain.user.entity.WalletEarnSource;
import com.doitdo.domain.user.entity.User;
import com.doitdo.domain.user.repository.UserRepository;
import com.doitdo.domain.user.repository.UserWalletRepository;
import com.doitdo.global.cache.CacheEvictHelper;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.TamagotchiErrorCode;

@ExtendWith(MockitoExtension.class)
class TamagotchiServiceImplTest {

	@Mock
	private CharacterActionRepository characterActionRepository;

	@Mock
	private CharacterRepository characterRepository;

	@Mock
	private CharacterUnlockRepository characterUnlockRepository;

	@Mock
	private UserCharacterRepository userCharacterRepository;

	@Mock
	private UserCharacterHistoryRepository userCharacterHistoryRepository;

	@Mock
	private UserRepository userRepository;

	@Mock
	private CharacterSpeciesBackgroundRepository characterSpeciesBackgroundRepository;

	@Mock
	private ApplicationEventPublisher eventPublisher;

	@Mock
	private CacheEvictHelper cacheEvictHelper;

	@Mock
	private CreditEarnService creditEarnService;

	@Mock
	private UserWalletRepository userWalletRepository;

	private TamagotchiServiceImpl service() {
		return new TamagotchiServiceImpl(
			characterActionRepository,
			characterRepository,
			characterUnlockRepository,
			userCharacterRepository,
			userCharacterHistoryRepository,
			characterSpeciesBackgroundRepository,
			userRepository,
			eventPublisher,
			cacheEvictHelper,
			creditEarnService,
			userWalletRepository
		);
	}

	@Test
	void receiveEggCreatesRandomEggWhenUserHasNoActiveCharacter() {
		TamagotchiServiceImpl service = service();
		Long userId = 1L;
		User user = User.builder()
			.userId(userId)
			.email("user@example.com")
			.username("user")
			.password("password")
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
		given(characterRepository.findAllByStage(Character.Stage.EGG)).willReturn(List.of(eggCharacter));
		given(userCharacterRepository.save(any(UserCharacter.class))).willReturn(savedUserCharacter);
		given(userCharacterHistoryRepository.save(any(UserCharacterHistory.class)))
			.willAnswer(invocation -> invocation.getArgument(0));

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
		assertThat(captor.getValue().getCharacterId()).isEqualTo(1L);
		assertThat(captor.getValue().getName()).isEqualTo("\uB69C\uC787");
		then(userCharacterHistoryRepository).should().save(any(UserCharacterHistory.class));
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
			.requiredExp(75)
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
		assertThat(resp.growthPercent()).isEqualTo(27);
		assertThat(resp.currentExp()).isEqualTo(20);
		assertThat(resp.requiredExp()).isEqualTo(75);
		assertThat(resp.canEvolve()).isFalse(); // 20 < 75
		assertThat(resp.canFarewell()).isFalse();
		then(userCharacterRepository).should(never()).save(any(UserCharacter.class));
	}

	@Test
	void getCurrentCharacterReturnsCanFarewellFalseWhenFarewellAvailableAtIsFuture() {
		TamagotchiServiceImpl service = service();
		Long userId = 1L;
		UserCharacter userCharacter = UserCharacter.builder()
			.userCharacterId(10L)
			.userId(userId)
			.characterId(4L)
			.name("rabi")
			.currentExp(125)
			.isActive(true)
			.isDeleted(false)
			.farewellAvailableAt(LocalDateTime.now().plusMinutes(10))
			.build();
		Character adultCharacter = Character.builder()
			.characterId(4L)
			.species("SLIME")
			.stage(Character.Stage.ADULT)
			.requiredExp(125)
			.thumbnailUrl("https://cdn.example.com/slime-adult.png")
			.build();

		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId))
			.willReturn(Optional.of(userCharacter));
		given(characterRepository.findById(4L)).willReturn(Optional.of(adultCharacter));

		CurrentCharacterResp resp = service.getCurrentCharacter(userId);

		assertThat(resp.canFarewell()).isFalse();
	}

	@Test
	void getCurrentCharacterReturnsCanFarewellTrueWhenFarewellAvailableAtIsPast() {
		TamagotchiServiceImpl service = service();
		Long userId = 1L;
		UserCharacter userCharacter = UserCharacter.builder()
			.userCharacterId(10L)
			.userId(userId)
			.characterId(4L)
			.name("rabi")
			.currentExp(125)
			.isActive(true)
			.isDeleted(false)
			.farewellAvailableAt(LocalDateTime.now().minusMinutes(1))
			.build();
		Character adultCharacter = Character.builder()
			.characterId(4L)
			.species("SLIME")
			.stage(Character.Stage.ADULT)
			.requiredExp(125)
			.thumbnailUrl("https://cdn.example.com/slime-adult.png")
			.build();

		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId))
			.willReturn(Optional.of(userCharacter));
		given(characterRepository.findById(4L)).willReturn(Optional.of(adultCharacter));

		CurrentCharacterResp resp = service.getCurrentCharacter(userId);

		assertThat(resp.canFarewell()).isTrue();
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
		given(userCharacterHistoryRepository.save(any(UserCharacterHistory.class)))
			.willAnswer(invocation -> invocation.getArgument(0));

		UpdateCharacterNameResp resp = service.updateName(userId, "rabi");

		assertThat(resp.characterId()).isEqualTo(1L);
		assertThat(resp.name()).isEqualTo("rabi");
		assertThat(userCharacter.getName()).isEqualTo("rabi");
		then(userCharacterHistoryRepository).should().save(any(UserCharacterHistory.class));
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
	void getMyCharacterActionUrlReturnsOneUrlWhenMultipleActionsExist() {
		TamagotchiServiceImpl service = service();
		Long userId = 1L;
		UserCharacter userCharacter = UserCharacter.builder()
			.userCharacterId(10L)
			.userId(userId)
			.characterId(9L)
			.name("rabi")
			.currentExp(0)
			.isActive(true)
			.isDeleted(false)
			.build();
		CharacterAction first = CharacterAction.builder()
			.actionId(11L)
			.characterId(9L)
			.actionType("EYE")
			.actionUrl("https://cdn.example.com/eye_2.gif")
			.build();
		CharacterAction second = CharacterAction.builder()
			.actionId(12L)
			.characterId(9L)
			.actionType("EYE")
			.actionUrl("https://cdn.example.com/eye.gif")
			.build();

		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId))
			.willReturn(Optional.of(userCharacter));
		given(characterActionRepository.findAllByCharacterIdAndActionType(9L, "EYE"))
			.willReturn(List.of(first, second));
		given(userWalletRepository.findByUserId(userId)).willReturn(Optional.of(wallet(userId, 100)));

		CharacterActionUrlResp resp = service.getMyCharacterActionUrl(userId, "EYE");

		assertThat(resp.actionUrl()).isIn("https://cdn.example.com/eye_2.gif", "https://cdn.example.com/eye.gif");
		assertThat(resp.earnedAmount()).isZero();
	}

	@Test
	void getMyCharacterActionUrlIdleEarnsTwoTimesAndSkipsThirdWithActionUrl() {
		TamagotchiServiceImpl service = service();
		Long userId = 1L;
		UserCharacter userCharacter = activeUserCharacter(userId);
		CharacterAction action = idleAction();
		LocalDate today = LocalDate.of(2026, 5, 7);
		LocalDateTime baseTime = today.atTime(9, 0);

		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId))
			.willReturn(Optional.of(userCharacter));
		given(userCharacterRepository.findActiveByUserIdForUpdate(userId))
			.willReturn(Optional.of(userCharacter));
		given(characterActionRepository.findAllByCharacterIdAndActionType(9L, "IDLE"))
			.willReturn(List.of(action));
		given(creditEarnService.tryEarn(userId, WalletEarnSource.PET_TOUCH, 50, 9L, false))
			.willReturn(50);
		given(userWalletRepository.findByUserId(userId)).willReturn(Optional.of(wallet(userId, 130)));

		int earnedSum = 0;
		for (int i = 0; i < 2; i++) {
			service.setClock(fixedClock(baseTime.plusHours(i * 2L)));
			earnedSum += service.getMyCharacterActionUrl(userId, "IDLE").earnedAmount();
		}
		service.setClock(fixedClock(baseTime.plusHours(4)));
		CharacterActionUrlResp third = service.getMyCharacterActionUrl(userId, "IDLE");

		assertThat(earnedSum).isEqualTo(100);
		assertThat(third.actionUrl()).isEqualTo("https://cdn.example.com/idle.gif");
		assertThat(third.earnedAmount()).isZero();
		assertThat(third.dailyTouchCount()).isEqualTo(2);
		assertThat(third.nextAvailableAt()).isEqualTo(today.plusDays(1).atStartOfDay());
		then(creditEarnService).should(times(2))
			.tryEarn(userId, WalletEarnSource.PET_TOUCH, 50, 9L, false);
	}

	@Test
	void getMyCharacterActionUrlIdleSkipsEarnDuringTwoHourCooldown() {
		TamagotchiServiceImpl service = service();
		Long userId = 1L;
		UserCharacter userCharacter = activeUserCharacter(userId);
		LocalDateTime baseTime = LocalDateTime.of(2026, 5, 7, 9, 0);

		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId))
			.willReturn(Optional.of(userCharacter));
		given(userCharacterRepository.findActiveByUserIdForUpdate(userId))
			.willReturn(Optional.of(userCharacter));
		given(characterActionRepository.findAllByCharacterIdAndActionType(9L, "IDLE"))
			.willReturn(List.of(idleAction()));
		given(creditEarnService.tryEarn(userId, WalletEarnSource.PET_TOUCH, 50, 9L, false))
			.willReturn(50);
		given(userWalletRepository.findByUserId(userId)).willReturn(Optional.of(wallet(userId, 110)));

		service.setClock(fixedClock(baseTime));
		CharacterActionUrlResp first = service.getMyCharacterActionUrl(userId, "IDLE");
		service.setClock(fixedClock(baseTime.plusMinutes(10)));
		CharacterActionUrlResp second = service.getMyCharacterActionUrl(userId, "IDLE");

		assertThat(first.earnedAmount()).isEqualTo(50);
		assertThat(second.actionUrl()).isEqualTo("https://cdn.example.com/idle.gif");
		assertThat(second.earnedAmount()).isZero();
		assertThat(second.dailyTouchCount()).isEqualTo(1);
		assertThat(second.nextAvailableAt()).isEqualTo(baseTime.plusHours(2));
		then(creditEarnService).should(times(1))
			.tryEarn(userId, WalletEarnSource.PET_TOUCH, 50, 9L, false);
	}

	@Test
	void getMyCharacterActionUrlEyeSkipsEarnEvaluationAndReturnsActionUrl() {
		TamagotchiServiceImpl service = service();
		Long userId = 1L;
		UserCharacter userCharacter = activeUserCharacter(userId);
		CharacterAction action = CharacterAction.builder()
			.actionId(11L)
			.characterId(9L)
			.actionType("EYE")
			.actionUrl("https://cdn.example.com/eye.gif")
			.build();

		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId))
			.willReturn(Optional.of(userCharacter));
		given(characterActionRepository.findAllByCharacterIdAndActionType(9L, "EYE"))
			.willReturn(List.of(action));
		given(userWalletRepository.findByUserId(userId)).willReturn(Optional.of(wallet(userId, 100)));

		CharacterActionUrlResp resp = service.getMyCharacterActionUrl(userId, "EYE");

		assertThat(resp.actionUrl()).isEqualTo("https://cdn.example.com/eye.gif");
		assertThat(resp.earnedAmount()).isZero();
		assertThat(resp.dailyTouchCount()).isZero();
		then(userCharacterRepository).should(never()).findActiveByUserIdForUpdate(anyLong());
		then(creditEarnService).should(never()).tryEarn(anyLong(), any(), anyInt(), any(), anyBoolean());
	}

	@Test
	void getMyCharacterActionUrlIdleResetsDailyTouchDateAfterDayChangesAndEarnsAgain() {
		TamagotchiServiceImpl service = service();
		Long userId = 1L;
		LocalDate today = LocalDate.of(2026, 5, 7);
		LocalDateTime now = today.atTime(9, 0);
		UserCharacter userCharacter = UserCharacter.builder()
			.userCharacterId(10L)
			.userId(userId)
			.characterId(9L)
			.name("rabi")
			.currentExp(0)
			.isActive(true)
			.isDeleted(false)
			.lastTouchedAt(now.minusDays(1))
			.dailyTouchDate(today.minusDays(1))
			.dailyTouchCount(2)
			.build();

		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId))
			.willReturn(Optional.of(userCharacter));
		given(userCharacterRepository.findActiveByUserIdForUpdate(userId))
			.willReturn(Optional.of(userCharacter));
		given(characterActionRepository.findAllByCharacterIdAndActionType(9L, "IDLE"))
			.willReturn(List.of(idleAction()));
		given(creditEarnService.tryEarn(userId, WalletEarnSource.PET_TOUCH, 50, 9L, false))
			.willReturn(50);
		given(userWalletRepository.findByUserId(userId)).willReturn(Optional.of(wallet(userId, 140)));

		service.setClock(fixedClock(now));
		CharacterActionUrlResp resp = service.getMyCharacterActionUrl(userId, "IDLE");

		assertThat(resp.earnedAmount()).isEqualTo(50);
		assertThat(resp.dailyTouchCount()).isEqualTo(1);
		assertThat(resp.nextAvailableAt()).isEqualTo(now.plusHours(2));
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
			.requiredExp(75)
			.thumbnailUrl("https://cdn.example.com/slime.png")
			.build();
		Character rabbit = Character.builder()
			.characterId(2L)
			.species("RABBIT")
			.name("토끼")
			.stage(Character.Stage.TEEN)
			.requiredExp(100)
			.thumbnailUrl("https://cdn.example.com/rabbit.png")
			.build();
		Character dragon = Character.builder()
			.characterId(3L)
			.species("DRAGON")
			.name("드래곤")
			.stage(Character.Stage.ADULT)
			.requiredExp(125)
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
			.requiredExp(75)
			.thumbnailUrl("https://cdn.example.com/slime.png")
			.build();

		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId))
			.willReturn(Optional.of(eggUserCharacter));
		given(characterRepository.findById(1L)).willReturn(Optional.of(eggCharacter));
		given(characterRepository.findFirstBySpeciesAndStageOrderByCharacterIdAsc("SLIME", Character.Stage.BABY))
			.willReturn(Optional.of(babyCharacter));
		given(userCharacterHistoryRepository.save(any(UserCharacterHistory.class)))
			.willAnswer(invocation -> invocation.getArgument(0));

		HatchCharacterResp resp = service.hatch(userId);

		assertThat(resp.characterId()).isEqualTo(2L);
		assertThat(resp.stage()).isEqualTo("BABY");
		assertThat(resp.name()).isEqualTo("rabi");
		assertThat(resp.thumbnailUrl()).isEqualTo("https://cdn.example.com/slime.png");
		then(userCharacterHistoryRepository).should().save(any(UserCharacterHistory.class));
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
			.requiredExp(75)
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
		// BABY requiredExp=75 를 충족하면 TEEN 으로 진화한다.
		UserCharacter userCharacter = UserCharacter.builder()
			.userCharacterId(20L)
			.userId(userId)
			.characterId(2L)
			.name("rabi")
			.currentExp(75)
			.isActive(true)
			.isDeleted(false)
			.build();
		Character babyCharacter = Character.builder()
			.characterId(2L)
			.species("SLIME")
			.stage(Character.Stage.BABY)
			.requiredExp(75)
			.thumbnailUrl("https://cdn.example.com/slime-baby.png")
			.build();
		// TEEN requiredExp=100
		Character teenCharacter = Character.builder()
			.characterId(3L)
			.species("SLIME")
			.stage(Character.Stage.TEEN)
			.requiredExp(100)
			.thumbnailUrl("https://cdn.example.com/slime-teen.png")
			.build();

		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId))
			.willReturn(Optional.of(userCharacter));
		given(characterRepository.findById(2L)).willReturn(Optional.of(babyCharacter));
		given(characterRepository.findFirstBySpeciesAndStageOrderByCharacterIdAsc("SLIME", Character.Stage.TEEN))
			.willReturn(Optional.of(teenCharacter));
		given(userCharacterHistoryRepository.save(any(UserCharacterHistory.class)))
			.willAnswer(invocation -> invocation.getArgument(0));

		EvolutionResp resp = service.evolve(userId, 20L);

		assertThat(resp.tamagotchiId()).isEqualTo(20L);
		assertThat(resp.beforeStage()).isEqualTo("BABY");
		assertThat(resp.afterStage()).isEqualTo("TEEN");
		assertThat(resp.currentExp()).isEqualTo(0);
		assertThat(resp.requiredExp()).isEqualTo(100); // TEEN requiredExp
		assertThat(resp.animationUrl()).isEqualTo(
			"https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/evolution/evolution.gif");
		assertThat(resp.characterImageUrl()).isEqualTo("https://cdn.example.com/slime-teen.png");
		assertThat(resp.evolvedAt()).isNotBlank();
		then(characterUnlockRepository).should(never()).saveAll(any());
		then(userCharacterHistoryRepository).should().save(any(UserCharacterHistory.class));
	}

	@Test
	void evolveToAdultUnlocksAllCharactersInSpecies() {
		TamagotchiServiceImpl service = service();
		Long userId = 1L;
		UserCharacter userCharacter = UserCharacter.builder()
			.userCharacterId(20L)
			.userId(userId)
			.characterId(3L)
			.name("rabi")
			.currentExp(100)
			.isActive(true)
			.isDeleted(false)
			.build();
		Character teenCharacter = Character.builder()
			.characterId(3L)
			.species("SLIME")
			.stage(Character.Stage.TEEN)
			.requiredExp(100)
			.thumbnailUrl("https://cdn.example.com/slime-teen.png")
			.build();
		Character adultCharacter = Character.builder()
			.characterId(4L)
			.species("SLIME")
			.stage(Character.Stage.ADULT)
			.requiredExp(125)
			.thumbnailUrl("https://cdn.example.com/slime-adult.png")
			.build();
		Character babyCharacter = Character.builder()
			.characterId(2L)
			.species("SLIME")
			.stage(Character.Stage.BABY)
			.requiredExp(75)
			.thumbnailUrl("https://cdn.example.com/slime-baby.png")
			.build();

		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId))
			.willReturn(Optional.of(userCharacter));
		given(characterRepository.findById(3L)).willReturn(Optional.of(teenCharacter));
		given(characterRepository.findFirstBySpeciesAndStageOrderByCharacterIdAsc("SLIME", Character.Stage.ADULT))
			.willReturn(Optional.of(adultCharacter));
		given(characterRepository.findBySpecies("SLIME")).willReturn(List.of(babyCharacter, teenCharacter, adultCharacter));
		given(characterUnlockRepository.findByUserId(userId)).willReturn(List.of());
		given(userCharacterHistoryRepository.save(any(UserCharacterHistory.class)))
			.willAnswer(invocation -> invocation.getArgument(0));

		EvolutionResp resp = service.evolve(userId, 20L);

		assertThat(resp.beforeStage()).isEqualTo("TEEN");
		assertThat(resp.afterStage()).isEqualTo("ADULT");

		@SuppressWarnings("unchecked")
		ArgumentCaptor<Iterable<CharacterUnlock>> captor = (ArgumentCaptor<Iterable<CharacterUnlock>>) (ArgumentCaptor<?>)
			forClass(Iterable.class);
		then(characterUnlockRepository).should().saveAll(captor.capture());
		then(userCharacterHistoryRepository).should().save(any(UserCharacterHistory.class));

		ArrayList<Long> unlockedCharacterIds = new ArrayList<>();
		for (CharacterUnlock unlock : captor.getValue()) {
			unlockedCharacterIds.add(unlock.getCharacterId());
			assertThat(unlock.getUserId()).isEqualTo(userId);
		}
		assertThat(unlockedCharacterIds).containsExactly(2L, 3L, 4L);
	}

	@Test
	void evolveFailsWhenExpInsufficient() {
		TamagotchiServiceImpl service = service();
		Long userId = 1L;
		// currentExp=74 < requiredExp=75 이면 M05_006
		UserCharacter userCharacter = UserCharacter.builder()
			.userCharacterId(20L)
			.userId(userId)
			.characterId(2L)
			.name("rabi")
			.currentExp(74)
			.isActive(true)
			.isDeleted(false)
			.build();
		Character babyCharacter = Character.builder()
			.characterId(2L)
			.species("SLIME")
			.stage(Character.Stage.BABY)
			.requiredExp(75)
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
			.currentExp(75)
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
			.currentExp(125)
			.isActive(true)
			.isDeleted(false)
			.farewellAvailableAt(LocalDateTime.now().minusMinutes(1))
			.build();
		Character adultCharacter = Character.builder()
			.characterId(4L)
			.species("SLIME")
			.stage(Character.Stage.ADULT)
			.requiredExp(125)
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
		given(characterRepository.findAllByStage(Character.Stage.EGG)).willReturn(List.of(eggCharacter));
		given(userCharacterRepository.save(any(UserCharacter.class)))
			.willAnswer(invocation -> invocation.getArgument(0));
		given(userCharacterHistoryRepository.save(any(UserCharacterHistory.class)))
			.willAnswer(invocation -> invocation.getArgument(0));

		FarewellResp resp = service.approveIndependence(userId, true);

		assertThat(resp.farewellId()).isEqualTo(30L);
		assertThat(resp.nextCharacterAssigned()).isTrue();
		assertThat(resp.nextCharacterStage()).isEqualTo("EGG");
		assertThat(resp.animationUrl()).isNotBlank();
		ArgumentCaptor<UserCharacter> captor = forClass(UserCharacter.class);
		then(userCharacterRepository).should(times(2)).save(captor.capture());
		UserCharacter savedNextEgg = captor.getAllValues().get(1);
		assertThat(savedNextEgg.getFarewellNotified()).isFalse();
		then(userCharacterHistoryRepository).should().save(any(UserCharacterHistory.class));
	}

	@Test
	void approveIndependenceRejectsWhenFarewellAvailableAtIsNull() {
		TamagotchiServiceImpl service = service();
		Long userId = 1L;
		UserCharacter adultUserCharacter = UserCharacter.builder()
			.userCharacterId(30L)
			.userId(userId)
			.characterId(4L)
			.name("rabi")
			.currentExp(125)
			.isActive(true)
			.isDeleted(false)
			.build();
		Character adultCharacter = Character.builder()
			.characterId(4L)
			.species("SLIME")
			.stage(Character.Stage.ADULT)
			.requiredExp(125)
			.thumbnailUrl("https://cdn.example.com/slime-adult.png")
			.build();

		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId))
			.willReturn(Optional.of(adultUserCharacter));
		given(characterRepository.findById(4L)).willReturn(Optional.of(adultCharacter));

		assertThatThrownBy(() -> service.approveIndependence(userId, true))
			.isInstanceOf(CustomException.class)
			.satisfies(throwable -> {
				CustomException exception = (CustomException)throwable;
				assertThat(exception.getErrorCode()).isEqualTo(TamagotchiErrorCode.M00_003);
				assertThat(exception.getErrorCode().getHttpStatus()).isEqualTo(HttpStatus.CONFLICT);
			});
	}

	@Test
	void approveIndependenceRejectsWhenFarewellAvailableAtIsFuture() {
		TamagotchiServiceImpl service = service();
		Long userId = 1L;
		UserCharacter adultUserCharacter = UserCharacter.builder()
			.userCharacterId(30L)
			.userId(userId)
			.characterId(4L)
			.name("rabi")
			.currentExp(125)
			.isActive(true)
			.isDeleted(false)
			.farewellAvailableAt(LocalDateTime.now().plusMinutes(10))
			.build();
		Character adultCharacter = Character.builder()
			.characterId(4L)
			.species("SLIME")
			.stage(Character.Stage.ADULT)
			.requiredExp(125)
			.thumbnailUrl("https://cdn.example.com/slime-adult.png")
			.build();

		given(userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId))
			.willReturn(Optional.of(adultUserCharacter));
		given(characterRepository.findById(4L)).willReturn(Optional.of(adultCharacter));

		assertThatThrownBy(() -> service.approveIndependence(userId, true))
			.isInstanceOf(CustomException.class)
			.satisfies(throwable -> {
				CustomException exception = (CustomException)throwable;
				assertThat(exception.getErrorCode()).isEqualTo(TamagotchiErrorCode.M00_003);
				assertThat(exception.getErrorCode().getHttpStatus()).isEqualTo(HttpStatus.CONFLICT);
			});
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
			.requiredExp(100)
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

	private UserCharacter activeUserCharacter(Long userId) {
		return UserCharacter.builder()
			.userCharacterId(10L)
			.userId(userId)
			.characterId(9L)
			.name("rabi")
			.currentExp(0)
			.isActive(true)
			.isDeleted(false)
			.build();
	}

	private CharacterAction idleAction() {
		return CharacterAction.builder()
			.actionId(12L)
			.characterId(9L)
			.actionType("IDLE")
			.actionUrl("https://cdn.example.com/idle.gif")
			.build();
	}

	private UserWallet wallet(Long userId, int balance) {
		return UserWallet.builder()
			.userId(userId)
			.balance(balance)
			.build();
	}

	private Clock fixedClock(LocalDateTime dateTime) {
		return Clock.fixed(dateTime.atZone(ZoneId.systemDefault()).toInstant(), ZoneId.systemDefault());
	}
}
