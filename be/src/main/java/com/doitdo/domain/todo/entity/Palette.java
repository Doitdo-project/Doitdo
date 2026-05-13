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
@Table(name = "palettes")
@Builder
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Palette {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "palette_id")
	private Long paletteId;

	@Column(name = "palette_name", nullable = false, length = 20)
	private String paletteName;

	/**
	 * 표시 순서 (낮은 값이 먼저). 시드 코드의 리스트 순서가 SSOT.
	 * paletteId(INSERT 순서) 와 별도로 두는 이유: 기존 운영 DB 에서 palette_id 는
	 * 이미 고정인 채로 운영자가 임의로 순서만 바꾸고 싶을 때 ALTER 없이 UPDATE 한 줄로 끝나도록.
	 */
	@Column(name = "display_order", nullable = false)
	private Integer displayOrder;

	public static Palette create(String paletteName, Integer displayOrder) {
		return Palette.builder()
				.paletteName(paletteName)
				.displayOrder(displayOrder)
				.build();
	}

	public void updateDisplayOrder(Integer displayOrder) {
		this.displayOrder = displayOrder;
	}
}
