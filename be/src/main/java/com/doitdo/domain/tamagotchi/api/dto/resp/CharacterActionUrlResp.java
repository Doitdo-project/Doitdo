package com.doitdo.domain.tamagotchi.api.dto.resp;

public record CharacterActionUrlResp(
	String actionUrl,
	int earnedAmount,
	int balanceAfter
) {
}
