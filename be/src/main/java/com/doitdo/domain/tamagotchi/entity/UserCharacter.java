package com.doitdo.domain.tamagotchi.entity;

import java.time.LocalDateTime;

import com.doitdo.global.entity.BaseTimeEntity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@Table(name = "user_character")
@Builder
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class UserCharacter extends BaseTimeEntity {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "user_character_id")
	private Long userCharacterId;

	@Column(name = "character_id", nullable = false)
	private Long characterId;

	@Column(name = "equiped_items_id")
	private Long equipedItemsId;

	@Column(name = "user_id", nullable = false)
	private Long userId;

	@Column(length = 50)
	private String name;

	@Column(name = "current_exp", nullable = false)
	private Integer currentExp;

	@Column(name = "is_active", nullable = false)
	private Boolean isActive;

	@Column(name = "is_deleted", nullable = false)
	private Boolean isDeleted;

	@Column(name = "farewell_available_at")
	private LocalDateTime farewellAvailableAt;

	@Builder.Default
	@Column(name = "farewell_notified", nullable = false)
	private Boolean farewellNotified = false;

	public void equipItem(Long userItemId) {
		this.equipedItemsId = userItemId;
	}

	public void unequipItem() {
		this.equipedItemsId = null;
	}

	public void deactivate() {
		this.isActive = false;
	}

	public void setCharacterId(Long characterId) {
		this.characterId = characterId;
	}

	/** 진화/부화/farewell 시 exp 리셋. */
	public void resetExp() {
		this.currentExp = 0;
	}

	/**
	 * 경험치 가산. 현재 단계 상한에서 cap.
	 *
	 * @param delta 가산할 양 (≥0)
	 * @param cap   현재 단계의 requiredExp. null 이면 no-op.
	 */
	public void gainExp(int delta, Integer cap) {
		if (cap == null || delta <= 0) return;
		int next = this.currentExp + delta;
		this.currentExp = Math.min(cap, next);
	}

	public void setName(String name) {
		this.name = name;
	}

	public void scheduleFarewell(LocalDateTime availableAt) {
		if (this.farewellAvailableAt != null) {
			return;
		}
		this.farewellAvailableAt = availableAt;
	}

	public void markFarewellNotified() {
		if (Boolean.TRUE.equals(this.farewellNotified)) {
			return;
		}
		this.farewellNotified = true;
	}
}
