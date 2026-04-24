package com.doitdo.domain.tamagotchi.api.dto.resp;

import io.swagger.v3.oas.annotations.media.Schema;

public record CurrentCharacterResp(

	@Schema(description = "원본 캐릭터 식별자(characters.character_id)")
	Long characterId,
	String name,
	String stage,
	String thumbnailUrl,
	@Schema(description = "현재 단계 진행률 0~100 (currentExp * 100 / requiredExp, 파생)")
	Integer growthPercent,
	@Schema(description = "현재 단계에서 누적된 경험치")
	Integer currentExp,
	@Schema(description = "현재 단계 진화에 필요한 경험치 총량")
	Integer requiredExp,
	@Schema(description = "진화 가능 여부 (BABY/TEEN 에서 currentExp >= requiredExp)")
	Boolean canEvolve,
	@Schema(description = "독립(이별) 가능 여부 (ADULT 에서 currentExp >= requiredExp)")
	Boolean canFarewell,
	Long equippedUserItemId,
	@Schema(description = "사용자가 실제로 키우는 현재 활성 다마고치 row 식별자(user_character.user_character_id). M05~M08 path 식별자로 사용")
	Long userCharacterId
) {}
