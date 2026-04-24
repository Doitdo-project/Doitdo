package com.doitdo.domain.inventory.api.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.BDDMockito.given;

import java.time.LocalDateTime;
import java.util.List;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.doitdo.domain.auth.application.CustomUserDetails;
import com.doitdo.domain.inventory.api.dto.resp.InventoryItemResp;
import com.doitdo.domain.inventory.api.dto.resp.InventoryResp;
import com.doitdo.domain.inventory.application.InventoryService;
import com.doitdo.domain.user.entity.User;
import com.doitdo.global.api.response.GlobalApiResponse;

@ExtendWith(MockitoExtension.class)
class InventoryControllerTest {

	@Mock
	private InventoryService inventoryService;

	@Test
	void getInventoryReturnsGlobalApiResponse() {
		InventoryController controller = new InventoryController(inventoryService);
		CustomUserDetails userDetails = new CustomUserDetails(User.builder()
			.userId(1L)
			.email("user@example.com")
			.username("user")
			.password("password")
			.isDeleted(false)
			.build());
		InventoryResp serviceResp = new InventoryResp(10L, 42L, List.of(
			new InventoryItemResp(
				42L,
				9L,
				"HAT_001",
				"wizard hat",
				"https://cdn.example.com/items/9.png",
				"https://cdn.example.com/items/9_thumb.png",
				LocalDateTime.parse("2026-04-15T10:00:00"),
				true
			)
		));

		given(inventoryService.getInventory(1L, 10L)).willReturn(serviceResp);

		GlobalApiResponse<InventoryResp> resp = controller.getInventory(userDetails, 10L);

		assertThat(resp.getStatus()).isEqualTo(200);
		assertThat(resp.getMessage()).isEqualTo("OK");
		assertThat(resp.getData()).isEqualTo(serviceResp);
	}
}
