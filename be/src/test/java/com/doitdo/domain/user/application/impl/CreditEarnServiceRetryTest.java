package com.doitdo.domain.user.application.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

import com.doitdo.domain.user.application.CreditEarnService;
import com.doitdo.domain.user.application.dto.EarnResult;
import com.doitdo.domain.user.entity.UserWallet;
import com.doitdo.domain.user.entity.WalletEarnSource;
import com.doitdo.domain.user.repository.UserWalletRepository;
import com.doitdo.domain.user.repository.WalletEarnLogRepository;
import com.doitdo.global.exception.CustomException;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.dao.CannotAcquireLockException;
import org.springframework.retry.annotation.EnableRetry;
import org.springframework.test.context.junit.jupiter.SpringJUnitConfig;

@SpringJUnitConfig(CreditEarnServiceRetryTest.TestConfig.class)
class CreditEarnServiceRetryTest {

	private static final Long USER_ID = 1L;

	@Autowired
	private CreditEarnService creditEarnService;

	@Autowired
	private UserWalletRepository userWalletRepository;

	@Autowired
	private WalletEarnLogRepository walletEarnLogRepository;

	@BeforeEach
	void setUp() {
		reset(userWalletRepository, walletEarnLogRepository);
	}

	@Test
	void tryEarn_transientLockFailureRetriesAndThenSucceeds() {
		UserWallet wallet = UserWallet.builder()
				.userId(USER_ID)
				.balance(10)
				.build();
		given(userWalletRepository.findByUserIdForUpdate(USER_ID))
				.willThrow(new CannotAcquireLockException("first lock conflict"))
				.willThrow(new CannotAcquireLockException("second lock conflict"))
				.willReturn(Optional.of(wallet));
		given(walletEarnLogRepository.sumAmountByUserIdAndSourceAndDate(
				eq(USER_ID),
				eq(WalletEarnSource.PET_TOUCH),
				any(LocalDateTime.class),
				any(LocalDateTime.class)
		)).willReturn(0);
		given(walletEarnLogRepository.sumAmountByUserIdAndSourcesAndDate(
				eq(USER_ID),
				eq(List.of(WalletEarnSource.PET_TOUCH, WalletEarnSource.TODO_COMPLETION)),
				any(LocalDateTime.class),
				any(LocalDateTime.class)
		)).willReturn(0);

		EarnResult result = creditEarnService.tryEarn(USER_ID, WalletEarnSource.PET_TOUCH, 20, 10L, false);

		assertThat(result.earnedAmount()).isEqualTo(20);
		assertThat(result.balance()).isEqualTo(30);
		assertThat(result.rewarded()).isTrue();
		verify(userWalletRepository, times(3)).findByUserIdForUpdate(USER_ID);
	}

	@Test
	void tryEarn_transientLockFailureExhaustedRecoversWithCurrentBalance() {
		UserWallet wallet = UserWallet.builder()
				.userId(USER_ID)
				.balance(70)
				.build();
		given(userWalletRepository.findByUserIdForUpdate(USER_ID))
				.willThrow(new CannotAcquireLockException("lock conflict"));
		given(userWalletRepository.findByUserId(USER_ID)).willReturn(Optional.of(wallet));

		EarnResult result = creditEarnService.tryEarn(USER_ID, WalletEarnSource.TODO_COMPLETION, 20, 10L, false);

		assertThat(result.earnedAmount()).isZero();
		assertThat(result.balance()).isEqualTo(70);
		assertThat(result.rewarded()).isFalse();
		verify(userWalletRepository, times(3)).findByUserIdForUpdate(USER_ID);
		verify(userWalletRepository).findByUserId(USER_ID);
	}

	@Test
	void tryEarn_businessExceptionDoesNotRetry() {
		given(userWalletRepository.findByUserIdForUpdate(USER_ID)).willReturn(Optional.empty());

		assertThatThrownBy(() -> creditEarnService.tryEarn(
				USER_ID,
				WalletEarnSource.TODO_COMPLETION,
				20,
				10L,
				false
		)).isInstanceOf(CustomException.class);
		verify(userWalletRepository, times(1)).findByUserIdForUpdate(USER_ID);
	}

	@Configuration
	@EnableRetry
	static class TestConfig {

		@Bean
		UserWalletRepository userWalletRepository() {
			return mock(UserWalletRepository.class);
		}

		@Bean
		WalletEarnLogRepository walletEarnLogRepository() {
			return mock(WalletEarnLogRepository.class);
		}

		@Bean
		CreditEarnService creditEarnService(
				UserWalletRepository userWalletRepository,
				WalletEarnLogRepository walletEarnLogRepository) {
			return new CreditEarnServiceImpl(userWalletRepository, walletEarnLogRepository);
		}
	}
}
