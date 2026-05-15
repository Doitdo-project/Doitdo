package com.doitdo.domain.auth.application.cache;

import java.util.function.Supplier;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(name = "auth.user-cache.provider", havingValue = "none", matchIfMissing = true)
public class NoneAuthUserCacheProvider implements AuthUserCacheProvider {

	@Override
	public AuthUserSnapshot get(Long userId, Supplier<AuthUserSnapshot> loader) {
		return loader.get();
	}

	@Override
	public void evict(Long userId) {
		// no-op
	}
}
