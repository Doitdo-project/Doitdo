package com.doitdo.domain.auth.application.cache;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import jakarta.annotation.PostConstruct;
import java.util.function.Supplier;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(name = "auth.user-cache.provider", havingValue = "caffeine")
public class CaffeineAuthUserCacheProvider implements AuthUserCacheProvider {

	private final AuthUserCacheProperties properties;
	private Cache<Long, AuthUserSnapshot> cache;

	public CaffeineAuthUserCacheProvider(AuthUserCacheProperties properties) {
		this.properties = properties;
	}

	@PostConstruct
	void initializeCache() {
		this.cache = Caffeine.newBuilder()
				.expireAfterWrite(properties.getTtl())
				.maximumSize(properties.getMaxSize())
				.build();
	}

	@Override
	public AuthUserSnapshot get(Long userId, Supplier<AuthUserSnapshot> loader) {
		return cache.get(userId, ignored -> loader.get());
	}

	@Override
	public void evict(Long userId) {
		cache.invalidate(userId);
	}
}
