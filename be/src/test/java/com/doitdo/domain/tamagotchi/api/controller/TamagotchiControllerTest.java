package com.doitdo.domain.tamagotchi.api.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.BDDMockito.given;

import java.util.List;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.doitdo.domain.auth.application.CustomUserDetails;
import com.doitdo.domain.tamagotchi.api.dto.req.ApproveIndependenceReq;
import com.doitdo.domain.tamagotchi.api.dto.req.UpdateCharacterNameReq;
import com.doitdo.domain.tamagotchi.api.dto.resp.CharacterActionUrlResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.CurrentCharacterResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.EncyclopediaDetailCharacterResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.EncyclopediaDetailResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.EncyclopediaItemResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.EncyclopediaResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.EvolutionResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.FarewellResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.HatchCharacterResp;
import com.doitdo.domain.tamagotchi.api.dto.resp.UpdateCharacterNameResp;
import com.doitdo.domain.tamagotchi.application.TamagotchiService;
import com.doitdo.domain.tamagotchi.entity.CharacterActionType;
import com.doitdo.domain.user.entity.User;
import com.doitdo.global.api.response.GlobalApiResponse;

@ExtendWith(MockitoExtension.class)
class TamagotchiControllerTest {

	@Mock
	private TamagotchiService tamagotchiService;

	@Test
	void receiveEggReturnsGlobalApiResponse() {
		TamagotchiController controller = new TamagotchiController(tamagotchiService);
		CustomUserDetails userDetails = new CustomUserDetails(User.builder()
			.userId(1L)
			.email("user@example.com")
			.username("user")
			.password("password")
			.isDeleted(false)
			.build());
		CurrentCharacterResp serviceResp = new CurrentCharacterResp(
			1L,
			null,
			"EGG",
			"https://cdn.example.com/egg.png",
			0,
			0,
			0,
			false,
			false,
			null,
			10L,
			false
		);

		given(tamagotchiService.receiveEgg(1L)).willReturn(serviceResp);

		GlobalApiResponse<CurrentCharacterResp> resp = controller.receiveEgg(userDetails);

		assertThat(resp.getStatus()).isEqualTo(200);
		assertThat(resp.getMessage()).isEqualTo("OK");
		assertThat(resp.getData()).isEqualTo(serviceResp);
	}

	@Test
	void updateCharacterNameReturnsGlobalApiResponse() {
		TamagotchiController controller = new TamagotchiController(tamagotchiService);
		CustomUserDetails userDetails = new CustomUserDetails(User.builder()
			.userId(1L)
			.email("user@example.com")
			.username("user")
			.password("password")
			.isDeleted(false)
			.build());
		UpdateCharacterNameResp serviceResp = new UpdateCharacterNameResp(10L, "rabi");

		given(tamagotchiService.updateName(1L, "rabi")).willReturn(serviceResp);

		GlobalApiResponse<UpdateCharacterNameResp> resp =
			controller.updateName(userDetails, new UpdateCharacterNameReq("rabi"));

		assertThat(resp.getStatus()).isEqualTo(200);
		assertThat(resp.getMessage()).isEqualTo("OK");
		assertThat(resp.getData()).isEqualTo(serviceResp);
	}

	@Test
	void getEncyclopediaReturnsGlobalApiResponse() {
		TamagotchiController controller = new TamagotchiController(tamagotchiService);
		CustomUserDetails userDetails = new CustomUserDetails(User.builder()
			.userId(1L)
			.email("user@example.com")
			.username("user")
			.password("password")
			.isDeleted(false)
			.build());
		EncyclopediaResp serviceResp = new EncyclopediaResp(List.of(
			new EncyclopediaItemResp(1L, "뚜잇", "SLIME", "ADULT", true, "https://cdn.example.com/slime.png")
		));

		given(tamagotchiService.getEncyclopedia(1L)).willReturn(serviceResp);

		GlobalApiResponse<EncyclopediaResp> resp = controller.getEncyclopedia(userDetails);

		assertThat(resp.getStatus()).isEqualTo(200);
		assertThat(resp.getMessage()).isEqualTo("OK");
		assertThat(resp.getData()).isEqualTo(serviceResp);
	}

