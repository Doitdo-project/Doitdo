package com.doitdo.domain.user.application.impl;

import com.doitdo.domain.user.application.CreditEarnService;
import com.doitdo.domain.user.application.dto.EarnResult;
import com.doitdo.domain.user.entity.UserWallet;
import com.doitdo.domain.user.entity.WalletEarnLog;
import com.doitdo.domain.user.entity.WalletEarnSource;
import com.doitdo.domain.user.repository.UserWalletRepository;
import com.doitdo.domain.user.repository.WalletEarnLogRepository;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.UserErrorCode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.CannotAcquireLockException;
import org.springframework.dao.OptimisticLockingFailureException;
import org.springframework.dao.PessimisticLockingFailureException;
import org.springframework.dao.TransientDataAccessException;
import org.springframework.retry.annotation.Backoff;
import org.springframework.retry.annotation.Recover;
import org.springframework.retry.annotation.Retryable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class CreditEarnServiceImpl implements CreditEarnService {

	private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");
	private static final int SOURCE_DAILY_CAP = 100;
	private static final int COMBINED_DAILY_CAP = 200;
	private static final List<WalletEarnSource> DAILY_CAPPED_SOURCES = List.of(
			WalletEarnSource.PET_TOUCH,
			WalletEarnSource.TODO_COMPLETION
	);

	private final UserWalletRepository userWalletRepository;
	private final WalletEarnLogRepository walletEarnLogRepository;

	@Override
	@Transactional(propagation = Propagation.REQUIRES_NEW)
	@Retryable(
			retryFor = {
					PessimisticLockingFailureException.class,
					OptimisticLockingFailureException.class,
					CannotAcquireLockException.class,
					TransientDataAccessException.class
			},
			noRetryFor = CustomException.class,
			notRecoverable = CustomException.class,
			maxAttempts = 3,
			backoff = @Backoff(delay = 50, maxDelay = 100, multiplier = 2.0)
	)
	public EarnResult tryEarn(Long userId, WalletEarnSource source, int amount, Long refId, boolean bypassDailyCap) {
		UserWallet wallet = userWalletRepository.findByUserIdForUpdate(userId)
				.orElseThrow(() -> new CustomException(UserErrorCode.U05_001));

		if (isDuplicateTodoCompletion(userId, source, refId)) {
			return new EarnResult(0, wallet.getBalance(), false);
		}

		if (shouldCheckDailyCap(source, bypassDailyCap) && exceedsDailyCap(userId, source, amount)) {
			return new EarnResult(0, wallet.getBalance(), false);
		}

		wallet.addBalance(amount);
		walletEarnLogRepository.save(WalletEarnLog.builder()
				.userId(userId)
				.source(source)
				.amount(amount)
				.refId(refId)
				.earnedAt(LocalDateTime.now(SEOUL))
				.build());

		return new EarnResult(amount, wallet.getBalance(), true);
	}

	@Recover
	public EarnResult recover(
			TransientDataAccessException exception,
			Long userId,
			WalletEarnSource source,
			int amount,
			Long refId,
			boolean bypassDailyCap) {
		int balance = userWalletRepository.findByUserId(userId)
				.map(UserWallet::getBalance)
				.orElse(0);
		log.warn("event=CREDIT_EARN_RETRY_EXHAUSTED userId={} source={} refId={} amount={} balance={}",
				userId, source, refId, amount, balance, exception);
		return new EarnResult(0, balance, false);
	}

	private boolean isDuplicateTodoCompletion(Long userId, WalletEarnSource source, Long refId) {
		return source == WalletEarnSource.TODO_COMPLETION
				&& refId != null
				&& walletEarnLogRepository.existsByUserIdAndSourceAndRefId(userId, source, refId);
	}

	private boolean shouldCheckDailyCap(WalletEarnSource source, boolean bypassDailyCap) {
		return !bypassDailyCap && DAILY_CAPPED_SOURCES.contains(source);
	}

	private boolean exceedsDailyCap(Long userId, WalletEarnSource source, int amount) {
		LocalDate today = LocalDate.now(SEOUL);
		LocalDateTime startOfDay = today.atStartOfDay();
		LocalDateTime endOfDay = today.plusDays(1).atStartOfDay();

		int sourceEarnedAmount = walletEarnLogRepository.sumAmountByUserIdAndSourceAndDate(
				userId,
				source,
				startOfDay,
				endOfDay
		);
		if (sourceEarnedAmount + amount > SOURCE_DAILY_CAP) {
			return true;
		}

		int combinedEarnedAmount = walletEarnLogRepository.sumAmountByUserIdAndSourcesAndDate(
				userId,
				DAILY_CAPPED_SOURCES,
				startOfDay,
				endOfDay
		);
		return combinedEarnedAmount + amount > COMBINED_DAILY_CAP;
	}
}
