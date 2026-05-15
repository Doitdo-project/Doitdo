package com.doitdo.domain.auth.repository;

import java.time.Duration;
import java.util.Map;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Repository;

/**
 * 비밀번호 재설정 OTP(6자리) 저장소.
 *
 * <p>Redis Hash 자료구조로 저장 — {@code HINCRBY} 가 원자적이므로 동시 시도 카운트 race 가 없다.
 * 키 컨벤션: {@code password-otp:{email}} (소문자 정규화).
 *
 * <ul>
 *   <li>{@code code} — 6자리 OTP 문자열</li>
 *   <li>{@code attempts} — 검증 실패 누적 횟수 (정답 시도 직전까지)</li>
 *   <li>{@code userId} — 발급 시점의 대상 사용자 ID</li>
 * </ul>
 *
 * <p>TTL 은 {@link #save} 호출 시 지정되며 increment 시점에 갱신하지 않는다 — 같은 OTP 세션의
 * 시도 시간 한도를 유지하기 위함.
 */
@Repository
@RequiredArgsConstructor
public class PasswordResetOtpRedisRepository {

	private static final String KEY_PREFIX = "password-otp:";
	private static final String FIELD_CODE = "code";
	private static final String FIELD_ATTEMPTS = "attempts";
	private static final String FIELD_USER_ID = "userId";

	private final StringRedisTemplate redisTemplate;

	public record Otp(String code, int attempts, Long userId) {}

	public void save(String email, String code, Long userId, Duration ttl) {
		String key = buildKey(email);
		redisTemplate.opsForHash().putAll(key, Map.of(
				FIELD_CODE, code,
				FIELD_ATTEMPTS, "0",
				FIELD_USER_ID, String.valueOf(userId)
		));
		redisTemplate.expire(key, ttl);
	}

	public Optional<Otp> find(String email) {
		String key = buildKey(email);
		Map<Object, Object> entries = redisTemplate.opsForHash().entries(key);
		if (entries.isEmpty()) {
			return Optional.empty();
		}
		try {
			String code = (String) entries.get(FIELD_CODE);
			String attemptsStr = (String) entries.get(FIELD_ATTEMPTS);
			String userIdStr = (String) entries.get(FIELD_USER_ID);
			if (code == null || attemptsStr == null || userIdStr == null) {
				return Optional.empty();
			}
			return Optional.of(new Otp(code, Integer.parseInt(attemptsStr), Long.parseLong(userIdStr)));
		} catch (NumberFormatException e) {
			return Optional.empty();
		}
	}

	/**
	 * 실패 시도 카운트 +1. {@code HINCRBY} 라 race-free. 반환값은 증가 후 카운트.
	 */
	public long incrementAttempts(String email) {
		Long next = redisTemplate.opsForHash().increment(buildKey(email), FIELD_ATTEMPTS, 1L);
		return next != null ? next : 0L;
	}

	public void delete(String email) {
		redisTemplate.delete(buildKey(email));
	}

	private String buildKey(String email) {
		return KEY_PREFIX + email.toLowerCase();
	}
}
