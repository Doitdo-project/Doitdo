package com.doitdo.domain.inventory.api.dto.resp;

import java.time.LocalDateTime;

public record InventoryItemResp(

	Long userItemId,
	Long itemId,
	String code,
	String name,
	String imgUrl,
	String thumbnailUrl,
	LocalDateTime acquiredAt,
	Boolean equipped
) {
}
