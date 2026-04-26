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
	name = "auto_providers",
	uniqueConstraints = {
		@UniqueConstraint(
			name = "uk_provider_uid",
			columnNames = {"provider", "provider_uid"}
		)
	}
)
@EntityListeners(AuditingEntityListener.class)
@Builder
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class AutoProvider {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "provider_id")
	private Long providerId;

	@Column(name = "user_id", nullable = false)
	private Long userId;

	@Column(nullable = false, length = 20)
	private String provider;

	@Column(name = "provider_uid", nullable = false, length = 255)
	private String providerUid;

	/**
	 * Apple 전용 — 회원탈퇴 시 Apple {@code /auth/revoke} 호출에 사용.
	 *
	 * <p>KAKAO/GOOGLE 행에서는 항상 null. Apple 도 첫 로그인 시 authorizationCode 교환에 실패하면
	 * 저장 못 할 수 있으나, 현재 정책상 authorizationCode 누락은 로그인 자체를 거절(A03-002)하므로
	 * APPLE 행은 정상 흐름에서 항상 값이 채워진다.
	 *
	 * <p>Apple refresh_token 은 보통 짧지만 안전 마진 두고 512 자.
	 */
	@Column(name = "apple_refresh_token", length = 512)
	private String appleRefreshToken;

	@CreatedDate
	@Column(name = "linked_at", nullable = false, updatable = false)
	private LocalDateTime linkedAt;

	public static AutoProvider create(Long userId, String provider, String providerUid) {
		return AutoProvider.builder()
				.userId(userId)
				.provider(provider)
				.providerUid(providerUid)
				.build();
	}

	public static AutoProvider createWithRefreshToken(
			Long userId, String provider, String providerUid, String appleRefreshToken
	) {
		return AutoProvider.builder()
				.userId(userId)
				.provider(provider)
				.providerUid(providerUid)
				.appleRefreshToken(appleRefreshToken)
				.build();
	}

	/**
	 * 재로그인 시 Apple 이 새 refresh_token 을 발급하면 갱신.
	 *
	 * <p>{@code newToken} 이 null/blank 면 기존 값을 보존(=apple 응답에 refresh_token 누락 시 우리 DB 값 유지).
	 */
	public void updateAppleRefreshToken(String newToken) {
		if (newToken != null && !newToken.isBlank()) {
			this.appleRefreshToken = newToken;
		}
	}
}
