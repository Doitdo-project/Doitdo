package com.doitdo.integration;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.doitdo.domain.user.application.CreditEarnService;
import com.doitdo.domain.user.entity.User;
import com.doitdo.domain.user.entity.UserWallet;
import com.doitdo.domain.user.entity.WalletEarnLog;
import com.doitdo.domain.user.entity.WalletEarnSource;
import com.doitdo.domain.user.repository.UserRepository;
import com.doitdo.domain.user.repository.UserWalletRepository;
import com.doitdo.domain.user.repository.WalletEarnLogRepository;
import com.doitdo.global.util.JwtUtil;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@ActiveProfiles("test")
@AutoConfigureMockMvc
class AttendanceRewardIntegrationTest {

	private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

	@Autowired private MockMvc mockMvc;
	@Autowired private JwtUtil jwtUtil;
	@Autowired private CreditEarnService creditEarnService;
	@Autowired private UserRepository userRepository;
	@Autowired private UserWalletRepository userWalletRepository;
	@Autowired private WalletEarnLogRepository walletEarnLogRepository;
	@Autowired private JdbcTemplate jdbcTemplate;

	@BeforeEach
	void setUp() {
		deleteUserData();
	}

	@Test
	@DisplayName("Case 1: 신규 사용자, 첫 GET /api/users/me 호출은 false 반환 후 100 뚜레딧 자동 적립")
	void case01_firstGetMyInfoAutoClaimsAttendanceReward() throws Exception {
		Long userId = createCompletedUserWithWallet(0);
		String token = jwtUtil.generateAccessToken(userId);

		mockMvc.perform(get("/api/users/me")
						.header("Authorization", "Bearer " + token))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.data.dailyAttendanceClaimed").value(false));

		assertThat(walletBalance(userId)).isEqualTo(100);
		List<WalletEarnLog> logs = walletEarnLogsBySource(userId, WalletEarnSource.DAILY_ATTENDANCE);
		assertThat(logs).hasSize(1);
		assertThat(logs.get(0).getAmount()).isEqualTo(100);
	}

	@Test
	@DisplayName("Case 2: 같은 날 두 번째 GET /api/users/me 호출은 true 반환, 지갑 변동 없음")
	void case02_secondGetMyInfoSameDayReturnsClaimedTrueWithoutChange() throws Exception {
		Long userId = createCompletedUserWithWallet(0);
		String token = jwtUtil.generateAccessToken(userId);

		mockMvc.perform(get("/api/users/me")
						.header("Authorization", "Bearer " + token))
				.andExpect(status().isOk());
		int balanceAfterFirstClaim = walletBalance(userId);

		mockMvc.perform(get("/api/users/me")
						.header("Authorization", "Bearer " + token))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.data.dailyAttendanceClaimed").value(true));

		assertThat(walletBalance(userId)).isEqualTo(balanceAfterFirstClaim);
		assertThat(walletEarnLogsBySource(userId, WalletEarnSource.DAILY_ATTENDANCE)).hasSize(1);
	}

	@Test
	@DisplayName("Case 3: 같은 날 세 번째 GET /api/users/me 호출도 true 반환, 적립 1회만 유지")
	void case03_thirdGetMyInfoSameDayReturnsClaimedTrueWithoutChange() throws Exception {
		Long userId = createCompletedUserWithWallet(0);
		String token = jwtUtil.generateAccessToken(userId);

		mockMvc.perform(get("/api/users/me")
						.header("Authorization", "Bearer " + token))
				.andExpect(status().isOk());
		mockMvc.perform(get("/api/users/me")
						.header("Authorization", "Bearer " + token))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.data.dailyAttendanceClaimed").value(true));
		int balanceAfterSecondCall = walletBalance(userId);

		mockMvc.perform(get("/api/users/me")
						.header("Authorization", "Bearer " + token))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.data.dailyAttendanceClaimed").value(true));

		assertThat(walletBalance(userId)).isEqualTo(balanceAfterSecondCall);
		assertThat(walletEarnLogsBySource(userId, WalletEarnSource.DAILY_ATTENDANCE)).hasSize(1);
	}

