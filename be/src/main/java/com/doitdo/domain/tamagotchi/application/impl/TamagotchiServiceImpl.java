package com.doitdo.domain.tamagotchi.application.impl;

import java.time.Instant;
import java.util.EnumMap;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

import com.doitdo.domain.tamagotchi.api.dto.resp.CurrentCharacterResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.EncyclopediaDetailCharacterResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.EncyclopediaDetailResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.EvolutionResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.FarewellResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.HatchCharacterResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.UpdateCharacterNameResp;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.doitdo.domain.tamagotchi.api.dto.resp.EncyclopediaItemResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.EncyclopediaResp;
import com.doitdo.domain.tamagotchi.application.TamagotchiService;
import com.doitdo.domain.tamagotchi.entity.CharacterUnlock;
import com.doitdo.domain.tamagotchi.entity.UserCharacterHistory;
import com.doitdo.domain.tamagotchi.entity.UserCharacter;
import com.doitdo.domain.tamagotchi.repository.CharacterRepository;
import com.doitdo.domain.tamagotchi.repository.CharacterSpeciesBackgroundRepository;
import com.doitdo.domain.tamagotchi.repository.CharacterUnlockRepository;
import com.doitdo.domain.tamagotchi.repository.UserCharacterHistoryRepository;
import com.doitdo.domain.tamagotchi.repository.UserCharacterRepository;
import com.doitdo.domain.user.repository.UserRepository;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.TamagotchiErrorCode;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class TamagotchiServiceImpl implements TamagotchiService {

	private final CharacterRepository characterRepository;
	private final CharacterUnlockRepository characterUnlockRepository;
	private final UserCharacterRepository userCharacterRepository;
	private final UserCharacterHistoryRepository userCharacterHistoryRepository;
	private final CharacterSpeciesBackgroundRepository characterSpeciesBackgroundRepository;
	private final UserRepository userRepository;

	@Override
	@Transactional
	public CurrentCharacterResp receiveEgg(Long userId) {
		userRepository.findByIdForUpdate(userId)
			.orElseThrow(() -> new CustomException(TamagotchiErrorCode.M04_002));

		Optional<UserCharacter> currentUserCharacter = userCharacterRepository
			.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId);

		if (currentUserCharacter.isPresent()) {
			return toCurrentCharacterResp(currentUserCharacter.get(), TamagotchiErrorCode.M04_002);
		}

		com.doitdo.domain.tamagotchi.entity.Character eggCharacter = characterRepository
			.findFirstByStageOrderByCharacterIdAsc(com.doitdo.domain.tamagotchi.entity.Character.Stage.EGG)
			.orElseThrow(() -> new CustomException(TamagotchiErrorCode.M04_003));

		UserCharacter userCharacter = UserCharacter.builder()
			.userId(userId)
			.characterId(eggCharacter.getCharacterId())
			.name(eggCharacter.getName())
			.currentExp(0)
			.isActive(true)
			.isDeleted(false)
			.build();
		UserCharacter savedUserCharacter = userCharacterRepository.save(userCharacter);
		saveHistory(savedUserCharacter.getUserCharacterId(), userId, UserCharacterHistory.EventType.CREATED,
			null, eggCharacter.getCharacterId(), null, savedUserCharacter.getName(), null, 0,
			UserCharacterHistory.ActorType.USER, userId, "egg received");

		return new CurrentCharacterResp(
			eggCharacter.getCharacterId(),
			savedUserCharacter.getName(),
			eggCharacter.getStage().name(),
			eggCharacter.getThumbnailUrl(),
			0,
			0,
			eggCharacter.getRequiredExp() != null ? eggCharacter.getRequiredExp() : 0,
			false,
			false,
			savedUserCharacter.getEquipedItemsId(),
			savedUserCharacter.getUserCharacterId()
		);
	}

	@Override
	@Transactional(readOnly = true)
	public EncyclopediaResp getEncyclopedia(Long userId) {
		Set<Long> unlockedCharacterIds = characterUnlockRepository.findByUserId(userId).stream()
			.map(unlock -> unlock.getCharacterId())
			.collect(Collectors.toSet());

		return new EncyclopediaResp(characterRepository.findAll().stream()
			.filter(character -> character.getStage() == com.doitdo.domain.tamagotchi.entity.Character.Stage.ADULT)
			.map(character -> new EncyclopediaItemResp(
				character.getCharacterId(),
				character.getName(),
				character.getSpecies(),
				character.getStage().name(),
				unlockedCharacterIds.contains(character.getCharacterId()),
				character.getThumbnailUrl()
			))
			.toList());
	}

	@Override
	@Transactional(readOnly = true)
	public EncyclopediaDetailResp getEncyclopediaDetail(Long userId, String species) {
		List<com.doitdo.domain.tamagotchi.entity.Character> characters = characterRepository.findBySpecies(species);
		if (characters.isEmpty()) {
			throw new CustomException(TamagotchiErrorCode.M03_002);
		}

		com.doitdo.domain.tamagotchi.entity.CharacterSpeciesBackground background = characterSpeciesBackgroundRepository
			.findById(species)
			.orElseThrow(() -> new CustomException(TamagotchiErrorCode.M03_002));

		Long encounterCount = userCharacterRepository.countByUserIdAndSpecies(userId, species);
		EnumMap<com.doitdo.domain.tamagotchi.entity.Character.Stage, EncyclopediaDetailCharacterResp> stageMap =
			new EnumMap<>(com.doitdo.domain.tamagotchi.entity.Character.Stage.class);
		for (com.doitdo.domain.tamagotchi.entity.Character character : characters) {
			stageMap.put(character.getStage(), new EncyclopediaDetailCharacterResp(
				character.getCharacterId(),
				character.getName(),
				character.getThumbnailUrl()
			));
		}

		if (stageMap.get(com.doitdo.domain.tamagotchi.entity.Character.Stage.BABY) == null
			|| stageMap.get(com.doitdo.domain.tamagotchi.entity.Character.Stage.TEEN) == null
			|| stageMap.get(com.doitdo.domain.tamagotchi.entity.Character.Stage.ADULT) == null) {
			throw new CustomException(TamagotchiErrorCode.M03_003);
		}

		return new EncyclopediaDetailResp(
			species,
			background.getBirthBackground(),
			encounterCount != null ? encounterCount : 0L,
			stageMap.get(com.doitdo.domain.tamagotchi.entity.Character.Stage.BABY),
			stageMap.get(com.doitdo.domain.tamagotchi.entity.Character.Stage.TEEN),
			stageMap.get(com.doitdo.domain.tamagotchi.entity.Character.Stage.ADULT)
		);
	}

	@Override
	@Transactional
	public UpdateCharacterNameResp updateName(Long userId, String name) {
		if (name == null || name.isBlank() || name.length() > 20) {
			throw new CustomException(TamagotchiErrorCode.M01_003);
		}

		UserCharacter userCharacter = userCharacterRepository
			.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId)
			.orElseThrow(() -> new CustomException(TamagotchiErrorCode.M01_002));

		Long beforeCharacterId = userCharacter.getCharacterId();
		String beforeName = userCharacter.getName();
		Integer beforeExp = userCharacter.getCurrentExp();
		userCharacter.setName(name);
		saveHistory(userCharacter.getUserCharacterId(), userId, UserCharacterHistory.EventType.NAME_UPDATED,
			beforeCharacterId, beforeCharacterId, beforeName, userCharacter.getName(), beforeExp, beforeExp,
			UserCharacterHistory.ActorType.USER, userId, "name updated");

		return new UpdateCharacterNameResp(
			userCharacter.getCharacterId(),
			userCharacter.getName()
		);
	}

	@Override
	@Transactional(readOnly = true)
	public CurrentCharacterResp getCurrentCharacter(Long userId) {
		UserCharacter userCharacter = userCharacterRepository
			.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId)
			.orElseThrow(() -> new CustomException(TamagotchiErrorCode.M04_002));

		return toCurrentCharacterResp(userCharacter, TamagotchiErrorCode.M04_002);
	}

	private CurrentCharacterResp toCurrentCharacterResp(UserCharacter userCharacter, TamagotchiErrorCode errorCode) {
		com.doitdo.domain.tamagotchi.entity.Character character = characterRepository
			.findById(userCharacter.getCharacterId())
			.orElseThrow(() -> new CustomException(errorCode));

		Integer requiredExp = character.getRequiredExp();
		int growthPercent = (requiredExp == null || requiredExp == 0)
			? 0
			: Math.min(100, (int)Math.round(userCharacter.getCurrentExp() * 100.0 / requiredExp));
		boolean canEvolve = (character.getStage() == com.doitdo.domain.tamagotchi.entity.Character.Stage.BABY
			|| character.getStage() == com.doitdo.domain.tamagotchi.entity.Character.Stage.TEEN)
			&& requiredExp != null
			&& userCharacter.getCurrentExp() >= requiredExp;
		boolean canFarewell = character.getStage() == com.doitdo.domain.tamagotchi.entity.Character.Stage.ADULT
			&& requiredExp != null
			&& userCharacter.getCurrentExp() >= requiredExp;

		return new CurrentCharacterResp(
			character.getCharacterId(),
			userCharacter.getName(),
			character.getStage().name(),
			character.getThumbnailUrl(),
			growthPercent,
			userCharacter.getCurrentExp(),
			requiredExp,
			canEvolve,
			canFarewell,
			userCharacter.getEquipedItemsId(),
			userCharacter.getUserCharacterId()
		);
	}

	@Override
	@Transactional
	public HatchCharacterResp hatch(Long userId) {
		UserCharacter userCharacter = userCharacterRepository
			.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId)
			.orElseThrow(() -> new CustomException(TamagotchiErrorCode.M02_002));

		com.doitdo.domain.tamagotchi.entity.Character eggCharacter = characterRepository
			.findById(userCharacter.getCharacterId())
			.orElseThrow(() -> new CustomException(TamagotchiErrorCode.M02_002));

		if (eggCharacter.getStage() != com.doitdo.domain.tamagotchi.entity.Character.Stage.EGG) {
			throw new CustomException(TamagotchiErrorCode.M02_003);
		}

		Long beforeCharacterId = userCharacter.getCharacterId();
		String beforeName = userCharacter.getName();
		Integer beforeExp = userCharacter.getCurrentExp();
		com.doitdo.domain.tamagotchi.entity.Character babyCharacter = characterRepository
			.findFirstBySpeciesAndStageOrderByCharacterIdAsc(
				eggCharacter.getSpecies(),
				com.doitdo.domain.tamagotchi.entity.Character.Stage.BABY
			)
			.orElseThrow(() -> new CustomException(TamagotchiErrorCode.M02_004));

		userCharacter.setCharacterId(babyCharacter.getCharacterId());
		userCharacter.resetExp();
		saveHistory(userCharacter.getUserCharacterId(), userId, UserCharacterHistory.EventType.HATCHED,
			beforeCharacterId, babyCharacter.getCharacterId(), beforeName, userCharacter.getName(), beforeExp,
			userCharacter.getCurrentExp(), UserCharacterHistory.ActorType.USER, userId, "egg hatched");

		return new HatchCharacterResp(
			babyCharacter.getCharacterId(),
			babyCharacter.getStage().name(),
			userCharacter.getName(),
			babyCharacter.getThumbnailUrl()
		);
	}

	@Override
	@Transactional
	public EvolutionResp evolve(Long userId, Long userCharacterId) {
		UserCharacter userCharacter = userCharacterRepository
			.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId)
			.orElseThrow(() -> new CustomException(TamagotchiErrorCode.M05_002));

		if (!userCharacterId.equals(userCharacter.getUserCharacterId())) {
			throw new CustomException(TamagotchiErrorCode.M05_002);
		}

		com.doitdo.domain.tamagotchi.entity.Character currentCharacter = characterRepository
			.findById(userCharacter.getCharacterId())
			.orElseThrow(() -> new CustomException(TamagotchiErrorCode.M05_002));

		Long beforeCharacterId = currentCharacter.getCharacterId();
		String beforeName = userCharacter.getName();
		Integer beforeExp = userCharacter.getCurrentExp();
		Integer requiredExp = currentCharacter.getRequiredExp();
		if (requiredExp == null) {
			throw new CustomException(TamagotchiErrorCode.M05_005);
		}
		if (userCharacter.getCurrentExp() < requiredExp) {
			throw new CustomException(TamagotchiErrorCode.M05_006);
		}

		com.doitdo.domain.tamagotchi.entity.Character.Stage beforeStage = currentCharacter.getStage();
		com.doitdo.domain.tamagotchi.entity.Character.Stage afterStage = switch (beforeStage) {
			case BABY -> com.doitdo.domain.tamagotchi.entity.Character.Stage.TEEN;
			case TEEN -> com.doitdo.domain.tamagotchi.entity.Character.Stage.ADULT;
			default -> throw new CustomException(TamagotchiErrorCode.M05_003);
		};

		com.doitdo.domain.tamagotchi.entity.Character nextCharacter = characterRepository
			.findFirstBySpeciesAndStageOrderByCharacterIdAsc(currentCharacter.getSpecies(), afterStage)
			.orElseThrow(() -> new CustomException(TamagotchiErrorCode.M05_005));

		userCharacter.setCharacterId(nextCharacter.getCharacterId());
		userCharacter.resetExp();
		if (afterStage == com.doitdo.domain.tamagotchi.entity.Character.Stage.ADULT) {
			unlockSpeciesCharacters(userId, currentCharacter.getSpecies());
		}
		saveHistory(userCharacter.getUserCharacterId(), userId, UserCharacterHistory.EventType.EVOLVED,
			beforeCharacterId, nextCharacter.getCharacterId(), beforeName, userCharacter.getName(), beforeExp,
			userCharacter.getCurrentExp(), UserCharacterHistory.ActorType.USER, userId, "evolved");

		return new EvolutionResp(
			userCharacter.getUserCharacterId(),
			beforeStage.name(),
			afterStage.name(),
			userCharacter.getCurrentExp(),
			nextCharacter.getRequiredExp(),
			buildAnimationUrl(beforeStage, afterStage),
			nextCharacter.getThumbnailUrl(),
			Instant.now().toString()
		);
	}

	private void unlockSpeciesCharacters(Long userId, String species) {
		Set<Long> unlockedCharacterIds = characterUnlockRepository.findByUserId(userId).stream()
			.map(unlock -> unlock.getCharacterId())
			.collect(Collectors.toSet());

		List<CharacterUnlock> unlocksToSave = characterRepository.findBySpecies(species).stream()
			.map(character -> character.getCharacterId())
			.filter(characterId -> !unlockedCharacterIds.contains(characterId))
			.map(characterId -> CharacterUnlock.builder()
				.userId(userId)
				.characterId(characterId)
				.build())
			.toList();

		if (!unlocksToSave.isEmpty()) {
			characterUnlockRepository.saveAll(unlocksToSave);
		}
	}

	private String buildAnimationUrl(
		com.doitdo.domain.tamagotchi.entity.Character.Stage beforeStage,
		com.doitdo.domain.tamagotchi.entity.Character.Stage afterStage
	) {
		return "https://cdn.example.com/tamagotchi/animations/"
			+ beforeStage.name().toLowerCase()
			+ "-to-"
			+ afterStage.name().toLowerCase();
	}

	@Override
	@Transactional
	public FarewellResp approveIndependence(Long userId, Boolean approved) {
		UserCharacter adultUserCharacter = userCharacterRepository
			.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId)
			.orElseThrow(() -> new CustomException(TamagotchiErrorCode.M00_002));

		com.doitdo.domain.tamagotchi.entity.Character adultCharacter = characterRepository
			.findById(adultUserCharacter.getCharacterId())
			.orElseThrow(() -> new CustomException(TamagotchiErrorCode.M00_002));

		if (adultCharacter.getStage() == com.doitdo.domain.tamagotchi.entity.Character.Stage.EGG) {
			throw new CustomException(TamagotchiErrorCode.M00_003);
		}
		if (adultCharacter.getStage() != com.doitdo.domain.tamagotchi.entity.Character.Stage.ADULT) {
			throw new CustomException(TamagotchiErrorCode.M00_002);
		}
		if (!Boolean.TRUE.equals(approved)) {
			throw new CustomException(TamagotchiErrorCode.M00_003);
		}

		com.doitdo.domain.tamagotchi.entity.Character eggCharacter = characterRepository
			.findFirstByStageOrderByCharacterIdAsc(com.doitdo.domain.tamagotchi.entity.Character.Stage.EGG)
			.orElseThrow(() -> new CustomException(TamagotchiErrorCode.M00_004));

		adultUserCharacter.deactivate();
		userCharacterRepository.save(adultUserCharacter);

		UserCharacter nextEggCharacter = UserCharacter.builder()
			.userId(userId)
			.characterId(eggCharacter.getCharacterId())
			.name(adultUserCharacter.getName())
			.currentExp(0)
			.isActive(true)
			.isDeleted(false)
			.build();
		UserCharacter savedNextEggCharacter = userCharacterRepository.save(nextEggCharacter);
		saveHistory(savedNextEggCharacter.getUserCharacterId(), userId, UserCharacterHistory.EventType.FAREWELL,
			adultCharacter.getCharacterId(), eggCharacter.getCharacterId(), adultUserCharacter.getName(),
			savedNextEggCharacter.getName(), adultUserCharacter.getCurrentExp(), savedNextEggCharacter.getCurrentExp(),
			UserCharacterHistory.ActorType.USER, userId, "independence approved");

		return new FarewellResp(
			adultUserCharacter.getUserCharacterId(),
			true,
			eggCharacter.getStage().name(),
			buildAnimationUrl(
				com.doitdo.domain.tamagotchi.entity.Character.Stage.ADULT,
				com.doitdo.domain.tamagotchi.entity.Character.Stage.EGG
			)
		);
	}

	private void saveHistory(
		Long userCharacterId,
		Long userId,
		UserCharacterHistory.EventType eventType,
		Long beforeCharacterId,
		Long afterCharacterId,
		String beforeName,
		String afterName,
		Integer beforeExp,
		Integer afterExp,
		UserCharacterHistory.ActorType actorType,
		Long actorId,
		String reason
	) {
		userCharacterHistoryRepository.save(UserCharacterHistory.builder()
			.userCharacterId(userCharacterId)
			.userId(userId)
			.eventType(eventType)
			.beforeCharacterId(beforeCharacterId)
			.afterCharacterId(afterCharacterId)
			.beforeName(beforeName)
			.afterName(afterName)
			.beforeExp(beforeExp)
			.afterExp(afterExp)
			.reason(reason)
			.actorType(actorType)
			.actorId(actorId)
			.build());
	}
}
