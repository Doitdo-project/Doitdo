package com.doitdo.domain.tamagotchi.api.dto.resp;

public record FarewellResp(
	Long farewellId,
	boolean nextCharacterAssigned,
	String nextCharacterStage,
	String animationUrl
) {
}