	@Test
	@DisplayName("Case 4: Asia/Seoul 자정 경과 후 첫 GET /api/users/me 호출은 false 반환 후 추가 적립")
	void case04_getMyInfoAutoClaimsAgainAfterSeoulMidnight() throws Exception {
		Long userId = createCompletedUserWithWallet(0);
		String token = jwtUtil.generateAccessToken(userId);

		mockMvc.perform(get("/api/users/me")
						.header("Authorization", "Bearer " + token))
				.andExpect(status().isOk());
		moveAttendanceLogsToYesterday(userId);

		mockMvc.perform(get("/api/users/me")
						.header("Authorization", "Bearer " + token))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.data.dailyAttendanceClaimed").value(false));

		assertThat(walletBalance(userId)).isEqualTo(200);
		assertThat(walletEarnLogsBySource(userId, WalletEarnSource.DAILY_ATTENDANCE)).hasSize(2);
	}

	@Test
	@DisplayName("Case 5: PET_TOUCH 100 + TODO_COMPLETION 100 이후에도 GET /api/users/me 출석 보상 100 자동 적립")
	void case05_dailyAttendanceDoesNotCountTowardSourceDailyCap() throws Exception {
		Long userId = createCompletedUserWithWallet(0);
		String token = jwtUtil.generateAccessToken(userId);

		int petEarned = creditEarnService.tryEarn(userId, WalletEarnSource.PET_TOUCH, 100, null, false)
				.earnedAmount();
		int todoEarned = creditEarnService.tryEarn(userId, WalletEarnSource.TODO_COMPLETION, 100, null, false)
				.earnedAmount();

		assertThat(petEarned).isEqualTo(100);
		assertThat(todoEarned).isEqualTo(100);
		assertThat(walletBalance(userId)).isEqualTo(200);

		mockMvc.perform(get("/api/users/me")
						.header("Authorization", "Bearer " + token))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.data.dailyAttendanceClaimed").value(false));

		assertThat(walletEarnLogsBySource(userId, WalletEarnSource.DAILY_ATTENDANCE)).hasSize(1);
		assertThat(walletBalance(userId)).isEqualTo(300);
	}

	private Long createCompletedUserWithWallet(int initialBalance) {
		String suffix = UUID.randomUUID().toString().substring(0, 8);
		User user = userRepository.saveAndFlush(User.builder()
				.email("attendance-" + suffix + "@test.local")
				.password("encoded")
				.username("attendance_" + suffix)
				.birthDate(LocalDate.of(1990, 1, 1))
				.termsAgreedAt(LocalDateTime.now(SEOUL))
				.privacyAgreedAt(LocalDateTime.now(SEOUL))
				.termsVersion("1.0")
				.isDeleted(false)
				.build());
		userWalletRepository.saveAndFlush(UserWallet.builder()
				.userId(user.getUserId())
				.balance(initialBalance)
				.build());
		return user.getUserId();
	}

	private void deleteUserData() {
		jdbcTemplate.execute("SET REFERENTIAL_INTEGRITY FALSE");
		for (String table : List.of(
				"wallet_earn_logs", "user_wallets",
				"streak_reward_logs", "user_streaks",
				"furniture_purchase_logs", "room_furniture_placements", "user_furnitures",
				"todos", "categories",
				"user_character_history", "character_unlocks", "user_character",
				"character_actions", "characters",
				"user_settings", "users", "refresh_tokens", "auto_providers"
		)) {
			jdbcTemplate.update("DELETE FROM " + table);
		}
		jdbcTemplate.execute("SET REFERENTIAL_INTEGRITY TRUE");
	}

	private int walletBalance(Long userId) {
		return userWalletRepository.findByUserId(userId)
				.orElseThrow(() -> new AssertionError("지갑 없음: userId=" + userId))
				.getBalance();
	}

	private List<WalletEarnLog> walletEarnLogsBySource(Long userId, WalletEarnSource source) {
		return walletEarnLogRepository.findAll().stream()
				.filter(log -> log.getUserId().equals(userId) && log.getSource() == source)
				.toList();
	}

	private void moveAttendanceLogsToYesterday(Long userId) {
		LocalDateTime yesterdayNoon = LocalDate.now(SEOUL).minusDays(1).atTime(12, 0);
		jdbcTemplate.update(
				"UPDATE wallet_earn_logs SET earned_at=? WHERE user_id=? AND source='DAILY_ATTENDANCE'",
				yesterdayNoon,
				userId
		);
	}
}
