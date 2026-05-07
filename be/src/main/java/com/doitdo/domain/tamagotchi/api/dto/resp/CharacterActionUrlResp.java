package com.doitdo.domain.tamagotchi.api.dto.resp;

import java.time.LocalDateTime;

public record CharacterActionUrlResp(
	String actionUrl,
	int earnedAmount,
	int balanceAfter,
	int dailyTouchCount,
	LocalDateTime nextAvailableAt
) {
}
