package com.doitdo.domain.auth.application.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentCaptor.forClass;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.then;

import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.doitdo.domain.auth.api.dto.resp.OAuthLoginResp;
import com.doitdo.domain.auth.entity.AutoProvider;
import com.doitdo.domain.auth.repository.AutoProviderRepository;
import com.doitdo.domain.auth.repository.RefreshTokenRepository;
import com.doitdo.domain.setting.repository.UserSettingRepository;
import com.doitdo.domain.shop.application.DefaultFurnitureRegistrar;
import com.doitdo.domain.streak.repository.UserStreakRepository;
import com.doitdo.domain.todo.application.DefaultCategoryRegistrar;
import com.doitdo.domain.user.entity.User;
import com.doitdo.domain.user.entity.UserWallet;
import com.doitdo.domain.user.repository.UserRepository;
import com.doitdo.domain.user.repository.UserWalletRepository;
import com.doitdo.global.client.dto.GoogleUserInfo;
import com.doitdo.global.util.JwtUtil;

@ExtendWith(MockitoExtension.class)
class OAuthPersistenceServiceTest {

	@Mock
	private UserRepository userRepository;

	@Mock
	private UserWalletRepository userWalletRepository;

	@Mock
	private UserSettingRepository userSettingRepository;

	@Mock
	private UserStreakRepository userStreakRepository;

	@Mock
	private AutoProviderRepository autoProviderRepository;

	@Mock
	private RefreshTokenRepository refreshTokenRepository;

	@Mock
	private JwtUtil jwtUtil;

	@Mock
	private DefaultCategoryRegistrar defaultCategoryRegistrar;

	@Mock
	private DefaultFurnitureRegistrar defaultFurnitureRegistrar;

	private OAuthPersistenceService buildService() {
		return new OAuthPersistenceService(
				userRepository,
				userWalletRepository,
				userSettingRepository,
				userStreakRepository,
				autoProviderRepository,
				refreshTokenRepository,
				jwtUtil,
				defaultCategoryRegistrar,
				defaultFurnitureRegistrar
		);
	}

	@Test
	void persistGoogleUserCreatesWalletWithInitialCreditForNewUser() {
		OAuthPersistenceService service = buildService();
		GoogleUserInfo googleUser = new GoogleUserInfo(
				"google-sub",
				"user@example.com",
				"user",
				true
		);
		User savedUser = User.builder()
				.userId(1L)
				.email("user@example.com")
				.username("user")
				.password(null)
				.isDeleted(false)
				.build();

		given(autoProviderRepository.findAllByProviderAndProviderUid("GOOGLE", "google-sub"))
				.willReturn(java.util.List.of());
		given(userRepository.findByEmail("user@example.com")).willReturn(Optional.empty());
		given(userRepository.existsByUsername("user")).willReturn(false);
		given(userRepository.save(any(User.class))).willReturn(savedUser);
		given(autoProviderRepository.save(any(AutoProvider.class))).willAnswer(invocation -> invocation.getArgument(0));
		given(jwtUtil.generateAccessToken(1L)).willReturn("access");
		given(jwtUtil.generateRefreshToken(1L)).willReturn("refresh");

		OAuthLoginResp resp = service.persistGoogleUser(googleUser);

		assertThat(resp.isNewUser()).isTrue();
		ArgumentCaptor<UserWallet> walletCaptor = forClass(UserWallet.class);
		then(userWalletRepository).should().save(walletCaptor.capture());
		assertThat(walletCaptor.getValue().getBalance()).isEqualTo(100);
	}
}
