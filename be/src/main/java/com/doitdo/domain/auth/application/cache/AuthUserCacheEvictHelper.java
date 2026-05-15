package com.doitdo.domain.auth.application.cache;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

@Component
@RequiredArgsConstructor
public class AuthUserCacheEvictHelper {

	private final AuthUserCacheService authUserCacheService;

	public void evict(Long userId) {
		if (userId != null) {
			authUserCacheService.evict(userId);
		}
	}

	public void evictAfterCommit(Long userId) {
		if (userId == null) {
			return;
		}
		if (!TransactionSynchronizationManager.isSynchronizationActive()
				|| !TransactionSynchronizationManager.isActualTransactionActive()) {
			evict(userId);
			return;
		}

		TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
			@Override
			public void afterCommit() {
				evict(userId);
			}
		});
	}
}
