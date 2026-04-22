package com.doitdo.domain.tamagotchi.api.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.BDDMockito.given;

import java.util.List;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.doitdo.domain.auth.application.CustomUserDetails;
import com.doitdo.domain.tamagotchi.api.dto.resp.CurrentCharacterResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.EncyclopediaItemResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.EncyclopediaResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.HatchCharacterResp;
import com.doitdo.domain.tamagotchi.application.TamagotchiService;
import com.doitdo.domain.user.entity.User;
import com.doitdo.global.api.response.GlobalApiResponse;

@ExtendWith(MockitoExtension.class)
class TamagotchiControllerTest {

	@Mock
	private TamagotchiService tamagotchiService;

	@Test
	void getEncyclopediaReturnsGlobalApiResponse() {
		TamagotchiController controller = new TamagotchiController(tamagotchiService);
		CustomUserDetails userDetails = new CustomUserDetails(User.builder()
			.userId(1L)
			.email("user@example.com")
			.username("user")
			.password("password")
			.streakCount(0)
			.isDeleted(false)
			.build());
		EncyclopediaResp serviceResp = new EncyclopediaResp(List.of(
			new EncyclopediaItemResp(1L, "SLIME", "BABY", true, "https://cdn.example.com/slime.png")
		));

		given(tamagotchiService.getEncyclopedia(1L)).willReturn(serviceResp);

		GlobalApiResponse<EncyclopediaResp> resp = controller.getEncyclopedia(userDetails);

		assertThat(resp.getStatus()).isEqualTo(200);
		assertThat(resp.getMessage()).isEqualTo("OK");
		assertThat(resp.getData()).isEqualTo(serviceResp);
	}

	@Test
	void hatchReturnsGlobalApiResponse() {
		TamagotchiController controller = new TamagotchiController(tamagotchiService);
		CustomUserDetails userDetails = new CustomUserDetails(User.builder()
			.userId(1L)
			.email("user@example.com")
			.username("user")
			.password("password")
			.streakCount(0)
			.isDeleted(false)
			.build());
		HatchCharacterResp serviceResp = new HatchCharacterResp(2L, "BABY", "SLIME");

		given(tamagotchiService.hatch(1L)).willReturn(serviceResp);

		GlobalApiResponse<HatchCharacterResp> resp = controller.hatch(userDetails);

		assertThat(resp.getStatus()).isEqualTo(200);
		assertThat(resp.getMessage()).isEqualTo("OK");
		assertThat(resp.getData()).isEqualTo(serviceResp);
	}
}
