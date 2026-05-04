package com.doitdo.domain.shop.entity;

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
@Table(name = "room_furniture_placements")
@Builder
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class RoomFurniturePlacement extends BaseTimeEntity {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "placement_id")
	private Long placementId;

	@Column(name = "user_id", nullable = false)
	private Long userId;

	@Column(name = "user_furniture_id", nullable = false)
	private Long userFurnitureId;

	@Column(nullable = false)
	private Integer x;

	@Column(nullable = false)
	private Integer y;

	@Column(name = "z_index", nullable = false)
	private Integer zIndex;

	@Column(nullable = false)
	private Integer rotation;

	public static RoomFurniturePlacement create(Long userId, Long userFurnitureId, Furniture furniture) {
		return RoomFurniturePlacement.builder()
			.userId(userId)
			.userFurnitureId(userFurnitureId)
			.x(furniture.getDefaultX())
			.y(furniture.getDefaultY())
			.zIndex(furniture.getZIndex())
			.rotation(0)
			.build();
	}

	public void updatePosition(Integer x, Integer y, Integer zIndex, Integer rotation) {
		this.x = x;
		this.y = y;
		this.zIndex = zIndex;
		this.rotation = rotation;
	}
}
