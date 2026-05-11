package com.doitdo.domain.shop.entity;

import com.doitdo.global.entity.BaseTimeEntity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
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
	name = "user_furnitures",
	indexes = {
		@Index(name = "idx_user_furnitures_user_id", columnList = "user_id")
	},
	uniqueConstraints = {
		@UniqueConstraint(
			name = "uk_user_furnitures_user_furniture",
			columnNames = {"user_id", "furniture_id"}
		)
	}
)
@Builder
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class UserFurniture extends BaseTimeEntity {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "user_furniture_id")
	private Long userFurnitureId;

	@Column(name = "user_id", nullable = false)
	private Long userId;

	@Column(name = "furniture_id", nullable = false)
	private Long furnitureId;

	public static UserFurniture create(Long userId, Long furnitureId) {
		return UserFurniture.builder()
			.userId(userId)
			.furnitureId(furnitureId)
			.build();
	}
}