	@Test
	void getEncyclopediaDetailReturnsGlobalApiResponse() {
		TamagotchiController controller = new TamagotchiController(tamagotchiService);
		CustomUserDetails userDetails = new CustomUserDetails(User.builder()
			.userId(1L)
			.email("user@example.com")
			.username("user")
			.password("password")
			.isDeleted(false)
			.build());
		EncyclopediaDetailResp serviceResp = new EncyclopediaDetailResp(
			"SLIME",
			"진흙에서 태어난 생명체",
			3L,
			new EncyclopediaDetailCharacterResp(1L, "슬라임 베이비", "https://cdn.example.com/slime-baby.png"),
			new EncyclopediaDetailCharacterResp(2L, "슬라임 틴", "https://cdn.example.com/slime-teen.png"),
			new EncyclopediaDetailCharacterResp(3L, "슬라임 어덜트", "https://cdn.example.com/slime-adult.png")
		);

		given(tamagotchiService.getEncyclopediaDetail(1L, "SLIME")).willReturn(serviceResp);

		GlobalApiResponse<EncyclopediaDetailResp> resp = controller.getEncyclopediaDetail(userDetails, "SLIME");

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
			.isDeleted(false)
			.build());
		HatchCharacterResp serviceResp = new HatchCharacterResp(
			2L,
			"BABY",
			"SLIME",
			"https://cdn.example.com/slime.png"
		);

		given(tamagotchiService.hatch(1L)).willReturn(serviceResp);

		GlobalApiResponse<HatchCharacterResp> resp = controller.hatch(userDetails);

		assertThat(resp.getStatus()).isEqualTo(200);
		assertThat(resp.getMessage()).isEqualTo("OK");
		assertThat(resp.getData()).isEqualTo(serviceResp);
	}

	@Test
	void evolveReturnsGlobalApiResponse() {
		TamagotchiController controller = new TamagotchiController(tamagotchiService);
		CustomUserDetails userDetails = new CustomUserDetails(User.builder()
			.userId(1L)
			.email("user@example.com")
			.username("user")
			.password("password")
			.isDeleted(false)
			.build());
		EvolutionResp serviceResp = new EvolutionResp(
			20L,
			"BABY",
			"TEEN",
			120,
			100,
			"https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/evolution/evolution.gif",
			"https://cdn.example.com/slime-teen.png",
			"2026-04-22T10:30:00Z"
		);

		given(tamagotchiService.evolve(1L, 20L)).willReturn(serviceResp);

		GlobalApiResponse<EvolutionResp> resp = controller.evolve(userDetails, 20L);

		assertThat(resp.getStatus()).isEqualTo(200);
		assertThat(resp.getMessage()).isEqualTo("OK");
		assertThat(resp.getData()).isEqualTo(serviceResp);
	}

	@Test
	void approveIndependenceReturnsGlobalApiResponse() {
		TamagotchiController controller = new TamagotchiController(tamagotchiService);
		CustomUserDetails userDetails = new CustomUserDetails(User.builder()
			.userId(1L)
			.email("user@example.com")
			.username("user")
			.password("password")
			.isDeleted(false)
			.build());
		FarewellResp serviceResp = new FarewellResp(
			30L,
			true,
			"EGG",
			"https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/independence/independence.gif"
		);

		given(tamagotchiService.approveIndependence(1L, true)).willReturn(serviceResp);

		GlobalApiResponse<FarewellResp> resp = controller.approveIndependence(userDetails, new ApproveIndependenceReq(true));

		assertThat(resp.getStatus()).isEqualTo(200);
		assertThat(resp.getMessage()).isEqualTo("OK");
		assertThat(resp.getData()).isEqualTo(serviceResp);
	}

	@Test
	void getMyCharacterActionUrlReturnsGlobalApiResponse() {
		TamagotchiController controller = new TamagotchiController(tamagotchiService);
		CustomUserDetails userDetails = new CustomUserDetails(User.builder()
			.userId(1L)
			.email("user@example.com")
			.username("user")
			.password("password")
			.isDeleted(false)
			.build());
		CharacterActionUrlResp serviceResp = new CharacterActionUrlResp(
			"https://cdn.example.com/idle.gif",
			10,
			110
		);

		given(tamagotchiService.getMyCharacterActionUrl(1L, CharacterActionType.IDLE)).willReturn(serviceResp);

		GlobalApiResponse<CharacterActionUrlResp> resp = controller.getMyCharacterActionUrl(CharacterActionType.IDLE, userDetails);

		assertThat(resp.getStatus()).isEqualTo(200);
		assertThat(resp.getMessage()).isEqualTo("OK");
		assertThat(resp.getData()).isEqualTo(serviceResp);
	}
}
