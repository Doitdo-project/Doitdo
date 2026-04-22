package com.doitdo.domain.tamagotchi.application.impl;

import java.time.Instant;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

import com.doitdo.domain.tamagotchi.api.dto.resp.CurrentCharacterResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.EvolutionResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.FarewellResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.HatchCharacterResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.UpdateCharacterNameResp;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.doitdo.domain.tamagotchi.api.dto.resp.EncyclopediaItemResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.EncyclopediaResp;
import com.doitdo.domain.tamagotchi.application.TamagotchiService;
import com.doitdo.domain.tamagotchi.entity.UserCharacter;
import com.doitdo.domain.tamagotchi.repository.CharacterRepository;
import com.doitdo.domain.tamagotchi.repository.CharacterUnlockRepository;
import com.doitdo.domain.tamagotchi.repository.UserCharacterRepository;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.TamagotchiErrorCode;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class TamagotchiServiceImpl implements TamagotchiService {

	private final CharacterRepository characterRepository;
	private final CharacterUnlockRepository characterUnlockRepository;
	private final UserCharacterRepository userCharacterRepository;

	@Override
	@Transactional(readOnly = true)
	public EncyclopediaResp getEncyclopedia(Long userId) {
		Set<Long> unlockedCharacterIds = characterUnlockRepository.findByUserId(userId).stream()
			.map(unlock -> unlock.getCharacterId())
			.collect(Collectors.toSet());

		return new EncyclopediaResp(characterRepository.findAll().stream()
			.map(character -> new EncyclopediaItemResp(
				character.getCharacterId(),
				character.getSpecies(),
				character.getStage().name(),
				unlockedCharacterIds.contains(character.getCharacterId()),
				character.getThumbnailUrl()
			))
			.toList());
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

		userCharacter.setName(name);

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

		com.doitdo.domain.tamagotchi.entity.Character character = characterRepository
			.findById(userCharacter.getCharacterId())
			.orElseThrow(() -> new CustomException(TamagotchiErrorCode.M04_002));

		return new CurrentCharacterResp(
			character.getCharacterId(),
			userCharacter.getName(),
			character.getStage().name(),
			userCharacter.getGrowthPercent(),
			userCharacter.getEquipedItemsId()
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

		com.doitdo.domain.tamagotchi.entity.Character babyCharacter = characterRepository
			.findFirstBySpeciesAndStageOrderByCharacterIdAsc(
				eggCharacter.getSpecies(),
				com.doitdo.domain.tamagotchi.entity.Character.Stage.BABY
			)
			.orElseThrow(() -> new CustomException(TamagotchiErrorCode.M02_004));

		userCharacter.setCharacterId(babyCharacter.getCharacterId());
		userCharacter.setGrowthPercent(0);

		return new HatchCharacterResp(
			babyCharacter.getCharacterId(),
			babyCharacter.getStage().name(),
			userCharacter.getName()
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
		userCharacter.setGrowthPercent(0);

		return new EvolutionResp(
			userCharacter.getUserCharacterId(),
			beforeStage.name(),
			afterStage.name(),
			userCharacter.getGrowthPercent(),
			getRequiredExp(afterStage),
			buildAnimationUrl(beforeStage, afterStage),
			nextCharacter.getThumbnailUrl(),
			Instant.now().toString()
		);
	}

	private int getRequiredExp(com.doitdo.domain.tamagotchi.entity.Character.Stage stage) {
		return switch (stage) {
			case TEEN -> 100;
			case ADULT -> 200;
			default -> 0;
		};
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
			.growthPercent(0)
			.isActive(true)
			.isDeleted(false)
			.build();
		userCharacterRepository.save(nextEggCharacter);

		return new FarewellResp(
			adultUserCharacter.getUserCharacterId(),
			true,
			eggCharacter.getStage().name(),
			buildAnimationUrl(com.doitdo.domain.tamagotchi.entity.Character.Stage.ADULT,
				com.doitdo.domain.tamagotchi.entity.Character.Stage.EGG)
		);
	}
}
