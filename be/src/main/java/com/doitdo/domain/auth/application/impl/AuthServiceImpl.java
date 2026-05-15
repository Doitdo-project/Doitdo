package com.doitdo.domain.auth.application.impl;

import com.doitdo.domain.auth.api.dto.req.LoginReq;
import com.doitdo.domain.auth.api.dto.req.PasswordResetReq;
import com.doitdo.domain.auth.api.dto.req.PasswordResetRequestReq;
import com.doitdo.domain.auth.api.dto.req.PasswordResetVerifyCodeReq;
import com.doitdo.domain.auth.api.dto.req.RefreshTokenReq;
import com.doitdo.domain.auth.api.dto.req.SignupReq;
import com.doitdo.domain.auth.api.dto.resp.LoginResp;
import com.doitdo.domain.auth.api.dto.resp.PasswordResetVerifyCodeResp;
import com.doitdo.domain.auth.api.dto.resp.SignupResp;
import com.doitdo.domain.auth.api.dto.resp.TokenResp;
import com.doitdo.domain.auth.application.AuthService;
import com.doitdo.domain.auth.application.CustomUserDetails;
import com.doitdo.domain.auth.entity.RefreshToken;
import com.doitdo.domain.auth.repository.PasswordResetOtpRedisRepository;
import com.doitdo.domain.auth.repository.PasswordResetTokenRedisRepository;
import com.doitdo.domain.auth.repository.RefreshTokenRepository;
import com.doitdo.domain.setting.entity.UserSetting;
import com.doitdo.domain.setting.repository.UserSettingRepository;
import com.doitdo.domain.shop.application.DefaultFurnitureRegistrar;
import com.doitdo.domain.streak.entity.UserStreak;
import com.doitdo.domain.streak.repository.UserStreakRepository;
import com.doitdo.domain.tamagotchi.entity.Character;
import com.doitdo.domain.tamagotchi.entity.UserCharacter;
import com.doitdo.domain.tamagotchi.repository.CharacterRepository;
import com.doitdo.domain.tamagotchi.repository.UserCharacterRepository;
import com.doitdo.domain.todo.application.DefaultCategoryRegistrar;
import com.doitdo.domain.todo.application.DefaultTodoRegistrar;
import com.doitdo.domain.user.application.CreditEarnService;
import com.doitdo.domain.user.api.dto.resp.UserInfoResp;
import com.doitdo.domain.user.entity.User;
import com.doitdo.domain.user.entity.UserWallet;
import com.doitdo.domain.user.entity.WalletEarnSource;
import com.doitdo.domain.user.repository.UserRepository;
import com.doitdo.domain.user.repository.UserWalletRepository;
import com.doitdo.domain.user.repository.WalletEarnLogRepository;
import com.doitdo.global.exception.AuthErrorCode;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.UserErrorCode;
import com.doitdo.global.mail.MailService;
import com.doitdo.global.util.JwtUtil;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Base64;
import java.util.List;
import java.util.concurrent.ThreadLocalRandom;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
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
@Slf4j
public class AuthServiceImpl implements AuthService {

	private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

	private static final SecureRandom SECURE_RANDOM = new SecureRandom();
	private static final int RESET_TOKEN_BYTES = 12; // → Base64URL 16자

	private final UserRepository userRepository;
	private final UserWalletRepository userWalletRepository;
	private final UserSettingRepository userSettingRepository;
	private final UserStreakRepository userStreakRepository;
	private final RefreshTokenRepository refreshTokenRepository;
	private final PasswordResetTokenRedisRepository passwordResetTokenRepository;
	private final PasswordResetOtpRedisRepository passwordResetOtpRepository;
	private final WalletEarnLogRepository walletEarnLogRepository;
	private final PasswordEncoder passwordEncoder;
	private final AuthenticationManager authenticationManager;
	private final JwtUtil jwtUtil;
	private final MailService mailService;
	private final DefaultCategoryRegistrar defaultCategoryRegistrar;
	private final DefaultTodoRegistrar defaultTodoRegistrar;
	private final DefaultFurnitureRegistrar defaultFurnitureRegistrar;
	private final CharacterRepository characterRepository;
	private final UserCharacterRepository userCharacterRepository;
	private final CreditEarnService creditEarnService;

	@Value("${jwt.refresh-token-expiration}")
	private long refreshTokenExpiration;

	@Value("${app.password-reset.otp-ttl-minutes}")
	private long otpTtlMinutes;

	@Value("${app.password-reset.reset-token-ttl-minutes}")
	private long resetTokenTtlMinutes;

