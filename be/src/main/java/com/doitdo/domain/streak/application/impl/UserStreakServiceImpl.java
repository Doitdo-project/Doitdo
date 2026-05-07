package com.doitdo.domain.streak.application.impl;

import com.doitdo.domain.streak.api.dto.resp.StreakRewardResp;
import com.doitdo.domain.streak.api.dto.resp.UserStreakResp;
import com.doitdo.domain.streak.application.UserStreakService;
import com.doitdo.domain.streak.entity.StreakRewardLog;
import com.doitdo.domain.streak.entity.UserStreak;
import com.doitdo.domain.streak.repository.StreakRewardLogRepository;
import com.doitdo.domain.streak.repository.UserStreakRepository;
import com.doitdo.domain.user.entity.UserWallet;
import com.doitdo.domain.user.repository.UserWalletRepository;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.UserErrorCode;
import java.time.LocalDate;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UserStreakServiceImpl implements UserStreakService {

	private static final int REWARD_INTERVAL_DAYS = 7;
	private static final int SEVEN_DAY_REWARD_AMOUNT = 200;

	private final UserStreakRepository userStreakRepository;
	private final UserWalletRepository userWalletRepository;
	private final StreakRewardLogRepository streakRewardLogRepository;

	@Override
	@Transactional
	public void recordActivity(Long userId) {
		UserStreak streak = userStreakRepository.findByUserId(userId)
				.orElseGet(() -> userStreakRepository.save(UserStreak.create(userId)));
		streak.recordActivity(LocalDate.now());
	}

	@Override
	@Transactional(readOnly = true)
	public UserStreakResp getMyStreak(Long userId) {
		UserStreak streak = userStreakRepository.findByUserId(userId)
				.orElseThrow(() -> new CustomException(UserErrorCode.U06_002));
		return UserStreakResp.from(streak);
	}

	@Override
	@Transactional
	public StreakRewardResp claimSevenDayReward(Long userId) {
		UserStreak streak = userStreakRepository.findByUserId(userId)
				.orElseThrow(() -> new CustomException(UserErrorCode.U06_002));
		Integer streakCount = streak.getCurrentStreakCount();

		if (!isRewardable(streak)) {
			return StreakRewardResp.notRewarded(streakCount);
		}

		boolean alreadyRewarded = streakRewardLogRepository.existsByUserIdAndStreakStartDateAndStreakCount(
				userId,
				streak.getCurrentStreakStartDate(),
				streakCount
		);
		if (alreadyRewarded) {
			return StreakRewardResp.notRewarded(streakCount);
		}

		UserWallet wallet = userWalletRepository.findByUserId(userId)
				.orElseThrow(() -> new CustomException(UserErrorCode.U06_004));
		wallet.addBalance(SEVEN_DAY_REWARD_AMOUNT);
		streakRewardLogRepository.save(StreakRewardLog.create(
				userId,
				streak.getCurrentStreakStartDate(),
				streakCount,
				SEVEN_DAY_REWARD_AMOUNT
		));

		return StreakRewardResp.rewarded(streakCount, SEVEN_DAY_REWARD_AMOUNT, wallet.getBalance());
	}

	private boolean isRewardable(UserStreak streak) {
		Integer streakCount = streak.getCurrentStreakCount();
		return streak.getCurrentStreakStartDate() != null
				&& streakCount != null
				&& streakCount >= REWARD_INTERVAL_DAYS
				&& streakCount % REWARD_INTERVAL_DAYS == 0;
	}
}
