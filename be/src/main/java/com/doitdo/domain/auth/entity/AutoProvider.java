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
}
