package com.doitdo.domain.tamagotchi.api.dto.resp;

public record EncyclopediaItemResp(

	Long characterId,
	String species,
	String stage,
	Boolean unlocked,
	String thumbnailUrl
) {
}
