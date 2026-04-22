package com.doitdo.domain.tamagotchi.application.impl;

import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

import com.doitdo.domain.tamagotchi.api.dto.resp.CurrentCharacterResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.HatchCharacterResp;
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
}
