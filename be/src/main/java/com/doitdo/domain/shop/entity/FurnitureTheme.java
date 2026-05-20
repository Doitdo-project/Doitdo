package com.doitdo.domain.shop.entity;

import com.doitdo.global.entity.BaseTimeEntity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
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
	name = "furniture_themes",
	indexes = {
		@Index(name = "idx_furniture_themes_active_order", columnList = "is_active, display_order")
	}
)
@Builder
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class FurnitureTheme extends BaseTimeEntity {

	@Id
	@Column(name = "theme_code", length = 30)
	private String themeCode;

	@Column(name = "theme_name", nullable = false, length = 50)
	private String themeName;

	@Column(name = "thumbnail_url", length = 500)
	private String thumbnailUrl;

	@Column(name = "display_order", nullable = false)
	private Integer displayOrder;

	@Column(name = "is_active", nullable = false)
	private Boolean isActive;
}
