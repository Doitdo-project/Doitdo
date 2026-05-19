package com.doitdo.domain.user.application;

import com.doitdo.domain.user.application.dto.EarnResult;
import com.doitdo.domain.user.entity.WalletEarnSource;

public interface CreditEarnService {

	EarnResult tryEarn(Long userId, WalletEarnSource source, int amount, Long refId, boolean bypassDailyCap);
}
