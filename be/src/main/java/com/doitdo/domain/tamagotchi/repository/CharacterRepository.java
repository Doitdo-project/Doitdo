package com.doitdo.domain.tamagotchi.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.doitdo.domain.tamagotchi.entity.Character;

public interface CharacterRepository extends JpaRepository<Character, Long> {
}
