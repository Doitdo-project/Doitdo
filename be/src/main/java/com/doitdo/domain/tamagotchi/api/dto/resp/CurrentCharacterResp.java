package com.doitdo.domain.tamagotchi.api.dto.resp;

public record CurrentCharacterResp(

	Long characterId,
	String name,
	String stage,
	Integer growthPercent,
	Long equippedUserItemId
) {
}
