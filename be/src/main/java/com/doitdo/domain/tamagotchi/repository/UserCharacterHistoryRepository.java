package com.doitdo.domain.tamagotchi.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.doitdo.domain.tamagotchi.entity.UserCharacterHistory;

public interface UserCharacterHistoryRepository extends JpaRepository<UserCharacterHistory, Long> {
}
