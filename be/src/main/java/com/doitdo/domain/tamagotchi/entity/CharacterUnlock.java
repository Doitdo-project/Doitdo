package com.doitdo.domain.tamagotchi.entity;

import java.time.LocalDateTime;

import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@Table(name = "character_unlocks")
@IdClass(CharacterUnlockId.class)
@EntityListeners(AuditingEntityListener.class)
@Builder
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class CharacterUnlock {

	@Id
	@Column(name = "user_id")
	private Long userId;

	@Id
	@Column(name = "character_id")
	private Long characterId;

	@CreatedDate
	@Column(name = "unlocked_at", nullable = false, updatable = false)
	private LocalDateTime unlockedAt;
}
