package com.doitdo.domain.tamagotchi.application;

import com.doitdo.domain.tamagotchi.api.dto.resp.EncyclopediaResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.CurrentCharacterResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.HatchCharacterResp;

public interface TamagotchiService {

	EncyclopediaResp getEncyclopedia(Long userId);

	CurrentCharacterResp getCurrentCharacter(Long userId);

	HatchCharacterResp hatch(Long userId);
}
