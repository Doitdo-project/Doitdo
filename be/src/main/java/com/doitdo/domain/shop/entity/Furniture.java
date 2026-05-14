package com.doitdo.domain.shop.entity;

import com.doitdo.global.entity.BaseTimeEntity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@Table(
	name = "furnitures",
	indexes = {
		@Index(name = "idx_furnitures_category", columnList = "category")
	}
)
@Builder
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Furniture extends BaseTimeEntity {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "furniture_id")
	private Long furnitureId;

	@Column(nullable = false, unique = true, length = 50)
	private String code;

	@Column(nullable = false, length = 100)
	private String name;

	@Column(length = 255)
	private String description;

	@Column(nullable = false, length = 30)
	private String category;

	@Column(name = "theme_code", length = 30)
	private String themeCode;

	@Column(nullable = false)
	private Integer price;

	@Column(name = "image_url", length = 500)
	private String imageUrl;

	@Column(name = "thumbnail_url", length = 500)
	private String thumbnailUrl;

	@Column(name = "default_x", nullable = false)
	private Integer defaultX;

	@Column(name = "default_y", nullable = false)
	private Integer defaultY;

	@Column(nullable = false)
	private Integer width;

	@Column(nullable = false)
	private Integer height;

	@Column(name = "z_index", nullable = false)
	private Integer zIndex;

	@Column(name = "is_on_sale", nullable = false)
	private Boolean isOnSale;

	@Column(name = "is_deleted", nullable = false)
	private Boolean isDeleted;
}
