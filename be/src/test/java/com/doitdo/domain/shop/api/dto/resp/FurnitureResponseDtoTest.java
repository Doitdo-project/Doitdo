package com.doitdo.domain.shop.api.dto.resp;

import static org.assertj.core.api.Assertions.assertThat;

import java.lang.reflect.RecordComponent;
import java.util.Arrays;

import org.junit.jupiter.api.Test;

class FurnitureResponseDtoTest {

	@Test
	void shopFurnitureItemResponse_doesNotExposeDefaultCoordinates() {
		assertThat(recordComponentNames(FurnitureShopItemResp.class))
			.doesNotContain("defaultX", "defaultY");
	}

	@Test
	void userFurnitureItemResponse_doesNotExposeDefaultCoordinates() {
		assertThat(recordComponentNames(UserFurnitureItemResp.class))
			.doesNotContain("defaultX", "defaultY");
	}

	@Test
	void roomFurniturePlacementResponse_doesNotExposeCoordinates() {
		assertThat(recordComponentNames(RoomFurniturePlacementResp.class))
			.doesNotContain("x", "y");
	}

	private String[] recordComponentNames(Class<? extends Record> recordType) {
		return Arrays.stream(recordType.getRecordComponents())
			.map(RecordComponent::getName)
			.toArray(String[]::new);
	}
}
