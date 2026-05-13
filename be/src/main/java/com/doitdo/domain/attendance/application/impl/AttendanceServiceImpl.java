package com.doitdo.domain.attendance.application.impl;

import com.doitdo.domain.attendance.api.dto.resp.AttendanceClaimResp;
import com.doitdo.domain.attendance.application.AttendanceService;
import com.doitdo.domain.user.application.CreditEarnService;
import com.doitdo.domain.user.entity.UserWallet;
import com.doitdo.domain.user.entity.WalletEarnSource;
import com.doitdo.domain.user.repository.UserWalletRepository;
import com.doitdo.domain.user.repository.WalletEarnLogRepository;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.UserErrorCode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AttendanceServiceImpl implements AttendanceService {

	private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");
	private static final int DAILY_ATTENDANCE_REWARD = 100;

	private final CreditEarnService creditEarnService;
	private final WalletEarnLogRepository walletEarnLogRepository;
	private final UserWalletRepository userWalletRepository;

	@Override
	@Transactional
	public AttendanceClaimResp claim(Long userId) {
		LocalDate today = LocalDate.now(SEOUL);
		if (isClaimed(userId, today)) {
			throw new CustomException(UserErrorCode.U07_001);
		}

		int earnedAmount = creditEarnService.tryEarn(
				userId,
				WalletEarnSource.DAILY_ATTENDANCE,
				DAILY_ATTENDANCE_REWARD,
				null,
				true
		);
		UserWallet wallet = userWalletRepository.findByUserId(userId)
				.orElseThrow(() -> new CustomException(UserErrorCode.U05_001));

		return new AttendanceClaimResp(earnedAmount, wallet.getBalance(), today);
	}

	private boolean isClaimed(Long userId, LocalDate date) {
		LocalDateTime startOfDay = date.atStartOfDay();
		LocalDateTime endOfDay = date.plusDays(1).atStartOfDay();
		return walletEarnLogRepository.sumAmountByUserIdAndSourceAndDate(
				userId,
				WalletEarnSource.DAILY_ATTENDANCE,
				startOfDay,
				endOfDay
		) > 0;
	}
}
