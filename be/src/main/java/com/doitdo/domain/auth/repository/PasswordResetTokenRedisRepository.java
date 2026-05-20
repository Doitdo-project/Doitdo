package com.doitdo.domain.auth.repository;

import java.time.Duration;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Repository;

/**
 * 비밀번호 재설정 1회용 토큰 저장소.
 *
 * <p>저장 형식: {@code password-reset:{token} -> userId(String)}, TTL 30분(기본). Redis 키 컨벤션은
 * {@link com.doitdo.global.config.RedisConfig} 의 {@code domain:type} 패턴을 따른다.
 *
 * <p>refresh token 은 race 우려와 영구성 때문에 JPA(refresh_tokens 테이블) 를 쓰지만, 비번 재설정 토큰은
 * 짧은 TTL + 일회용 + race 영향 없음 이라 Redis 가 더 적합 (TTL 자동 만료, 일회용은 명시적 delete).
 */
@Repository
@RequiredArgsConstructor
public class PasswordResetTokenRedisRepository {

	private static final String KEY_PREFIX = "password-reset:";

	private final StringRedisTemplate redisTemplate;

	public void save(String token, Long userId, Duration ttl) {
		redisTemplate.opsForValue().set(buildKey(token), String.valueOf(userId), ttl);
	}

	public Optional<Long> findUserIdByToken(String token) {
		String value = redisTemplate.opsForValue().get(buildKey(token));
		if (value == null) {
			return Optional.empty();
		}
		try {
			return Optional.of(Long.parseLong(value));
		} catch (NumberFormatException e) {
			return Optional.empty();
		}
	}

	public void delete(String token) {
		redisTemplate.delete(buildKey(token));
	}

	private String buildKey(String token) {
		return KEY_PREFIX + token;
	}
}
