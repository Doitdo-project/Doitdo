package com.doitdo.domain.tamagotchi.entity;

import java.util.Locale;

public enum CharacterActionType {
	EYE,
	IDLE,
	WALK,
	SLEEP,
	HAPPY,
	SAD,
	POOP;

	public boolean matches(String value) {
		return value != null && name().equals(value.toUpperCase(Locale.ROOT));
	}
}
