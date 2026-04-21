package com.doitdo.domain.tamagotchi.application;

import com.doitdo.domain.tamagotchi.api.dto.resp.EncyclopediaResp;

public interface TamagotchiService {

	EncyclopediaResp getEncyclopedia(Long userId);
}
