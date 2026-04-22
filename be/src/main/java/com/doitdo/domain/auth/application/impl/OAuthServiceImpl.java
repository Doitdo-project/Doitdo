package com.doitdo.domain.auth.application.impl;

import com.doitdo.domain.auth.api.dto.resp.OAuthLoginResp;
import com.doitdo.domain.auth.application.OAuthService;
import com.doitdo.domain.auth.entity.AutoProvider;
import com.doitdo.domain.auth.entity.OAuthProvider;
import com.doitdo.domain.auth.entity.RefreshToken;
import com.doitdo.domain.auth.repository.AutoProviderRepository;
import com.doitdo.domain.auth.repository.RefreshTokenRepository;
import com.doitdo.domain.setting.entity.UserSetting;
import com.doitdo.domain.setting.repository.UserSettingRepository;
import com.doitdo.domain.user.api.dto.resp.UserInfoResp;
import com.doitdo.domain.user.entity.User;
import com.doitdo.domain.user.entity.UserWallet;
import com.doitdo.domain.user.repository.UserRepository;
import com.doitdo.domain.user.repository.UserWalletRepository;
import com.doitdo.global.client.GoogleIdTokenVerifierService;
import com.doitdo.global.client.KakaoOAuthClient;
import com.doitdo.global.client.dto.GoogleUserInfo;
import com.doitdo.global.client.dto.KakaoUserResp;
import com.doitdo.global.exception.AuthErrorCode;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.util.JwtUtil;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class OAuthServiceImpl implements OAuthService {

	private static final int USERNAME_RETRY_LIMIT = 5;

	private final KakaoOAuthClient kakaoOAuthClient;
	private final GoogleIdTokenVerifierService googleIdTokenVerifierService;
	private final UserRepository userRepository;
	private final UserWalletRepository userWalletRepository;
	private final UserSettingRepository userSettingRepository;
	private final AutoProviderRepository autoProviderRepository;
	private final RefreshTokenRepository refreshTokenRepository;
	private final JwtUtil jwtUtil;

	@Value("${jwt.refresh-token-expiration}")
	private long refreshTokenExpiration;

	@Override
	@Transactional
	public OAuthLoginResp login(OAuthProvider provider, String accessToken) {
		return switch (provider) {
			case KAKAO -> loginWithKakao(accessToken);
			case GOOGLE -> loginWithGoogle(accessToken);
		};
	}

	private OAuthLoginResp loginWithKakao(String accessToken) {
		KakaoUserResp kakaoUser = kakaoOAuthClient.getUserInfo(accessToken);
		String providerName = OAuthProvider.KAKAO.name();
		String providerUid = String.valueOf(kakaoUser.id());

		Optional<AutoProvider> existing = autoProviderRepository
				.findByProviderAndProviderUid(providerName, providerUid);

		if (existing.isPresent()) {
			User user = userRepository.findById(existing.get().getUserId())
					.orElseThrow(() -> new CustomException(AuthErrorCode.A03_004));
			return issueTokens(user, false);
		}

		return signupWithKakao(kakaoUser, providerName, providerUid);
	}

	private OAuthLoginResp signupWithKakao(KakaoUserResp kakaoUser, String providerName, String providerUid) {
		String email = kakaoUser.email();
		if (email == null || email.isBlank()) {
			throw new CustomException(AuthErrorCode.A03_001,
					"카카오 계정 이메일 동의가 필요합니다.");
		}

		if (userRepository.existsByEmail(email)) {
			throw new CustomException(AuthErrorCode.A03_003);
		}

		String username = resolveUniqueUsername(kakaoUser.nickname());

		User user = userRepository.save(User.createOAuthUser(email, username));
		userWalletRepository.save(UserWallet.create(user.getUserId()));
		userSettingRepository.save(UserSetting.create(user.getUserId()));
		autoProviderRepository.save(AutoProvider.create(user.getUserId(), providerName, providerUid));

		return issueTokens(user, true);
	}

	private OAuthLoginResp loginWithGoogle(String idToken) {
		GoogleUserInfo googleUser = googleIdTokenVerifierService.verify(idToken);
		String providerName = OAuthProvider.GOOGLE.name();
		String providerUid = googleUser.sub();

		Optional<AutoProvider> existing = autoProviderRepository
				.findByProviderAndProviderUid(providerName, providerUid);

		if (existing.isPresent()) {
			User user = userRepository.findById(existing.get().getUserId())
					.orElseThrow(() -> new CustomException(AuthErrorCode.A03_004));
			return issueTokens(user, false);
		}

		return signupWithGoogle(googleUser, providerName, providerUid);
	}

	private OAuthLoginResp signupWithGoogle(GoogleUserInfo googleUser, String providerName, String providerUid) {
		String email = googleUser.email();
		if (email == null || email.isBlank()) {
			throw new CustomException(AuthErrorCode.A03_001,
					"Google 계정 이메일 동의가 필요합니다.");
		}

		if (userRepository.existsByEmail(email)) {
			throw new CustomException(AuthErrorCode.A03_003);
		}

		String username = resolveUniqueUsername(googleUser.name());

		User user = userRepository.save(User.createOAuthUser(email, username));
		userWalletRepository.save(UserWallet.create(user.getUserId()));
		userSettingRepository.save(UserSetting.create(user.getUserId()));
		autoProviderRepository.save(AutoProvider.create(user.getUserId(), providerName, providerUid));

		return issueTokens(user, true);
	}

	private String resolveUniqueUsername(String baseNickname) {
		String base = (baseNickname == null || baseNickname.isBlank())
				? "user"
				: baseNickname;

		if (!userRepository.existsByUsername(base)) {
			return base;
		}

		for (int i = 0; i < USERNAME_RETRY_LIMIT; i++) {
			String candidate = base + "_" + UUID.randomUUID().toString().substring(0, 6);
			if (!userRepository.existsByUsername(candidate)) {
				return candidate;
			}
		}
		throw new CustomException(AuthErrorCode.A03_004, "고유한 username 생성에 실패했습니다.");
	}

	private OAuthLoginResp issueTokens(User user, boolean isNewUser) {
		String accessToken = jwtUtil.generateAccessToken(user.getUserId());
		String refreshToken = jwtUtil.generateRefreshToken(user.getUserId());
		saveOrUpdateRefreshToken(user.getUserId(), refreshToken);
		return new OAuthLoginResp(accessToken, refreshToken, UserInfoResp.from(user), isNewUser);
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
