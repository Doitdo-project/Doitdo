package com.doitdo.domain.tamagotchi.entity;

import java.io.Serializable;
import java.util.Objects;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
public class CharacterUnlockId implements Serializable {

	private Long userId;
	private Long characterId;

	@Override
	public boolean equals(Object o) {
		if (this == o) return true;
		if (!(o instanceof CharacterUnlockId that)) return false;
		return Objects.equals(userId, that.userId) && Objects.equals(characterId, that.characterId);
	}

	@Override
	public int hashCode() {
		return Objects.hash(userId, characterId);
	}
}
