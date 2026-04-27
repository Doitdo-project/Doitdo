package com.doitdo.domain.tamagotchi.api.dto.resp;

import java.util.List;

public record EncyclopediaResp(

	List<EncyclopediaItemResp> items
) {
}
