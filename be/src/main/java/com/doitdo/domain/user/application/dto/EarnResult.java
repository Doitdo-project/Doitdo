package com.doitdo.domain.user.application.dto;

public record EarnResult(
		int earnedAmount,
		int balance,
		boolean rewarded
) {
}
