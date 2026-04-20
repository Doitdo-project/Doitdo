package com.doitdo.global.util;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import javax.crypto.SecretKey;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class JwtUtil {

	private final SecretKey secretKey;
	private final long accessTokenExpiration;
	private final long refreshTokenExpiration;

	public JwtUtil(
			@Value("${jwt.secret}") String secret,
			@Value("${jwt.access-token-expiration}") long accessTokenExpiration,
			@Value("${jwt.refresh-token-expiration}") long refreshTokenExpiration) {
		this.secretKey = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
		this.accessTokenExpiration = accessTokenExpiration;
		this.refreshTokenExpiration = refreshTokenExpiration;
	}

	public String generateAccessToken(Long userId) {
		return buildToken(userId, accessTokenExpiration);
	}

	public String generateRefreshToken(Long userId) {
		return buildToken(userId, refreshTokenExpiration);
	}

	public Long getUserId(String token) {
		return Long.parseLong(getClaims(token).getSubject());
	}

	public boolean isValid(String token) {
		try {
			getClaims(token);
			return true;
		} catch (JwtException | IllegalArgumentException e) {
			return false;
		}
	}

	private String buildToken(Long userId, long expiration) {
		Date now = new Date();
		return Jwts.builder()
				.subject(String.valueOf(userId))
				.issuedAt(now)
				.expiration(new Date(now.getTime() + expiration))
				.signWith(secretKey)
				.compact();
	}

	private Claims getClaims(String token) {
		return Jwts.parser()
				.verifyWith(secretKey)
				.build()
				.parseSignedClaims(token)
				.getPayload();
	}
}
