package com.doitdo.integration;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.doitdo.domain.tamagotchi.application.impl.TamagotchiServiceImpl;
import com.doitdo.domain.tamagotchi.entity.Character;
import com.doitdo.domain.tamagotchi.entity.UserCharacter;
import com.doitdo.domain.tamagotchi.repository.CharacterRepository;
import com.doitdo.domain.tamagotchi.repository.UserCharacterRepository;
import com.doitdo.domain.user.application.CreditEarnService;
import com.doitdo.domain.user.entity.User;
import com.doitdo.domain.user.entity.UserWallet;
import com.doitdo.domain.user.entity.WalletEarnLog;
import com.doitdo.domain.user.entity.WalletEarnSource;
import com.doitdo.domain.user.repository.UserRepository;
import com.doitdo.domain.user.repository.UserWalletRepository;
import com.doitdo.domain.user.repository.WalletEarnLogRepository;
import com.doitdo.global.util.JwtUtil;
import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.util.AopTestUtils;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@ActiveProfiles("test")
@AutoConfigureMockMvc
class PoopMissionIntegrationTest {

	private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");
	private static final LocalTime POOP_START = LocalTime.of(10, 0);
	private static final LocalTime POOP_END = LocalTime.of(22, 0);

	@Autowired private MockMvc mockMvc;
	@Autowired private JwtUtil jwtUtil;
	@Autowired private TamagotchiServiceImpl tamagotchiService;
	@Autowired private CreditEarnService creditEarnService;
	@Autowired private UserRepository userRepository;
	@Autowired private UserWalletRepository userWalletRepository;
	@Autowired private WalletEarnLogRepository walletEarnLogRepository;
	@Autowired private CharacterRepository characterRepository;
	@Autowired private UserCharacterRepository userCharacterRepository;
	@Autowired private JdbcTemplate jdbcTemplate;

	@BeforeEach
	void setUp() throws Exception {
		deleteUserData();
		setServiceClock(todayAt(9, 0));
	}

	@AfterEach
	void tearDown() throws Exception {
		setServiceClock(Clock.system(SEOUL));
	}

	@Test
	@DisplayName("Case 1: 신규 사용자 첫 GET /api/characters/me 는 poop_time 을 Lazy 결정하고 poop=false")
	void case01_firstGetInitializesPoopTimeAndReturnsFalse() throws Exception {
		Long userId = createUserWithWallet(0);
		UserCharacter userCharacter = seedActiveCharacter(userId);
		String token = jwtUtil.generateAccessToken(userId);

		mockMvc.perform(get("/api/characters/me")
				.header("Authorization", "Bearer " + token))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.poop").value(false));

		UserCharacter saved = userCharacterRepository.findById(userCharacter.getUserCharacterId()).orElseThrow();
		assertThat(saved.getPoopTimeDate()).isEqualTo(today());
		assertThat(saved.getPoopTime()).isNotNull();
		assertThat(saved.getPoopTime()).isAfterOrEqualTo(POOP_START);
		assertThat(saved.getPoopTime()).isBefore(POOP_END);
	}

	@Test
	@DisplayName("Case 2: poop_time 전 GET 은 poop=false")
	void case02_getBeforePoopTimeReturnsFalse() throws Exception {
		Long userId = createUserWithWallet(0);
		UserCharacter userCharacter = seedActiveCharacter(userId);
		setPoopSchedule(userCharacter, LocalTime.of(10, 0), today(), null);
		setServiceClock(todayAt(9, 30));
		String token = jwtUtil.generateAccessToken(userId);

		mockMvc.perform(get("/api/characters/me")
				.header("Authorization", "Bearer " + token))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.poop").value(false));
	}

	@Test
	@DisplayName("Case 3: poop_time 도래 후 GET 은 poop=true")
	void case03_getAfterPoopTimeReturnsTrue() throws Exception {
		Long userId = createUserWithWallet(0);
		UserCharacter userCharacter = seedActiveCharacter(userId);
		setPoopSchedule(userCharacter, LocalTime.of(10, 0), today(), null);
		setServiceClock(todayAt(10, 0));
		String token = jwtUtil.generateAccessToken(userId);

		mockMvc.perform(get("/api/characters/me")
				.header("Authorization", "Bearer " + token))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.poop").value(true));
	}

	@Test
	@DisplayName("Case 4: POOP action 활성 상태면 50 뚜레딧 적립 후 poop=false")
	void case04_poopActionClearsAndEarnsFifty() throws Exception {
		Long userId = createUserWithWallet(0);
		UserCharacter userCharacter = seedActiveCharacter(userId);
		setPoopSchedule(userCharacter, LocalTime.of(10, 0), today(), null);
		setServiceClock(todayAt(10, 0));
		String token = jwtUtil.generateAccessToken(userId);

		mockMvc.perform(post("/api/characters/me/actions/POOP")
				.header("Authorization", "Bearer " + token))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.earnedAmount").value(50))
			.andExpect(jsonPath("$.data.balanceAfter").value(50));

		UserCharacter saved = userCharacterRepository.findById(userCharacter.getUserCharacterId()).orElseThrow();
		assertThat(saved.getPoopClearedDate()).isEqualTo(today());
		assertThat(walletEarnLogsBySource(userId, WalletEarnSource.POOP_CLEAR)).hasSize(1);

		mockMvc.perform(get("/api/characters/me")
				.header("Authorization", "Bearer " + token))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.poop").value(false));
	}

