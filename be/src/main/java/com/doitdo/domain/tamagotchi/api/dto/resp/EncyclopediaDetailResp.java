package com.doitdo.domain.tamagotchi.api.dto.resp;

public record EncyclopediaDetailResp(

	String species,
	String birthBackground,
	Long encounterCount,
	EncyclopediaDetailCharacterResp baby,
	EncyclopediaDetailCharacterResp teen,
	EncyclopediaDetailCharacterResp adult
) {
}
