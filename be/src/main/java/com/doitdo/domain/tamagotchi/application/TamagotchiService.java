package com.doitdo.domain.tamagotchi.application;

import com.doitdo.domain.tamagotchi.api.dto.resp.EncyclopediaResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.CurrentCharacterResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.HatchCharacterResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.EvolutionResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.FarewellResp;

public interface TamagotchiService {

	EncyclopediaResp getEncyclopedia(Long userId);

	CurrentCharacterResp getCurrentCharacter(Long userId);

	HatchCharacterResp hatch(Long userId);

	EvolutionResp evolve(Long userId, Long userCharacterId);

	FarewellResp approveIndependence(Long userId, Boolean approved);
}