	@Test
	@DisplayName("Case 5: 같은 날 두 번째 POOP action 은 M09-004")
	void case05_secondPoopActionSameDayReturnsConflict() throws Exception {
		Long userId = createUserWithWallet(0);
		UserCharacter userCharacter = seedActiveCharacter(userId);
		setPoopSchedule(userCharacter, LocalTime.of(10, 0), today(), null);
		setServiceClock(todayAt(10, 0));
		String token = jwtUtil.generateAccessToken(userId);

		mockMvc.perform(post("/api/characters/me/actions/POOP")
				.header("Authorization", "Bearer " + token))
			.andExpect(status().isOk());
		int balanceAfterFirst = walletBalance(userId);

		mockMvc.perform(post("/api/characters/me/actions/POOP")
				.header("Authorization", "Bearer " + token))
			.andExpect(status().isConflict())
			.andExpect(jsonPath("$.code").value("M09-004"));

		assertThat(walletBalance(userId)).isEqualTo(balanceAfterFirst);
		assertThat(walletEarnLogsBySource(userId, WalletEarnSource.POOP_CLEAR)).hasSize(1);
	}

	@Test
	@DisplayName("Case 6: 어제 미청소 똥은 자정 경과 후 GET 에도 유지되고 poop=true")
	void case06_getAfterDateChangesKeepsUnclearedPreviousPoop() throws Exception {
		Long userId = createUserWithWallet(0);
		UserCharacter userCharacter = seedActiveCharacter(userId);
		LocalDate yesterday = today().minusDays(1);
		LocalTime yesterdayPoopTime = LocalTime.of(11, 0);
		setPoopSchedule(userCharacter, yesterdayPoopTime, yesterday, null);
		setServiceClock(todayAt(9, 0));
		String token = jwtUtil.generateAccessToken(userId);

		mockMvc.perform(get("/api/characters/me")
				.header("Authorization", "Bearer " + token))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.poop").value(true));

		UserCharacter saved = userCharacterRepository.findById(userCharacter.getUserCharacterId()).orElseThrow();
		assertThat(saved.getPoopTimeDate()).isEqualTo(yesterday);
		assertThat(saved.getPoopTime()).isEqualTo(yesterdayPoopTime);
	}

	@Test
	@DisplayName("Case 7(a): 어제 미청소 똥은 다음날 POOP action 1회로 50 적립 후 발생일 기준 클리어")
	void case07a_previousDayUnclearedPoopClearsOnceNextDay() throws Exception {
		Long userId = createUserWithWallet(0);
		UserCharacter userCharacter = seedActiveCharacter(userId);
		LocalDate yesterday = today().minusDays(1);
		setPoopSchedule(userCharacter, LocalTime.of(11, 0), yesterday, null);
		setServiceClock(todayAt(9, 0));
		String token = jwtUtil.generateAccessToken(userId);

		mockMvc.perform(post("/api/characters/me/actions/POOP")
				.header("Authorization", "Bearer " + token))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.earnedAmount").value(50))
			.andExpect(jsonPath("$.data.balanceAfter").value(50));

		UserCharacter saved = userCharacterRepository.findById(userCharacter.getUserCharacterId()).orElseThrow();
		assertThat(saved.getPoopClearedDate()).isEqualTo(yesterday);
		assertThat(walletEarnLogsBySource(userId, WalletEarnSource.POOP_CLEAR)).hasSize(1);
	}

	@Test
	@DisplayName("Case 7(b): 어제 미청소 똥을 청소한 직후 같은 날 GET 은 새 poop_time 을 결정")
	void case07b_getAfterClearingPreviousDayPoopSchedulesToday() throws Exception {
		Long userId = createUserWithWallet(0);
		UserCharacter userCharacter = seedActiveCharacter(userId);
		LocalDate yesterday = today().minusDays(1);
		setPoopSchedule(userCharacter, LocalTime.of(11, 0), yesterday, null);
		setServiceClock(todayAt(9, 0));
		String token = jwtUtil.generateAccessToken(userId);

		mockMvc.perform(post("/api/characters/me/actions/POOP")
				.header("Authorization", "Bearer " + token))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.earnedAmount").value(50));

		mockMvc.perform(get("/api/characters/me")
				.header("Authorization", "Bearer " + token))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.poop").value(false));

		UserCharacter saved = userCharacterRepository.findById(userCharacter.getUserCharacterId()).orElseThrow();
		assertThat(saved.getPoopClearedDate()).isEqualTo(yesterday);
		assertThat(saved.getPoopTimeDate()).isEqualTo(today());
		assertThat(saved.getPoopTime()).isAfterOrEqualTo(POOP_START);
		assertThat(saved.getPoopTime()).isBefore(POOP_END);
	}

