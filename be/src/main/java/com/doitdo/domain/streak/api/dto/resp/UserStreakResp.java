package com.doitdo.domain.streak.api.dto.resp;

import com.doitdo.domain.streak.entity.UserStreak;
import java.time.LocalDate;

public record UserStreakResp(

		Integer currentStreakCount,
		LocalDate currentStreakStartDate,
		LocalDate lastActiveDate,
		Integer longestStreakCount,
		LocalDate longestStreakStartDate,
		LocalDate longestStreakEndDate
) {

	public static UserStreakResp from(UserStreak streak) {
		return new UserStreakResp(
				streak.getCurrentStreakCount(),
				streak.getCurrentStreakStartDate(),
				streak.getLastActiveDate(),
				streak.getLongestStreakCount(),
				streak.getLongestStreakStartDate(),
				streak.getLongestStreakEndDate()
		);
	}
}
