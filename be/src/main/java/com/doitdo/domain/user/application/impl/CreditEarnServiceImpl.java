package com.doitdo.domain.user.application.impl;

import com.doitdo.domain.user.application.CreditEarnService;
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
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
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
	@Transactional
	public int tryEarn(Long userId, WalletEarnSource source, int amount, Long refId, boolean bypassDailyCap) {
		UserWallet wallet = userWalletRepository.findByUserIdForUpdate(userId)
				.orElseThrow(() -> new CustomException(UserErrorCode.U05_001));

		if (shouldCheckDailyCap(source, bypassDailyCap) && exceedsDailyCap(userId, source, amount)) {
			return 0;
		}

		wallet.addBalance(amount);
		walletEarnLogRepository.save(WalletEarnLog.builder()
				.userId(userId)
				.source(source)
				.amount(amount)
				.refId(refId)
				.earnedAt(LocalDateTime.now(SEOUL))
				.build());

		return amount;
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
