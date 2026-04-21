package com.doitdo.domain.tamagotchi.application;

import com.doitdo.domain.tamagotchi.api.dto.resp.EncyclopediaResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.CurrentCharacterResp;

public interface TamagotchiService {

	EncyclopediaResp getEncyclopedia(Long userId);

	CurrentCharacterResp getCurrentCharacter(Long userId);
}
