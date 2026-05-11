package com.doitdo.domain.auth.entity;

import java.time.LocalDateTime;

import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@Table(
	name = "refresh_tokens",
	uniqueConstraints = {
		@UniqueConstraint(name = "uk_user_id", columnNames = "user_id")
	}
)
@EntityListeners(AuditingEntityListener.class)
@Builder
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class RefreshToken {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "token_id")
	private Long tokenId;

	@Column(name = "user_id", nullable = false)
	private Long userId;

	@Column(nullable = false, length = 512)
	private String token;

	@CreatedDate
	@Column(name = "created_at", nullable = false, updatable = false)
	private LocalDateTime createdAt;

	@Column(name = "expires_at", nullable = false)
	private LocalDateTime expiresAt;

	public static RefreshToken create(Long userId, String token, LocalDateTime expiresAt) {
		return RefreshToken.builder()
				.userId(userId)
				.token(token)
				.expiresAt(expiresAt)
				.build();
	}

	public void update(String token, LocalDateTime expiresAt) {
		this.token = token;
		this.expiresAt = expiresAt;
	}
}
