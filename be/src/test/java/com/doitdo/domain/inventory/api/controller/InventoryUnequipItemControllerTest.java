package com.doitdo.domain.inventory.api.controller;

import static org.assertj.core.api.Assertions.assertThat;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.doitdo.domain.auth.application.CustomUserDetails;
import com.doitdo.domain.inventory.application.InventoryService;
import com.doitdo.domain.user.entity.User;
import com.doitdo.global.api.response.GlobalApiResponse;

@ExtendWith(MockitoExtension.class)
class InventoryUnequipItemControllerTest {

	@Mock
	private InventoryService inventoryService;

	@Test
	void unequipItemReturnsNoContentResponse() {
		InventoryController controller = new InventoryController(inventoryService);
		CustomUserDetails userDetails = new CustomUserDetails(User.builder()
			.userId(1L)
			.email("user@example.com")
			.username("user")
			.password("password")
			.streakCount(0)
			.isDeleted(false)
			.build());

		GlobalApiResponse<Void> resp = controller.unequipItem(userDetails, 10L, 42L);

		assertThat(resp.getStatus()).isEqualTo(204);
		assertThat(resp.getMessage()).isEqualTo("아이템 해제 완료");
		assertThat(resp.getData()).isNull();
	}
}
