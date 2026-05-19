package com.doitdo.domain.user.application.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.verify;

import com.doitdo.domain.user.application.dto.EarnResult;
import com.doitdo.domain.user.entity.UserWallet;
import com.doitdo.domain.user.entity.WalletEarnLog;
import com.doitdo.domain.user.entity.WalletEarnSource;
import com.doitdo.domain.user.repository.UserWalletRepository;
import com.doitdo.domain.user.repository.WalletEarnLogRepository;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.UserErrorCode;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class CreditEarnServiceImplTest {

	@Mock
	private UserWalletRepository userWalletRepository;

	@Mock
	private WalletEarnLogRepository walletEarnLogRepository;

	private CreditEarnServiceImpl service() {
		return new CreditEarnServiceImpl(userWalletRepository, walletEarnLogRepository);
	}

	@Test
	void tryEarn_petTouchBelowCap_addsBalanceAndSavesLog() {
		Long userId = 1L;
		UserWallet wallet = spy(UserWallet.builder()
				.userId(userId)
				.balance(0)
				.build());
		given(userWalletRepository.findByUserIdForUpdate(userId)).willReturn(Optional.of(wallet));
		given(walletEarnLogRepository.sumAmountByUserIdAndSourceAndDate(
				org.mockito.ArgumentMatchers.eq(userId),
				org.mockito.ArgumentMatchers.eq(WalletEarnSource.PET_TOUCH),
				any(LocalDateTime.class),
				any(LocalDateTime.class)
		)).willReturn(20);
		given(walletEarnLogRepository.sumAmountByUserIdAndSourcesAndDate(
				org.mockito.ArgumentMatchers.eq(userId),
				org.mockito.ArgumentMatchers.eq(List.of(WalletEarnSource.PET_TOUCH, WalletEarnSource.TODO_COMPLETION)),
				any(LocalDateTime.class),
				any(LocalDateTime.class)
		)).willReturn(40);

		EarnResult result = service().tryEarn(userId, WalletEarnSource.PET_TOUCH, 50, 100L, false);

		assertThat(result.earnedAmount()).isEqualTo(50);
		assertThat(result.balance()).isEqualTo(50);
		assertThat(result.rewarded()).isTrue();
		verify(wallet).addBalance(50);
		ArgumentCaptor<WalletEarnLog> logCaptor = ArgumentCaptor.forClass(WalletEarnLog.class);
		verify(walletEarnLogRepository).save(logCaptor.capture());
		assertThat(logCaptor.getValue().getUserId()).isEqualTo(userId);
		assertThat(logCaptor.getValue().getSource()).isEqualTo(WalletEarnSource.PET_TOUCH);
		assertThat(logCaptor.getValue().getAmount()).isEqualTo(50);
		assertThat(logCaptor.getValue().getRefId()).isEqualTo(100L);
		assertThat(logCaptor.getValue().getEarnedAt()).isNotNull();
	}

	@Test
	void tryEarn_petTouchSourceCapExceeded_returnsZeroWithoutAddingBalance() {
		Long userId = 1L;
		UserWallet wallet = spy(UserWallet.builder()
				.userId(userId)
				.balance(0)
				.build());
		given(userWalletRepository.findByUserIdForUpdate(userId)).willReturn(Optional.of(wallet));
		given(walletEarnLogRepository.sumAmountByUserIdAndSourceAndDate(
				org.mockito.ArgumentMatchers.eq(userId),
				org.mockito.ArgumentMatchers.eq(WalletEarnSource.PET_TOUCH),
				any(LocalDateTime.class),
				any(LocalDateTime.class)
		)).willReturn(100);

		EarnResult result = service().tryEarn(userId, WalletEarnSource.PET_TOUCH, 50, 100L, false);

		assertThat(result.earnedAmount()).isZero();
		assertThat(result.balance()).isZero();
		assertThat(result.rewarded()).isFalse();
		verify(wallet, never()).addBalance(anyInt());
		verify(walletEarnLogRepository, never()).save(any(WalletEarnLog.class));
	}

	@Test
	void tryEarn_todoCompletionSourceCapExceeded_returnsZero() {
		Long userId = 1L;
		UserWallet wallet = spy(UserWallet.builder()
				.userId(userId)
				.balance(0)
				.build());
		given(userWalletRepository.findByUserIdForUpdate(userId)).willReturn(Optional.of(wallet));
		given(walletEarnLogRepository.sumAmountByUserIdAndSourceAndDate(
				org.mockito.ArgumentMatchers.eq(userId),
				org.mockito.ArgumentMatchers.eq(WalletEarnSource.TODO_COMPLETION),
				any(LocalDateTime.class),
				any(LocalDateTime.class)
		)).willReturn(100);

		EarnResult result = service().tryEarn(userId, WalletEarnSource.TODO_COMPLETION, 20, 200L, false);

		assertThat(result.earnedAmount()).isZero();
		assertThat(result.balance()).isZero();
		assertThat(result.rewarded()).isFalse();
		verify(wallet, never()).addBalance(anyInt());
		verify(walletEarnLogRepository, never()).save(any(WalletEarnLog.class));
	}

	@Test
	void tryEarn_combinedDailyCapExceeded_returnsZero() {
		Long userId = 1L;
		UserWallet wallet = spy(UserWallet.builder()
				.userId(userId)
				.balance(0)
				.build());
		given(userWalletRepository.findByUserIdForUpdate(userId)).willReturn(Optional.of(wallet));
		given(walletEarnLogRepository.sumAmountByUserIdAndSourceAndDate(
				org.mockito.ArgumentMatchers.eq(userId),
				org.mockito.ArgumentMatchers.eq(WalletEarnSource.TODO_COMPLETION),
				any(LocalDateTime.class),
				any(LocalDateTime.class)
		)).willReturn(80);
		given(walletEarnLogRepository.sumAmountByUserIdAndSourcesAndDate(
				org.mockito.ArgumentMatchers.eq(userId),
				org.mockito.ArgumentMatchers.eq(List.of(WalletEarnSource.PET_TOUCH, WalletEarnSource.TODO_COMPLETION)),
				any(LocalDateTime.class),
				any(LocalDateTime.class)
		)).willReturn(190);

		EarnResult result = service().tryEarn(userId, WalletEarnSource.TODO_COMPLETION, 20, 200L, false);

		assertThat(result.earnedAmount()).isZero();
		assertThat(result.balance()).isZero();
		assertThat(result.rewarded()).isFalse();
		verify(wallet, never()).addBalance(anyInt());
		verify(walletEarnLogRepository, never()).save(any(WalletEarnLog.class));
	}

	@Test
	void tryEarn_todoCompletionSameRefAlreadyEarned_returnsZeroWithoutAddingBalance() {
		Long userId = 1L;
		UserWallet wallet = spy(UserWallet.builder()
				.userId(userId)
				.balance(40)
				.build());
		given(userWalletRepository.findByUserIdForUpdate(userId)).willReturn(Optional.of(wallet));
		given(walletEarnLogRepository.existsByUserIdAndSourceAndRefId(
				userId,
				WalletEarnSource.TODO_COMPLETION,
				200L
		)).willReturn(true);

		EarnResult result = service().tryEarn(userId, WalletEarnSource.TODO_COMPLETION, 20, 200L, false);

		assertThat(result.earnedAmount()).isZero();
		assertThat(result.balance()).isEqualTo(40);
		assertThat(result.rewarded()).isFalse();
		verify(wallet, never()).addBalance(anyInt());
		verify(walletEarnLogRepository, never()).sumAmountByUserIdAndSourceAndDate(any(), any(), any(), any());
		verify(walletEarnLogRepository, never()).save(any(WalletEarnLog.class));
	}

	@Test
	void tryEarn_signupBonusBypassDailyCap_addsBalanceWithoutCapChecks() {
		Long userId = 1L;
		UserWallet wallet = spy(UserWallet.builder()
				.userId(userId)
				.balance(0)
				.build());
		given(userWalletRepository.findByUserIdForUpdate(userId)).willReturn(Optional.of(wallet));

		EarnResult result = service().tryEarn(userId, WalletEarnSource.SIGNUP_BONUS, 100, null, true);

		assertThat(result.earnedAmount()).isEqualTo(100);
		assertThat(result.balance()).isEqualTo(100);
		assertThat(result.rewarded()).isTrue();
		verify(wallet).addBalance(100);
		verify(walletEarnLogRepository, never()).sumAmountByUserIdAndSourceAndDate(
				any(), any(), any(), any()
		);
		verify(walletEarnLogRepository).save(any(WalletEarnLog.class));
	}

	@Test
	void tryEarn_streakSevenDayBypassDailyCap_addsBalanceWithoutCapChecks() {
		Long userId = 1L;
		UserWallet wallet = spy(UserWallet.builder()
				.userId(userId)
				.balance(0)
				.build());
		given(userWalletRepository.findByUserIdForUpdate(userId)).willReturn(Optional.of(wallet));

		EarnResult result = service().tryEarn(userId, WalletEarnSource.STREAK_7DAY, 500, 50L, true);

		assertThat(result.earnedAmount()).isEqualTo(500);
		assertThat(result.balance()).isEqualTo(500);
		assertThat(result.rewarded()).isTrue();
		verify(wallet).addBalance(500);
		verify(walletEarnLogRepository, never()).sumAmountByUserIdAndSourceAndDate(
				any(), any(), any(), any()
		);
		verify(walletEarnLogRepository).save(any(WalletEarnLog.class));
	}

	@Test
	void tryEarn_walletNotFound_throwsException() {
		Long userId = 1L;
		given(userWalletRepository.findByUserIdForUpdate(userId)).willReturn(Optional.empty());

		assertThatThrownBy(() -> service().tryEarn(userId, WalletEarnSource.PET_TOUCH, 50, null, false))
				.isInstanceOf(CustomException.class)
				.extracting("errorCode")
				.isEqualTo(UserErrorCode.U05_001);
	}
}
