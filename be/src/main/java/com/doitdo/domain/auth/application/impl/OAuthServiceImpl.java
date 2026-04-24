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
import com.doitdo.domain.streak.entity.UserStreak;
import com.doitdo.domain.streak.repository.UserStreakRepository;
import com.doitdo.domain.todo.application.DefaultCategoryRegistrar;
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
import org.springframework.dao.DataIntegrityViolationException;
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
	private final UserStreakRepository userStreakRepository;
	private final AutoProviderRepository autoProviderRepository;
	private final RefreshTokenRepository refreshTokenRepository;
	private final JwtUtil jwtUtil;
	private final DefaultCategoryRegistrar defaultCategoryRegistrar;

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

		Optional<User> existingUser = findUserByProvider(providerName, providerUid);
		if (existingUser.isPresent()) {
			return issueTokens(existingUser.get(), false);
		}

		try {
			return signupWithKakao(kakaoUser, providerName, providerUid);
		} catch (DataIntegrityViolationException e) {
			return recoverFromRace(providerName, providerUid);
		}
	}

	private OAuthLoginResp signupWithKakao(KakaoUserResp kakaoUser, String providerName, String providerUid) {
		if (!kakaoUser.isEmailTrusted()) {
			throw new CustomException(AuthErrorCode.A03_005);
		}
		String email = kakaoUser.email();
		if (email == null || email.isBlank()) {
			throw new CustomException(AuthErrorCode.A03_001,
					"카카오 계정 이메일 동의가 필요합니다.");
		}

		Optional<OAuthLoginResp> linked = tryLinkExistingAccount(email, providerName, providerUid);
		if (linked.isPresent()) {
			return linked.get();
		}

		String username = resolveUniqueUsername(kakaoUser.nickname());

		User user = userRepository.save(User.createOAuthUser(email, username));
		userWalletRepository.save(UserWallet.create(user.getUserId()));
		userSettingRepository.save(UserSetting.create(user.getUserId()));
		userStreakRepository.save(UserStreak.create(user.getUserId()));
		autoProviderRepository.save(AutoProvider.create(user.getUserId(), providerName, providerUid));
		defaultCategoryRegistrar.registerFor(user.getUserId());

		return issueTokens(user, true);
	}

	private OAuthLoginResp loginWithGoogle(String idToken) {
		GoogleUserInfo googleUser = googleIdTokenVerifierService.verify(idToken);
		String providerName = OAuthProvider.GOOGLE.name();
		String providerUid = googleUser.sub();

		Optional<User> existingUser = findUserByProvider(providerName, providerUid);
		if (existingUser.isPresent()) {
			return issueTokens(existingUser.get(), false);
		}

		try {
			return signupWithGoogle(googleUser, providerName, providerUid);
		} catch (DataIntegrityViolationException e) {
			return recoverFromRace(providerName, providerUid);
		}
	}

	private OAuthLoginResp signupWithGoogle(GoogleUserInfo googleUser, String providerName, String providerUid) {
		if (!Boolean.TRUE.equals(googleUser.emailVerified())) {
			throw new CustomException(AuthErrorCode.A03_005);
		}
		String email = googleUser.email();
		if (email == null || email.isBlank()) {
			throw new CustomException(AuthErrorCode.A03_001,
					"Google 계정 이메일 동의가 필요합니다.");
		}

		Optional<OAuthLoginResp> linked = tryLinkExistingAccount(email, providerName, providerUid);
		if (linked.isPresent()) {
			return linked.get();
		}

		String username = resolveUniqueUsername(googleUser.name());

		User user = userRepository.save(User.createOAuthUser(email, username));
		userWalletRepository.save(UserWallet.create(user.getUserId()));
		userSettingRepository.save(UserSetting.create(user.getUserId()));
		userStreakRepository.save(UserStreak.create(user.getUserId()));
		autoProviderRepository.save(AutoProvider.create(user.getUserId(), providerName, providerUid));
		defaultCategoryRegistrar.registerFor(user.getUserId());

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

	/**
	 * 이미 같은 이메일로 가입된 user 가 있으면 정책에 따라 연결 처리.
	 *
	 * <ul>
	 *   <li>기존 user 가 소셜 가입자({@code password == null}): 현재 provider 의 {@link AutoProvider}
	 *       를 추가 연결하고 기존 user 로 로그인 처리 → {@code Optional<OAuthLoginResp>} 반환</li>
	 *   <li>기존 user 가 일반 회원가입자({@code password != null}): 자동 연결 거부 →
	 *       {@link AuthErrorCode#A03_006} 예외 throw (비밀번호 우회 방지)</li>
	 *   <li>기존 user 없음: {@link Optional#empty()} 반환 → 호출자가 신규 가입 계속 진행</li>
	 * </ul>
	 *
	 * <p>호출 전 반드시 이메일이 Provider 에 의해 검증됐음(email_verified=true)을 확인해야 한다.
	 */
	private Optional<OAuthLoginResp> tryLinkExistingAccount(
			String email, String providerName, String providerUid
	) {
		Optional<User> existing = userRepository.findByEmail(email);
		if (existing.isEmpty()) {
			return Optional.empty();
		}
		User user = existing.get();
		if (user.getPassword() != null) {
			throw new CustomException(AuthErrorCode.A03_006);
		}
		autoProviderRepository.save(AutoProvider.create(user.getUserId(), providerName, providerUid));
		return Optional.of(issueTokens(user, false));
	}

	/**
	 * provider + providerUid 로 기존 user 를 조회.
	 *
	 * <p>{@code findAllBy...} 를 사용해 DB 에 이미 중복 row 가 남아 있어도
	 * {@code NonUniqueResultException} 을 던지지 않고 첫 번째 winner 를 선택한다.
	 */
	private Optional<User> findUserByProvider(String providerName, String providerUid) {
		return autoProviderRepository
				.findAllByProviderAndProviderUid(providerName, providerUid)
				.stream()
				.findFirst()
				.map(ap -> userRepository.findById(ap.getUserId())
						.orElseThrow(() -> new CustomException(AuthErrorCode.A03_004)));
	}

	/**
	 * 신규 가입 경로에서 DB UNIQUE 제약 위반이 발생한 경우 복구 처리.
	 *
	 * <p>동시 요청 race condition 의 winner row 가 존재하면 해당 user 로 기존 로그인 처리.
	 * winner 가 없으면(= 진짜 다른 provider 로 이미 가입된 이메일) A03_003 를 그대로 던진다.
	 */
	private OAuthLoginResp recoverFromRace(String providerName, String providerUid) {
		User user = findUserByProvider(providerName, providerUid)
				.orElseThrow(() -> new CustomException(AuthErrorCode.A03_003));
		return issueTokens(user, false);
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
