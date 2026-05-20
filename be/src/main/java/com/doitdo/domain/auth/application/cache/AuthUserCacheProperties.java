package com.doitdo.domain.auth.application.cache;

import java.time.Duration;
import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Getter
@Setter
@Component
@ConfigurationProperties(prefix = "auth.user-cache")
public class AuthUserCacheProperties {

	private Provider provider = Provider.NONE;
	private Duration ttl = Duration.ofSeconds(60);
	private long maxSize = 10_000L;

	public enum Provider {
		NONE,
		REDIS,
		CAFFEINE
	}
}
