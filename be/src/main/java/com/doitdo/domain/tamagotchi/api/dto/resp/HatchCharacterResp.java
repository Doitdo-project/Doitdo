package com.doitdo.domain.tamagotchi.api.dto.resp;

public record HatchCharacterResp(
	Long characterId,
	String stage,
	String name,
	String thumbnailUrl
) {
}
