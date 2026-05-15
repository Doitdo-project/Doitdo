package com.doitdo.domain.auth.application.cache;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.function.Supplier;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

@Slf4j
@Component
@ConditionalOnProperty(name = "auth.user-cache.provider", havingValue = "redis")
public class RedisAuthUserCacheProvider implements AuthUserCacheProvider {

	private static final String KEY_PREFIX = "auth:user::";

	private final StringRedisTemplate redisTemplate;
	private final ObjectMapper objectMapper;
	private final AuthUserCacheProperties properties;

	public RedisAuthUserCacheProvider(
			StringRedisTemplate redisTemplate,
			ObjectMapper objectMapper,
			AuthUserCacheProperties properties) {
		this.redisTemplate = redisTemplate;
		this.objectMapper = objectMapper;
		this.properties = properties;
	}

	@Override
	public AuthUserSnapshot get(Long userId, Supplier<AuthUserSnapshot> loader) {
		String key = key(userId);
		try {
			String cached = redisTemplate.opsForValue().get(key);
			if (StringUtils.hasText(cached)) {
				return objectMapper.readValue(cached, AuthUserSnapshot.class);
			}
		} catch (RuntimeException | JsonProcessingException ex) {
			log.warn("auth user redis cache read failed userId={}", userId, ex);
		}

		AuthUserSnapshot loaded = loader.get();
		try {
			redisTemplate.opsForValue().set(key, objectMapper.writeValueAsString(loaded), properties.getTtl());
		} catch (RuntimeException | JsonProcessingException ex) {
			log.warn("auth user redis cache write failed userId={}", userId, ex);
		}
		return loaded;
	}

	@Override
	public void evict(Long userId) {
		try {
			redisTemplate.delete(key(userId));
		} catch (RuntimeException ex) {
			log.warn("auth user redis cache evict failed userId={}", userId, ex);
		}
	}

	private String key(Long userId) {
		return KEY_PREFIX + userId;
	}
}
