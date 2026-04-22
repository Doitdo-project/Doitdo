package com.doitdo.domain.tamagotchi.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.doitdo.domain.tamagotchi.entity.Character;

public interface CharacterRepository extends JpaRepository<Character, Long> {

	Optional<Character> findFirstBySpeciesAndStageOrderByCharacterIdAsc(String species, Character.Stage stage);

	Optional<Character> findFirstByStageOrderByCharacterIdAsc(Character.Stage stage);
}
