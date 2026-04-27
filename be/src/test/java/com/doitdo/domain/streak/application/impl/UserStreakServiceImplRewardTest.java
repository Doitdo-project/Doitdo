package com.doitdo.domain.streak.application.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

import com.doitdo.domain.streak.api.dto.resp.StreakRewardResp;
import com.doitdo.domain.streak.entity.StreakRewardLog;
import com.doitdo.domain.streak.entity.UserStreak;
import com.doitdo.domain.streak.repository.StreakRewardLogRepository;
import com.doitdo.domain.streak.repository.UserStreakRepository;
import com.doitdo.domain.user.entity.UserWallet;
import com.doitdo.domain.user.repository.UserWalletRepository;
import java.time.LocalDate;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class UserStreakServiceImplRewardTest {

	@Mock
	private UserStreakRepository userStreakRepository;

	@Mock
	private UserWalletRepository userWalletRepository;

	@Mock
	private StreakRewardLogRepository streakRewardLogRepository;

	@Test
	void claimSevenDayReward_rewardsWalletWhenCurrentStreakIsSevenDays() {
		UserStreakServiceImpl service = new UserStreakServiceImpl(
				userStreakRepository,
				userWalletRepository,
				streakRewardLogRepository
		);
		Long userId = 1L;
		LocalDate startDate = LocalDate.parse("2026-04-01");
		UserStreak streak = UserStreak.builder()
				.userId(userId)
				.currentStreakCount(7)
				.currentStreakStartDate(startDate)
				.lastActiveDate(LocalDate.parse("2026-04-07"))
				.longestStreakCount(7)
				.longestStreakStartDate(startDate)
				.longestStreakEndDate(LocalDate.parse("2026-04-07"))
				.build();
		UserWallet wallet = UserWallet.create(userId);

		given(userStreakRepository.findByUserId(userId)).willReturn(Optional.of(streak));
		given(streakRewardLogRepository.existsByUserIdAndStreakStartDateAndStreakCount(userId, startDate, 7))
				.willReturn(false);
		given(userWalletRepository.findByUserId(userId)).willReturn(Optional.of(wallet));

		StreakRewardResp resp = service.claimSevenDayReward(userId);

		assertThat(resp.rewarded()).isTrue();
		assertThat(resp.streakCount()).isEqualTo(7);
		assertThat(resp.rewardAmount()).isEqualTo(100);
		assertThat(resp.balance()).isEqualTo(100);
		assertThat(wallet.getBalance()).isEqualTo(100);
		verify(streakRewardLogRepository).save(org.mockito.ArgumentMatchers.any(StreakRewardLog.class));
	}

	@Test
	void claimSevenDayReward_doesNotRewardTwiceForSameStreakSegment() {
		UserStreakServiceImpl service = new UserStreakServiceImpl(
				userStreakRepository,
				userWalletRepository,
				streakRewardLogRepository
		);
		Long userId = 1L;
		LocalDate startDate = LocalDate.parse("2026-04-01");
		UserStreak streak = UserStreak.builder()
				.userId(userId)
				.currentStreakCount(7)
				.currentStreakStartDate(startDate)
				.lastActiveDate(LocalDate.parse("2026-04-07"))
				.longestStreakCount(7)
				.build();

		given(userStreakRepository.findByUserId(userId)).willReturn(Optional.of(streak));
		given(streakRewardLogRepository.existsByUserIdAndStreakStartDateAndStreakCount(userId, startDate, 7))
				.willReturn(true);

		StreakRewardResp resp = service.claimSevenDayReward(userId);

		assertThat(resp.rewarded()).isFalse();
		assertThat(resp.streakCount()).isEqualTo(7);
		assertThat(resp.rewardAmount()).isZero();
		assertThat(resp.balance()).isNull();
		verify(userWalletRepository, never()).findByUserId(userId);
		verify(streakRewardLogRepository, never()).save(org.mockito.ArgumentMatchers.any(StreakRewardLog.class));
	}

	@Test
	void claimSevenDayReward_doesNotRewardWhenCurrentStreakIsNotMultipleOfSeven() {
		UserStreakServiceImpl service = new UserStreakServiceImpl(
				userStreakRepository,
				userWalletRepository,
				streakRewardLogRepository
		);
		Long userId = 1L;
		UserStreak streak = UserStreak.builder()
				.userId(userId)
				.currentStreakCount(6)
				.currentStreakStartDate(LocalDate.parse("2026-04-01"))
				.lastActiveDate(LocalDate.parse("2026-04-06"))
				.longestStreakCount(6)
				.build();

		given(userStreakRepository.findByUserId(userId)).willReturn(Optional.of(streak));

		StreakRewardResp resp = service.claimSevenDayReward(userId);

		assertThat(resp.rewarded()).isFalse();
		assertThat(resp.streakCount()).isEqualTo(6);
		assertThat(resp.rewardAmount()).isZero();
		assertThat(resp.balance()).isNull();
		verify(userWalletRepository, never()).findByUserId(userId);
		verify(streakRewardLogRepository, never()).save(org.mockito.ArgumentMatchers.any(StreakRewardLog.class));
	}
}
