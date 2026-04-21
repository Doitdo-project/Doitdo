package com.doitdo.domain.tamagotchi.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.doitdo.domain.tamagotchi.entity.CharacterUnlock;
import com.doitdo.domain.tamagotchi.entity.CharacterUnlockId;

public interface CharacterUnlockRepository extends JpaRepository<CharacterUnlock, CharacterUnlockId> {

	List<CharacterUnlock> findByUserId(Long userId);
}
