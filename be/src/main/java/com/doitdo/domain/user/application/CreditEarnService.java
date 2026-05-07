package com.doitdo.domain.user.application;

import com.doitdo.domain.user.entity.WalletEarnSource;

public interface CreditEarnService {

	int tryEarn(Long userId, WalletEarnSource source, int amount, Long refId, boolean bypassDailyCap);
}