	@Test
	@DisplayName("Case 7(c): 어제 청소 완료 후 자정 경과 GET 은 새 poop_time 을 결정")
	void case07c_getAfterPreviousDayClearedPoopSchedulesToday() throws Exception {
		Long userId = createUserWithWallet(0);
		UserCharacter userCharacter = seedActiveCharacter(userId);
		LocalDate yesterday = today().minusDays(1);
		setPoopSchedule(userCharacter, LocalTime.of(11, 0), yesterday, yesterday);
		setServiceClock(todayAt(9, 0));
		String token = jwtUtil.generateAccessToken(userId);

		mockMvc.perform(get("/api/characters/me")
				.header("Authorization", "Bearer " + token))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.poop").value(false));

		UserCharacter saved = userCharacterRepository.findById(userCharacter.getUserCharacterId()).orElseThrow();
		assertThat(saved.getPoopTimeDate()).isEqualTo(today());
		assertThat(saved.getPoopTime()).isAfterOrEqualTo(POOP_START);
		assertThat(saved.getPoopTime()).isBefore(POOP_END);
	}

	@Test
	@DisplayName("Case 8: POOP_CLEAR 는 PET_TOUCH/TODO_COMPLETION cap 과 무관하게 50 적립")
	void case08_poopClearBypassesCombinedDailyCap() throws Exception {
		Long userId = createUserWithWallet(0);
		UserCharacter userCharacter = seedActiveCharacter(userId);
		setPoopSchedule(userCharacter, LocalTime.of(10, 0), today(), null);
		setServiceClock(todayAt(10, 0));
		String token = jwtUtil.generateAccessToken(userId);

		assertThat(creditEarnService.tryEarn(userId, WalletEarnSource.PET_TOUCH, 100, null, false)).isEqualTo(100);
		assertThat(creditEarnService.tryEarn(userId, WalletEarnSource.TODO_COMPLETION, 100, null, false))
			.isEqualTo(100);
		assertThat(walletBalance(userId)).isEqualTo(200);

		mockMvc.perform(post("/api/characters/me/actions/POOP")
				.header("Authorization", "Bearer " + token))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.earnedAmount").value(50))
			.andExpect(jsonPath("$.data.balanceAfter").value(250));

		assertThat(walletEarnLogsBySource(userId, WalletEarnSource.POOP_CLEAR)).hasSize(1);
		assertThat(walletBalance(userId)).isEqualTo(250);
	}

	private Long createUserWithWallet(int initialBalance) {
		String suffix = UUID.randomUUID().toString().substring(0, 8);
		User user = userRepository.saveAndFlush(User.builder()
			.email("poop-" + suffix + "@test.local")
			.password("encoded")
			.username("poop_" + suffix)
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

	private UserCharacter seedActiveCharacter(Long userId) {
		Character character = characterRepository.saveAndFlush(Character.builder()
			.species("SLIME")
			.name("슬라임")
			.stage(Character.Stage.BABY)
			.requiredExp(75)
			.thumbnailUrl("https://cdn.example.com/slime.png")
			.build());

		return userCharacterRepository.saveAndFlush(UserCharacter.builder()
			.userId(userId)
			.characterId(character.getCharacterId())
			.name("뚜잇이")
			.currentExp(0)
			.isActive(true)
			.isDeleted(false)
			.farewellNotified(false)
			.build());
	}

	private void setPoopSchedule(
		UserCharacter userCharacter,
		LocalTime poopTime,
		LocalDate poopTimeDate,
		LocalDate poopClearedDate
	) {
		UserCharacter saved = userCharacterRepository.findById(userCharacter.getUserCharacterId()).orElseThrow();
		saved.refreshPoopTime(poopTime, poopTimeDate);
		if (poopClearedDate != null) {
			saved.markPoopCleared(poopClearedDate);
		}
		userCharacterRepository.saveAndFlush(saved);
	}

	private List<WalletEarnLog> walletEarnLogsBySource(Long userId, WalletEarnSource source) {
		return walletEarnLogRepository.findAll().stream()
			.filter(log -> log.getUserId().equals(userId) && log.getSource() == source)
			.toList();
	}

	private int walletBalance(Long userId) {
		return userWalletRepository.findByUserId(userId)
			.orElseThrow(() -> new AssertionError("지갑 없음: userId=" + userId))
			.getBalance();
	}

	private LocalDate today() {
		return LocalDate.now(SEOUL);
	}

	private LocalDateTime todayAt(int hour, int minute) {
		return today().atTime(hour, minute);
	}

	private void setServiceClock(LocalDateTime dateTime) throws Exception {
		setServiceClock(Clock.fixed(dateTime.atZone(SEOUL).toInstant(), SEOUL));
	}

	private void setServiceClock(Clock clock) throws Exception {
		TamagotchiServiceImpl target = AopTestUtils.getTargetObject(tamagotchiService);
		ReflectionTestUtils.invokeMethod(target, "setClock", clock);
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
}
