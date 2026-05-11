package com.doitdo.domain.auth.repository;

import com.doitdo.domain.auth.entity.RefreshToken;
import java.time.LocalDateTime;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface RefreshTokenRepository extends JpaRepository<RefreshToken, Long> {

	/**
	 * {@code findFirstBy...} 를 사용해 DB 에 (이전 race 로 남은) 중복 row 가 있어도
	 * {@code NonUniqueResultException} 을 던지지 않고 첫 row 를 반환한다.
	 * (UNIQUE 제약은 추후 INSERT 부터 보호 — 과거 잔존 dupe 는 hotfix SQL 로 정리.)
	 */
	Optional<RefreshToken> findFirstByUserId(Long userId);

	void deleteByUserId(Long userId);

	/**
	 * user_id UNIQUE 제약을 활용한 단일 SQL upsert.
	 *
	 * <p>기존 SELECT-then-INSERT 방식은 동시 요청 시 둘 다 SELECT 에서 empty 를 받고
	 * 둘 다 INSERT 에 성공하여 중복 row 가 생기는 race 가 있었다. 단일 statement 의
	 * {@code INSERT ... ON DUPLICATE KEY UPDATE} 는 DB 레벨에서 원자적으로 처리되어
	 * race 자체가 발생하지 않는다.
	 */
	@Modifying
	@Query(
		value = "INSERT INTO refresh_tokens (user_id, token, expires_at, created_at) "
				+ "VALUES (:userId, :token, :expiresAt, NOW()) "
				+ "ON DUPLICATE KEY UPDATE "
				+ "  token = VALUES(token), "
				+ "  expires_at = VALUES(expires_at)",
		nativeQuery = true
	)
	void upsertByUserId(
			@Param("userId") Long userId,
			@Param("token") String token,
			@Param("expiresAt") LocalDateTime expiresAt
	);
}
