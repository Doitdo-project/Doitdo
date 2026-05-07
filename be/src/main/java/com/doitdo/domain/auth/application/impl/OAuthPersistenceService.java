package com.doitdo.domain.auth.application.impl;

import com.doitdo.domain.auth.api.dto.resp.OAuthLoginResp;
import com.doitdo.domain.auth.entity.AutoProvider;
import com.doitdo.domain.auth.entity.OAuthProvider;
import com.doitdo.domain.auth.repository.AutoProviderRepository;
import com.doitdo.domain.auth.repository.RefreshTokenRepository;
import com.doitdo.domain.setting.entity.UserSetting;
import com.doitdo.domain.setting.repository.UserSettingRepository;
import com.doitdo.domain.shop.application.DefaultFurnitureRegistrar;
import com.doitdo.domain.streak.entity.UserStreak;
import com.doitdo.domain.streak.repository.UserStreakRepository;
import com.doitdo.domain.todo.application.DefaultCategoryRegistrar;
import com.doitdo.domain.user.api.dto.resp.UserInfoResp;
import com.doitdo.domain.user.entity.User;
import com.doitdo.domain.user.entity.UserWallet;
import com.doitdo.domain.user.repository.UserRepository;
import com.doitdo.domain.user.repository.UserWalletRepository;
import com.doitdo.global.client.dto.AppleUserInfo;
import com.doitdo.global.client.dto.GoogleUserInfo;
import com.doitdo.global.client.dto.KakaoUserResp;
import com.doitdo.global.exception.AuthErrorCode;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.util.JwtUtil;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * OAuth 로그인의 DB 영속화 책임만 담당하는 서비스.
 *
 * <p>{@link OAuthServiceImpl} 에서 외부 API 호출과 분리되어, 외부 OAuth provider 호출
 * (Kakao/Google/Apple) 이 트랜잭션 외부에서 끝난 뒤 검증된 사용자 정보만 받아 DB 작업을 수행한다.
 *
 * <p>이 분리의 이유:
 * <ul>
 *   <li>외부 API 응답 대기 동안 DB 커넥션을 점유하지 않도록 트랜잭션 범위를 좁힌다</li>
 *   <li>HikariCP 풀이 외부 API 변동성/장애에 영향받지 않도록 격리</li>
 *   <li>회원가입/기존로그인/계정연결/race recovery 등 DB 분기를 한 곳에 모아 가독성 향상</li>
 * </ul>
 *
 * <p>{@link OAuthServiceImpl} 와 다른 빈으로 분리되어야 하는 이유는 Spring AOP 프록시
 * 메커니즘 때문 — 같은 클래스 안에서 self-invocation 으로 {@code @Transactional} 메서드를
 * 호출하면 프록시를 거치지 않아 트랜잭션이 적용되지 않는다.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class OAuthPersistenceService {

	private static final int USERNAME_RETRY_LIMIT = 5;

	private final UserRepository userRepository;
	private final UserWalletRepository userWalletRepository;
	private final UserSettingRepository userSettingRepository;
	private final UserStreakRepository userStreakRepository;
	private final AutoProviderRepository autoProviderRepository;
	private final RefreshTokenRepository refreshTokenRepository;
	private final JwtUtil jwtUtil;
	private final DefaultCategoryRegistrar defaultCategoryRegistrar;
	private final DefaultFurnitureRegistrar defaultFurnitureRegistrar;

	@Value("${jwt.refresh-token-expiration}")
	private long refreshTokenExpiration;

	@Transactional
	public OAuthLoginResp persistKakaoUser(KakaoUserResp kakaoUser) {
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

	@Transactional
	public OAuthLoginResp persistGoogleUser(GoogleUserInfo googleUser) {
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

	@Transactional
	public OAuthLoginResp persistAppleUser(AppleUserInfo appleUser, String appleRefreshToken) {
		String providerName = OAuthProvider.APPLE.name();
		String providerUid = appleUser.sub();

		// 재로그인: 기존 AutoProvider 행의 refresh_token 을 갱신 (Apple 은 매 로그인마다 새 코드 발급).
		Optional<AutoProvider> existingProvider = autoProviderRepository
				.findAllByProviderAndProviderUid(providerName, providerUid)
				.stream()
				.findFirst();
		if (existingProvider.isPresent()) {
			AutoProvider ap = existingProvider.get();
			ap.updateAppleRefreshToken(appleRefreshToken);
			User user = userRepository.findById(ap.getUserId())
					.orElseThrow(() -> new CustomException(AuthErrorCode.A03_004));
			return issueTokens(user, false);
		}

		try {
			return signupWithApple(appleUser, providerName, providerUid, appleRefreshToken);
		} catch (DataIntegrityViolationException e) {
			// race winner 가 만든 row 의 refresh_token 은 그쪽이 받은 값으로 이미 채워졌을 가능성이 큼.
			// 우리가 받은 토큰으로 덮어써도 무방하나, race 빈도가 낮아 단순화 — 다음 로그인에서 자연 갱신.
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
		userWalletRepository.save(UserWallet.createWithInitialCredit(user.getUserId()));
		userSettingRepository.save(UserSetting.create(user.getUserId()));
		userStreakRepository.save(UserStreak.create(user.getUserId()));
		autoProviderRepository.save(AutoProvider.create(user.getUserId(), providerName, providerUid));
		defaultCategoryRegistrar.registerFor(user.getUserId());
		defaultFurnitureRegistrar.registerFor(user.getUserId());

		return issueTokens(user, true);
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
		userWalletRepository.save(UserWallet.createWithInitialCredit(user.getUserId()));
		userSettingRepository.save(UserSetting.create(user.getUserId()));
		userStreakRepository.save(UserStreak.create(user.getUserId()));
		autoProviderRepository.save(AutoProvider.create(user.getUserId(), providerName, providerUid));
		defaultCategoryRegistrar.registerFor(user.getUserId());
		defaultFurnitureRegistrar.registerFor(user.getUserId());

		return issueTokens(user, true);
	}

	/**
	 * Apple 첫 로그인 시에만 identityToken 에 email 이 포함된다(이후 로그인부터는 null).
	 *
	 * <p>또한 사용자가 "내 이메일 가리기" 를 선택하면 {@code @privaterelay.appleid.com} 도메인의
	 * 릴레이 주소가 내려온다 — 우리 서비스에는 이 값을 그대로 저장해 사용한다(Apple 이 실제 주소로 포워딩).
	 *
	 * <p>{@link AppleUserInfo#emailVerified()} 는 Apple 자체 검증을 통과한 경우에만 true 다.
	 *
	 * <p>{@code appleRefreshToken} 은 신규/연결 두 경로 모두 {@link AutoProvider} 에 저장된다 —
	 * 회원탈퇴 시 revoke 호출에 필요.
	 */
	private OAuthLoginResp signupWithApple(
			AppleUserInfo appleUser, String providerName, String providerUid, String appleRefreshToken
	) {
		String email = appleUser.email();
		if (email == null || email.isBlank()) {
			// 첫 로그인이 아니라 sub 만 받은 상태로 신규 가입 경로에 들어왔다면 데이터 부족 → 에러.
			throw new CustomException(AuthErrorCode.A03_001,
					"Apple 계정 이메일이 누락되었습니다. 앱 설정 > Apple ID 사용 중인 앱에서 doitdo 를 제거 후 재시도해주세요.");
		}
		if (!Boolean.TRUE.equals(appleUser.emailVerified())) {
			throw new CustomException(AuthErrorCode.A03_005);
		}

		Optional<OAuthLoginResp> linked = tryLinkExistingAppleAccount(
				email, providerName, providerUid, appleRefreshToken);
		if (linked.isPresent()) {
			return linked.get();
		}

		// Apple 은 이름을 identityToken 에 포함하지 않는다(클라이언트에서 별도 전달 필요).
		// 현재 스키마는 username 만 요구하므로 email local-part 를 기본 닉네임 후보로 사용.
		String baseNickname = email.contains("@") ? email.substring(0, email.indexOf('@')) : email;
		String username = resolveUniqueUsername(baseNickname);

		User user = userRepository.save(User.createOAuthUser(email, username));
		userWalletRepository.save(UserWallet.createWithInitialCredit(user.getUserId()));
		userSettingRepository.save(UserSetting.create(user.getUserId()));
		userStreakRepository.save(UserStreak.create(user.getUserId()));
		autoProviderRepository.save(AutoProvider.createWithRefreshToken(
				user.getUserId(), providerName, providerUid, appleRefreshToken));
		defaultCategoryRegistrar.registerFor(user.getUserId());
		defaultFurnitureRegistrar.registerFor(user.getUserId());

		return issueTokens(user, true);
	}

	/**
	 * Apple 전용 기존 계정 연결. {@link #tryLinkExistingAccount} 와 정책은 동일하지만
	 * {@link AutoProvider} 행에 {@code appleRefreshToken} 까지 함께 저장한다.
	 */
	private Optional<OAuthLoginResp> tryLinkExistingAppleAccount(
			String email, String providerName, String providerUid, String appleRefreshToken
	) {
		Optional<User> existing = userRepository.findByEmail(email);
		if (existing.isEmpty()) {
			return Optional.empty();
		}
		User user = existing.get();
		if (user.getPassword() != null) {
			throw new CustomException(AuthErrorCode.A03_006);
		}
		autoProviderRepository.save(AutoProvider.createWithRefreshToken(
				user.getUserId(), providerName, providerUid, appleRefreshToken));
		return Optional.of(issueTokens(user, false));
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

	/**
	 * refresh_tokens 의 user_id UNIQUE 제약과 native upsert 를 사용해 race-free 갱신.
	 *
	 * <p>이전 구현은 SELECT 후 없으면 INSERT 였는데, 동시 로그인 요청 시 두 트랜잭션이
	 * 모두 empty 를 본 뒤 둘 다 INSERT 에 성공해 user_id 당 row 가 2개로 늘어나는
	 * race 가 있었다(2026-04-29 user_id=8 사고). 다음 호출의 {@code findByUserId}
	 * 가 NonUniqueResultException 으로 500 을 던졌다.
	 */
	private void saveOrUpdateRefreshToken(Long userId, String refreshToken) {
		LocalDateTime expiresAt = LocalDateTime.now().plusNanos(refreshTokenExpiration * 1_000_000L);
		refreshTokenRepository.upsertByUserId(userId, refreshToken, expiresAt);
	}
}
