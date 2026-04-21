package com.doitdo.domain.tamagotchi.entity;

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

	@Column(name = "growth_percent", nullable = false)
	private Integer growthPercent;

	@Column(name = "is_active", nullable = false)
	private Boolean isActive;

	@Column(name = "is_deleted", nullable = false)
	private Boolean isDeleted;

	public void equipItem(Long userItemId) {
		this.equipedItemsId = userItemId;
	}

	public void unequipItem() {
		this.equipedItemsId = null;
	}
}
