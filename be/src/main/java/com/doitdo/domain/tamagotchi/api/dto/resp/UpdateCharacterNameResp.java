package com.doitdo.domain.tamagotchi.api.dto.resp;

public record UpdateCharacterNameResp(
	Long characterId,
	String name
) {
}
