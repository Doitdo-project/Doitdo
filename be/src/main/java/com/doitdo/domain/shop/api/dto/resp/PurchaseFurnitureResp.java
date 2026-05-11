package com.doitdo.domain.shop.api.dto.resp;

public record PurchaseFurnitureResp(
	Long furnitureId,
	Long userFurnitureId,
	boolean owned,
	boolean soldOut,
	Integer balance
) {
}
