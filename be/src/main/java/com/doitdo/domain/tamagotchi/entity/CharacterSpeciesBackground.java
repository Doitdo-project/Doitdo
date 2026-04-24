package com.doitdo.domain.tamagotchi.entity;

import com.doitdo.global.entity.BaseTimeEntity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@Table(name = "character_species_backgrounds")
@Builder
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class CharacterSpeciesBackground extends BaseTimeEntity {

	@Id
	@Column(nullable = false, length = 20)
	private String species;

	@Column(name = "birth_background", nullable = false, columnDefinition = "TEXT")
	private String birthBackground;
}
