package com.doitdo.domain.tamagotchi.api.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.BDDMockito.given;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.doitdo.domain.auth.application.CustomUserDetails;
import com.doitdo.domain.tamagotchi.api.dto.resp.CurrentCharacterResp;
import com.doitdo.domain.tamagotchi.application.TamagotchiService;
import com.doitdo.domain.user.entity.User;
import com.doitdo.global.api.response.GlobalApiResponse;

@ExtendWith(MockitoExtension.class)
class TamagotchiCurrentCharacterControllerTest {

	@Mock
	private TamagotchiService tamagotchiService;

	@Test
	void getCurrentCharacterReturnsGlobalApiResponse() {
		TamagotchiController controller = new TamagotchiController(tamagotchiService);
		CustomUserDetails userDetails = new CustomUserDetails(User.builder()
			.userId(1L)
			.email("user@example.com")
			.username("user")
			.password("password")
			.streakCount(0)
			.isDeleted(false)
			.build());
		CurrentCharacterResp serviceResp = new CurrentCharacterResp(2L, "새싹이", "BABY", 45, 42L, 10L);

		given(tamagotchiService.getCurrentCharacter(1L)).willReturn(serviceResp);

		GlobalApiResponse<CurrentCharacterResp> resp = controller.getCurrentCharacter(userDetails);

		assertThat(resp.getStatus()).isEqualTo(200);
		assertThat(resp.getMessage()).isEqualTo("OK");
		assertThat(resp.getData()).isEqualTo(serviceResp);
	}
}
