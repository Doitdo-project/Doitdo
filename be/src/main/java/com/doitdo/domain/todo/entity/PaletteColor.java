package com.doitdo.domain.todo.entity;

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
@Table(name = "palette_colors")
@Builder
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class PaletteColor {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "color_id")
	private Integer colorId;

	@Column(name = "palette_id", nullable = false)
	private Long paletteId;

	@Column(nullable = false, length = 7)
	private String color;

	@Column(name = "color_order", nullable = false)
	private Integer colorOrder;

	public static PaletteColor create(Long paletteId, String color, Integer colorOrder) {
		return PaletteColor.builder()
				.paletteId(paletteId)
				.color(color)
				.colorOrder(colorOrder)
				.build();
	}
}
