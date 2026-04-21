package com.doitdo.domain.tamagotchi.application.impl;

import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.doitdo.domain.tamagotchi.api.dto.resp.EncyclopediaItemResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.EncyclopediaResp;
import com.doitdo.domain.tamagotchi.application.TamagotchiService;
import com.doitdo.domain.tamagotchi.repository.CharacterRepository;
import com.doitdo.domain.tamagotchi.repository.CharacterUnlockRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class TamagotchiServiceImpl implements TamagotchiService {

	private final CharacterRepository characterRepository;
	private final CharacterUnlockRepository characterUnlockRepository;

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
}
