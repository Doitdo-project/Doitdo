package com.doitdo.domain.streak.repository;

import com.doitdo.domain.streak.entity.StreakRewardLog;
import java.time.LocalDate;
import org.springframework.data.jpa.repository.JpaRepository;

public interface StreakRewardLogRepository extends JpaRepository<StreakRewardLog, Long> {

	boolean existsByUserIdAndStreakStartDateAndStreakCount(Long userId, LocalDate streakStartDate, Integer streakCount);
}
