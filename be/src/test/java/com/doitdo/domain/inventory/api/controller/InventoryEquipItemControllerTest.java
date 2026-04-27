package com.doitdo.domain.inventory.api.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.BDDMockito.given;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.doitdo.domain.auth.application.CustomUserDetails;
import com.doitdo.domain.inventory.api.dto.resp.EquipItemResp;
import com.doitdo.domain.inventory.application.InventoryService;
import com.doitdo.domain.user.entity.User;
import com.doitdo.global.api.response.GlobalApiResponse;

@ExtendWith(MockitoExtension.class)
class InventoryEquipItemControllerTest {

	@Mock
	private InventoryService inventoryService;

	@Test
	void equipItemReturnsGlobalApiResponse() {
		InventoryController controller = new InventoryController(inventoryService);
		CustomUserDetails userDetails = new CustomUserDetails(User.builder()
			.userId(1L)
			.email("user@example.com")
			.username("user")
			.password("password")
			.isDeleted(false)
			.build());
		EquipItemResp serviceResp = new EquipItemResp(10L, 42L, 9L, "wizard hat");

		given(inventoryService.equipItem(1L, 10L, 42L)).willReturn(serviceResp);

		GlobalApiResponse<EquipItemResp> resp = controller.equipItem(userDetails, 10L, 42L);

		assertThat(resp.getStatus()).isEqualTo(200);
		assertThat(resp.getMessage()).isEqualTo("아이템 장착 완료");
		assertThat(resp.getData()).isEqualTo(serviceResp);
	}
}
