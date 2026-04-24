package com.doitdo.domain.streak.repository;

import com.doitdo.domain.streak.entity.UserStreak;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserStreakRepository extends JpaRepository<UserStreak, Long> {

	Optional<UserStreak> findByUserId(Long userId);

	void deleteByUserId(Long userId);
}
