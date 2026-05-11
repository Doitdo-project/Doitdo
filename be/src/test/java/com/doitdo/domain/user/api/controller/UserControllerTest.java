package com.doitdo.domain.user.api.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.BDDMockito.given;

import com.doitdo.domain.auth.application.CustomUserDetails;
import com.doitdo.domain.user.api.dto.resp.WalletBalanceResp;
import com.doitdo.domain.user.application.UserService;
import com.doitdo.domain.user.entity.User;
import com.doitdo.global.api.response.GlobalApiResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class UserControllerTest {

	@Mock
	private UserService userService;

	private UserController controller;
	private CustomUserDetails userDetails;

	@BeforeEach
	void setUp() {
		controller = new UserController(userService);
		User user = User.builder()
				.userId(1L)
				.email("test@example.com")
				.username("testuser")
				.password("password")
				.isDeleted(false)
				.build();
		userDetails = new CustomUserDetails(user);
	}

	@Test
	void getMyBalance_returnsWalletBalance() {
		given(userService.getMyBalance(1L)).willReturn(new WalletBalanceResp(100));

		GlobalApiResponse<WalletBalanceResp> response = controller.getMyBalance(userDetails);

		assertThat(response.getStatus()).isEqualTo(200);
		assertThat(response.getData().balance()).isEqualTo(100);
	}
}