	@Value("${app.password-reset.max-attempts}")
	private int maxAttempts;

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
		User user = userRepository.save(User.create(
				req.email(),
				encodedPassword,
				req.username()));

		userWalletRepository.save(UserWallet.createEmpty(user.getUserId()));
		creditEarnService.tryEarn(user.getUserId(), WalletEarnSource.SIGNUP_BONUS, 1000, null, true);
		userSettingRepository.save(UserSetting.create(user.getUserId()));
		userStreakRepository.save(UserStreak.create(user.getUserId()));
		defaultCategoryRegistrar.registerFor(user.getUserId());
		defaultTodoRegistrar.registerFor(user.getUserId());
		defaultFurnitureRegistrar.registerFor(user.getUserId());

		// 회원가입 직후부터 exp 시스템 대상이 되도록 EGG UserCharacter 자동 생성.
		// 기존 /api/characters/me/egg (receiveEgg) 는 이미 멱등이라 호환성 영향 없음.
		Character eggCharacter = randomEggCharacter();
		userCharacterRepository.save(UserCharacter.builder()
				.userId(user.getUserId())
				.characterId(eggCharacter.getCharacterId())
				.name("뚜잇이")
				.currentExp(0)
				.isActive(true)
				.isDeleted(false)
				.farewellNotified(false)
				.build());

		log.info("event=USER_SIGNUP userId={}", user.getUserId());

