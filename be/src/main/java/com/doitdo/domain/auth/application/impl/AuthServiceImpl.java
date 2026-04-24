package com.doitdo.domain.auth.application.impl;

import com.doitdo.domain.auth.api.dto.req.LoginReq;
import com.doitdo.domain.auth.api.dto.req.RefreshTokenReq;
import com.doitdo.domain.auth.api.dto.req.SignupReq;
import com.doitdo.domain.auth.api.dto.resp.LoginResp;
import com.doitdo.domain.auth.api.dto.resp.SignupResp;
import com.doitdo.domain.auth.api.dto.resp.TokenResp;
import com.doitdo.domain.auth.application.AuthService;
import com.doitdo.domain.auth.application.CustomUserDetails;
import com.doitdo.domain.auth.entity.RefreshToken;
import com.doitdo.domain.auth.repository.RefreshTokenRepository;
import com.doitdo.domain.setting.entity.UserSetting;
import com.doitdo.domain.setting.repository.UserSettingRepository;
import com.doitdo.domain.streak.entity.UserStreak;
import com.doitdo.domain.streak.repository.UserStreakRepository;
import com.doitdo.domain.tamagotchi.entity.Character;
import com.doitdo.domain.tamagotchi.entity.UserCharacter;
import com.doitdo.domain.tamagotchi.repository.CharacterRepository;
import com.doitdo.domain.tamagotchi.repository.UserCharacterRepository;
import com.doitdo.domain.todo.application.DefaultCategoryRegistrar;
import com.doitdo.domain.user.api.dto.resp.UserInfoResp;
import com.doitdo.domain.user.entity.User;
import com.doitdo.domain.user.entity.UserWallet;
import com.doitdo.domain.user.repository.UserRepository;
import com.doitdo.domain.user.repository.UserWalletRepository;
import com.doitdo.global.exception.AuthErrorCode;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.UserErrorCode;
import com.doitdo.global.util.JwtUtil;
import java.time.LocalDateTime;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

	private final UserRepository userRepository;
	private final UserWalletRepository userWalletRepository;
	private final UserSettingRepository userSettingRepository;
	private final UserStreakRepository userStreakRepository;
	private final RefreshTokenRepository refreshTokenRepository;
	private final PasswordEncoder passwordEncoder;
	private final AuthenticationManager authenticationManager;
	private final JwtUtil jwtUtil;
	private final DefaultCategoryRegistrar defaultCategoryRegistrar;
	private final CharacterRepository characterRepository;
	private final UserCharacterRepository userCharacterRepository;

	@Value("${jwt.refresh-token-expiration}")
	private long refreshTokenExpiration;

	@Override
	@Transactional
	public SignupResp signup(SignupReq req) {
		if (userRepository.existsByEmail(req.email())) {
			throw new CustomException(UserErrorCode.U00_001);
		}
		if (userRepository.existsByUsername(req.username())) {
			throw new CustomException(UserErrorCode.U00_004);
		}

		String encodedPassword = passwordEncoder.encode(req.password());
		User user = userRepository.save(User.create(req.email(), encodedPassword, req.username()));

		userWalletRepository.save(UserWallet.create(user.getUserId()));
		userSettingRepository.save(UserSetting.create(user.getUserId()));
		userStreakRepository.save(UserStreak.create(user.getUserId()));
		defaultCategoryRegistrar.registerFor(user.getUserId());

		// 회원가입 직후부터 exp 시스템 대상이 되도록 EGG UserCharacter 자동 생성.
		// 기존 /api/characters/me/egg (receiveEgg) 는 이미 멱등이라 호환성 영향 없음.
		Character eggCharacter = characterRepository
				.findFirstByStageOrderByCharacterIdAsc(Character.Stage.EGG)
				.orElseThrow(() -> new CustomException(UserErrorCode.U00_005));
		userCharacterRepository.save(UserCharacter.builder()
				.userId(user.getUserId())
				.characterId(eggCharacter.getCharacterId())
				.name("뚜잇이")
				.currentExp(0)
				.isActive(true)
				.isDeleted(false)
				.build());

		return new SignupResp(user.getUserId(), user.getEmail(), user.getUsername());
	}

	@Override
	@Transactional
	public LoginResp login(LoginReq req) {
		try {
			Authentication authentication = authenticationManager.authenticate(
					new UsernamePasswordAuthenticationToken(req.username(), req.password())
			);
			CustomUserDetails principal = (CustomUserDetails) authentication.getPrincipal();
			User user = principal.getUser();

			String accessToken = jwtUtil.generateAccessToken(user.getUserId());
			String refreshToken = jwtUtil.generateRefreshToken(user.getUserId());
			saveOrUpdateRefreshToken(user.getUserId(), refreshToken);

			return new LoginResp(accessToken, refreshToken, UserInfoResp.from(user));
		} catch (AuthenticationException e) {
			throw new CustomException(AuthErrorCode.A00_001);
		}
	}

	@Override
	@Transactional
	public TokenResp refresh(RefreshTokenReq req) {
		String refreshToken = req.refreshToken();
		if (!jwtUtil.isValid(refreshToken)) {
			throw new CustomException(AuthErrorCode.A01_001);
		}

		Long userId = jwtUtil.getUserId(refreshToken);
		RefreshToken stored = refreshTokenRepository.findByUserId(userId)
				.orElseThrow(() -> new CustomException(AuthErrorCode.A01_001));

		if (!stored.getToken().equals(refreshToken)) {
			throw new CustomException(AuthErrorCode.A01_001);
		}
		if (stored.getExpiresAt().isBefore(LocalDateTime.now())) {
			throw new CustomException(AuthErrorCode.A01_002);
		}

		String newAccessToken = jwtUtil.generateAccessToken(userId);
		String newRefreshToken = jwtUtil.generateRefreshToken(userId);
		saveOrUpdateRefreshToken(userId, newRefreshToken);

		return new TokenResp(newAccessToken, newRefreshToken);
	}

	@Override
	@Transactional
	public void logout(Long userId) {
		refreshTokenRepository.deleteByUserId(userId);
	}

	private void saveOrUpdateRefreshToken(Long userId, String refreshToken) {
		LocalDateTime expiresAt = LocalDateTime.now().plusNanos(refreshTokenExpiration * 1_000_000L);
		refreshTokenRepository.findByUserId(userId)
				.ifPresentOrElse(
						existing -> existing.update(refreshToken, expiresAt),
						() -> refreshTokenRepository.save(
								RefreshToken.create(userId, refreshToken, expiresAt))
				);
	}
}
