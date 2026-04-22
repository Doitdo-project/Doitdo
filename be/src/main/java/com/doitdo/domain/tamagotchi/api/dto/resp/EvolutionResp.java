package com.doitdo.domain.tamagotchi.api.dto.resp;

public record EvolutionResp(
	Long tamagotchiId,
	String beforeStage,
	String afterStage,
	Integer currentExp,
	Integer requiredExp,
	String animationUrl,
	String characterImageUrl,
	String evolvedAt
) {
}
