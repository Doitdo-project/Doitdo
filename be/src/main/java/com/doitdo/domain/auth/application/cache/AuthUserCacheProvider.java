package com.doitdo.domain.auth.application.cache;

import java.util.function.Supplier;

public interface AuthUserCacheProvider {

	AuthUserSnapshot get(Long userId, Supplier<AuthUserSnapshot> loader);

	void evict(Long userId);
}
