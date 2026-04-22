package com.doitdo.domain.tamagotchi.api.dto.resp;

import io.swagger.v3.oas.annotations.media.Schema;

public record CurrentCharacterResp(

	@Schema(description = "원본 캐릭터 식별자(characters.character_id)")
	Long characterId,
	String name,
	String stage,
	Integer growthPercent,
	Long equippedUserItemId,
	@Schema(description = "사용자가 실제로 키우는 현재 활성 다마고치 row 식별자(user_character.user_character_id). M05~M08 path 식별자로 사용")
	Long userCharacterId
) {
}
