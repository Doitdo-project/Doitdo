package com.doitdo.domain.tamagotchi.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.doitdo.domain.tamagotchi.entity.CharacterAction;

public interface CharacterActionRepository extends JpaRepository<CharacterAction, Long> {

	List<CharacterAction> findAllByCharacterIdAndActionType(Long characterId, String actionType);
}
