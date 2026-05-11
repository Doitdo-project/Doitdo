package com.doitdo.domain.auth.application.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentCaptor.forClass;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.then;

import java.util.List;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.crypto.password.PasswordEncoder;

import com.doitdo.domain.auth.api.dto.req.SignupReq;
import com.doitdo.domain.auth.api.dto.resp.SignupResp;
import com.doitdo.domain.auth.repository.RefreshTokenRepository;
import com.doitdo.domain.setting.repository.UserSettingRepository;
import com.doitdo.domain.shop.application.DefaultFurnitureRegistrar;
import com.doitdo.domain.streak.repository.UserStreakRepository;
import com.doitdo.domain.tamagotchi.entity.Character;
import com.doitdo.domain.tamagotchi.entity.UserCharacter;
import com.doitdo.domain.tamagotchi.repository.CharacterRepository;
import com.doitdo.domain.tamagotchi.repository.UserCharacterRepository;
import com.doitdo.domain.todo.application.DefaultCategoryRegistrar;
import com.doitdo.domain.user.application.CreditEarnService;
import com.doitdo.domain.user.entity.User;
import com.doitdo.domain.user.entity.UserWallet;
import com.doitdo.domain.user.entity.WalletEarnSource;
import com.doitdo.domain.user.repository.UserRepository;
import com.doitdo.domain.user.repository.UserWalletRepository;
import com.doitdo.global.util.JwtUtil;

@ExtendWith(MockitoExtension.class)
class AuthServiceImplTest {

	@Mock
	private UserRepository userRepository;

	@Mock
	private UserWalletRepository userWalletRepository;

	@Mock
	private UserSettingRepository userSettingRepository;

	@Mock
	private UserStreakRepository userStreakRepository;

	@Mock
	private RefreshTokenRepository refreshTokenRepository;

	@Mock
	private PasswordEncoder passwordEncoder;

	@Mock
	private AuthenticationManager authenticationManager;

	@Mock
	private JwtUtil jwtUtil;

	@Mock
	private DefaultCategoryRegistrar defaultCategoryRegistrar;

	@Mock
	private DefaultFurnitureRegistrar defaultFurnitureRegistrar;

	@Mock
	private CharacterRepository characterRepository;

	@Mock
	private UserCharacterRepository userCharacterRepository;

	@Mock
	private CreditEarnService creditEarnService;

	private AuthServiceImpl buildService() {
		return new AuthServiceImpl(
			userRepository,
			userWalletRepository,
			userSettingRepository,
			userStreakRepository,
			refreshTokenRepository,
			passwordEncoder,
			authenticationManager,
			jwtUtil,
			defaultCategoryRegistrar,
			defaultFurnitureRegistrar,
			characterRepository,
			userCharacterRepository,
			creditEarnService
		);
	}

	private Character defaultEggCharacter() {
		return Character.builder()
			.characterId(26L)
			.species("DUCK")
			.name("오리알")
			.stage(Character.Stage.EGG)
			.requiredExp(0)
			.build();
	}

	@Test
	void signupAssignsRandomEggCharacter() {
		AuthServiceImpl service = buildService();
		User savedUser = User.builder()
			.userId(1L)
			.email("user@example.com")
			.username("user")
			.password("encoded")
			.isDeleted(false)
			.build();

		given(userRepository.existsByEmail("user@example.com")).willReturn(false);
		given(userRepository.existsByUsername("user")).willReturn(false);
		given(passwordEncoder.encode("password123")).willReturn("encoded");
		given(userRepository.save(any(User.class))).willReturn(savedUser);
		given(characterRepository.findAllByStage(Character.Stage.EGG)).willReturn(List.of(defaultEggCharacter()));

		SignupResp resp = service.signup(new SignupReq("user@example.com", "password123", "user"));

		assertThat(resp.birthDateRegistered()).isFalse();
		assertThat(resp.agreementsAccepted()).isFalse();

		ArgumentCaptor<UserWallet> walletCaptor = forClass(UserWallet.class);
		then(userWalletRepository).should().save(walletCaptor.capture());
		assertThat(walletCaptor.getValue().getBalance()).isZero();
		then(creditEarnService).should()
			.tryEarn(1L, WalletEarnSource.SIGNUP_BONUS, 100, null, true);

		ArgumentCaptor<UserCharacter> captor = forClass(UserCharacter.class);
		then(userCharacterRepository).should().save(captor.capture());
		assertThat(captor.getValue().getCharacterId()).isEqualTo(26L);
		then(defaultFurnitureRegistrar).should().registerFor(1L);
	}
}
