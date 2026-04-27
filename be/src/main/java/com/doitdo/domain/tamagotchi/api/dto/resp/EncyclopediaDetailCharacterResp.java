package com.doitdo.domain.tamagotchi.api.dto.resp;

public record EncyclopediaDetailCharacterResp(

	Long characterId,
	String name,
	String thumbnailUrl
) {
}
