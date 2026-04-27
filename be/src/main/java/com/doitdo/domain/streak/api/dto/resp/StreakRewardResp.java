package com.doitdo.domain.streak.api.dto.resp;

public record StreakRewardResp(
		boolean rewarded,
		Integer streakCount,
		Integer rewardAmount,
		Integer balance
) {

	public static StreakRewardResp rewarded(Integer streakCount, Integer rewardAmount, Integer balance) {
		return new StreakRewardResp(true, streakCount, rewardAmount, balance);
	}

	public static StreakRewardResp notRewarded(Integer streakCount) {
		return new StreakRewardResp(false, streakCount, 0, null);
	}
}
