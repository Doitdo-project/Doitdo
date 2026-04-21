package com.doitdo.domain.tamagotchi.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.doitdo.domain.tamagotchi.entity.UserCharacter;

public interface UserCharacterRepository extends JpaRepository<UserCharacter, Long> {

	Optional<UserCharacter> findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(Long userId);
}