		return new SignupResp(
				user.getUserId(),
				user.getEmail(),
				user.getUsername(),
				user.getBirthDate() != null,
				user.getTermsAgreedAt() != null
		);
	}

	private Character randomEggCharacter() {
		List<Character> eggCharacters = characterRepository.findAllByStage(Character.Stage.EGG);
		if (eggCharacters.isEmpty()) {
			throw new CustomException(UserErrorCode.U00_005);
		}
		return eggCharacters.get(ThreadLocalRandom.current().nextInt(eggCharacters.size()));
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

			log.info("event=LOGIN_SUCCESS userId={}", user.getUserId());

			return new LoginResp(accessToken, refreshToken,
					UserInfoResp.from(user, isAttendanceClaimedToday(user.getUserId())));
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
		RefreshToken stored = refreshTokenRepository.findFirstByUserId(userId)
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

		log.info("event=TOKEN_REFRESH userId={}", userId);

		return new TokenResp(newAccessToken, newRefreshToken);
	}

	@Override
	@Transactional
	public void logout(Long userId) {
		refreshTokenRepository.deleteByUserId(userId);
		log.info("event=LOGOUT userId={}", userId);
	}

	/**
	 * 비밀번호 재설정 요청 — 6자리 OTP 발송.
	 *
	 * <p>응답 정책 (UX 우선 — 한국 모바일 앱 컨벤션 따라 명확한 안내):
	 * <ul>
	 *   <li>일반 가입자 → 200 OK + 메일 발송</li>
	 *   <li>미가입 이메일·탈퇴 사용자 → <b>404 A04-007</b> + 회원가입 안내</li>
	 *   <li>소셜 가입자(password=null) → <b>409 A04-006</b> + 해당 IdP 로그인 안내</li>
	 * </ul>
	 *
	 * <p>탈퇴 사용자는 익명화 처리(이메일/유저네임 marker 치환)되어있어 미가입과 사실상 구분 불가 →
	 * A04-007 로 통합 처리. 같은 이메일에 OTP 가 이미 존재하면 새 OTP 로 덮어쓴다 (재요청 = 무효화 + 재발급).
	 */
	@Override
	public void requestPasswordReset(PasswordResetRequestReq req) {
		User user = userRepository.findByEmail(req.email())
				.filter(u -> !Boolean.TRUE.equals(u.getIsDeleted()))
				.orElseThrow(() -> {
					log.info("event=PASSWORD_RESET_REJECTED reason=NOT_FOUND emailHash={}",
							Integer.toHexString(req.email().hashCode()));
					return new CustomException(AuthErrorCode.A04_007);
				});

		if (user.getPassword() == null) {
			log.info("event=PASSWORD_RESET_REJECTED reason=SOCIAL_ACCOUNT userId={}", user.getUserId());
			throw new CustomException(AuthErrorCode.A04_006);
		}

		String code = generateOtpCode();
		passwordResetOtpRepository.save(
				user.getEmail(),
				code,
				user.getUserId(),
				Duration.ofMinutes(otpTtlMinutes));

		mailService.sendPasswordResetCodeMail(user.getEmail(), code);

		log.info("event=PASSWORD_RESET_REQUESTED userId={}", user.getUserId());
	}

	/**
	 * OTP 6자리 검증 + 짧은 reset 토큰 발급.
	 *
	 * <ul>
	 *   <li>OTP 없음/만료 → 410 A04-001</li>
	 *   <li>code 불일치 → attempts +1 (HINCRBY atomic). max 도달 시 OTP 삭제 + 410 A04-005, 아니면 410 A04-004</li>
	 *   <li>일치 → OTP 삭제 + reset 토큰(12 byte SecureRandom → Base64URL 16자) 발급, Redis TTL 5분</li>
	 * </ul>
	 */
	@Override
	public PasswordResetVerifyCodeResp verifyCode(PasswordResetVerifyCodeReq req) {
		PasswordResetOtpRedisRepository.Otp otp = passwordResetOtpRepository.find(req.email())
				.orElseThrow(() -> new CustomException(AuthErrorCode.A04_001));

		// 이미 max 도달된 상태 — incrementAttempts 가 없을 때도 방어
		if (otp.attempts() >= maxAttempts) {
			passwordResetOtpRepository.delete(req.email());
			throw new CustomException(AuthErrorCode.A04_005);
		}

		if (!otp.code().equals(req.code())) {
			long next = passwordResetOtpRepository.incrementAttempts(req.email());
			if (next >= maxAttempts) {
				passwordResetOtpRepository.delete(req.email());
				log.info("event=PASSWORD_RESET_OTP_LOCKED userId={}", otp.userId());
				throw new CustomException(AuthErrorCode.A04_005);
			}
			throw new CustomException(AuthErrorCode.A04_004);
		}

		passwordResetOtpRepository.delete(req.email());

		String resetToken = generateResetToken();
		passwordResetTokenRepository.save(
				resetToken,
				otp.userId(),
				Duration.ofMinutes(resetTokenTtlMinutes));

		log.info("event=PASSWORD_RESET_OTP_VERIFIED userId={}", otp.userId());
		return new PasswordResetVerifyCodeResp(resetToken);
	}

	/**
	 * reset 토큰 검증 후 새 비밀번호로 변경 + 토큰 소비 + 기존 refresh token 전부 무효화.
	 *
	 * <p>refresh token 무효화로 비번 재설정 직전까지 로그인돼 있던 다른 기기는 토큰 재발급 시 401 을 받게 된다.
	 * (이미 발급된 access token 은 만료(30분) 까지 유효 — JWT 특성상 즉시 차단 불가, 짧은 TTL 로 완화.)
	 */
	@Override
	@Transactional
	public void resetPassword(PasswordResetReq req) {
		Long userId = passwordResetTokenRepository.findUserIdByToken(req.resetToken())
				.orElseThrow(() -> new CustomException(AuthErrorCode.A04_001));

		User user = userRepository.findById(userId)
				.orElseThrow(() -> new CustomException(AuthErrorCode.A04_001));

		if (Boolean.TRUE.equals(user.getIsDeleted()) || user.getPassword() == null) {
			passwordResetTokenRepository.delete(req.resetToken());
			throw new CustomException(AuthErrorCode.A04_001);
		}

		user.updatePassword(passwordEncoder.encode(req.newPassword()));
		passwordResetTokenRepository.delete(req.resetToken());
		refreshTokenRepository.deleteByUserId(userId);

		log.info("event=PASSWORD_RESET_COMPLETED userId={}", userId);
	}

	private String generateOtpCode() {
		return String.format("%06d", SECURE_RANDOM.nextInt(1_000_000));
	}

	private String generateResetToken() {
		byte[] bytes = new byte[RESET_TOKEN_BYTES];
		SECURE_RANDOM.nextBytes(bytes);
		return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
	}

	/**
	 * refresh_tokens 의 user_id UNIQUE 제약과 native upsert 를 사용해 race-free 갱신.
	 * 자세한 배경은 {@code OAuthServiceImpl#saveOrUpdateRefreshToken} 참조.
	 */
	private void saveOrUpdateRefreshToken(Long userId, String refreshToken) {
		LocalDateTime expiresAt = LocalDateTime.now().plusNanos(refreshTokenExpiration * 1_000_000L);
		refreshTokenRepository.upsertByUserId(userId, refreshToken, expiresAt);
	}

	private boolean isAttendanceClaimedToday(Long userId) {
		LocalDate today = LocalDate.now(SEOUL);
		LocalDateTime startOfDay = today.atStartOfDay();
		LocalDateTime endOfDay = today.plusDays(1).atStartOfDay();
		return walletEarnLogRepository.sumAmountByUserIdAndSourceAndDate(
				userId,
				WalletEarnSource.DAILY_ATTENDANCE,
				startOfDay,
				endOfDay
		) > 0;
	}
}
