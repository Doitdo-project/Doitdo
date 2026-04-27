package com.doitdo.domain.tamagotchi.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.doitdo.domain.tamagotchi.entity.CharacterAction;

public interface CharacterActionRepository extends JpaRepository<CharacterAction, Long> {

	Optional<CharacterAction> findByCharacterIdAndActionType(Long characterId, String actionType);
}
