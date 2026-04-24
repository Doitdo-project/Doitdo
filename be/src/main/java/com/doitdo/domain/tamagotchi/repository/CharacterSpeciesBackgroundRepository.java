package com.doitdo.domain.tamagotchi.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.doitdo.domain.tamagotchi.entity.CharacterSpeciesBackground;

public interface CharacterSpeciesBackgroundRepository extends JpaRepository<CharacterSpeciesBackground, String> {
}
