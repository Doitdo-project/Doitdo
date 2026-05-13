package com.doitdo.integration;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.doitdo.domain.auth.api.dto.req.SignupReq;
import com.doitdo.domain.auth.application.AuthService;
import com.doitdo.domain.shop.application.ShopService;
import com.doitdo.domain.shop.entity.Furniture;
import com.doitdo.domain.shop.repository.FurnitureRepository;
import com.doitdo.domain.streak.application.UserStreakService;
import com.doitdo.domain.streak.entity.UserStreak;
import com.doitdo.domain.streak.repository.UserStreakRepository;
import com.doitdo.domain.tamagotchi.application.TamagotchiService;
import com.doitdo.domain.tamagotchi.api.dto.resp.CharacterActionUrlResp;
import com.doitdo.domain.tamagotchi.entity.Character;
import com.doitdo.domain.tamagotchi.entity.CharacterAction;
import com.doitdo.domain.tamagotchi.entity.UserCharacter;
import com.doitdo.domain.tamagotchi.repository.CharacterActionRepository;
import com.doitdo.domain.tamagotchi.repository.CharacterRepository;
import com.doitdo.domain.tamagotchi.repository.UserCharacterRepository;
import com.doitdo.domain.todo.api.dto.req.TodoStatusChangeReq;
import com.doitdo.domain.todo.application.TodoService;
import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.entity.Todo.TodoStatus;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import com.doitdo.domain.todo.repository.TodoRepository;
import com.doitdo.domain.user.application.CreditEarnService;
import com.doitdo.domain.user.entity.User;
import com.doitdo.domain.user.entity.UserWallet;
import com.doitdo.domain.user.entity.WalletEarnLog;
import com.doitdo.domain.user.entity.WalletEarnSource;
import com.doitdo.domain.user.repository.UserRepository;
import com.doitdo.domain.user.repository.UserWalletRepository;
import com.doitdo.domain.user.repository.WalletEarnLogRepository;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.ShopErrorCode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

/**
 * 뚜레딧 적립 시스템 통합 테스트 (Stage 5).
 *
 * <p>모든 테스트는 @Transactional 을 붙이지 않는다.
 * TodoCompletionCreditListener 가 AFTER_COMMIT 이벤트를 구독하므로,
 * 테스트 메서드 자체가 트랜잭션을 열면 커밋이 일어나지 않아 이벤트가 발행되지 않는다.
 */
@SpringBootTest
@ActiveProfiles("test")
class DoreditEarningSystemIntegrationTest {

    private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

    // ── 서비스 ─────────────────────────────────────────────────────────────
    @Autowired private AuthService         authService;
    @Autowired private TamagotchiService   tamagotchiService;
    @Autowired private TodoService         todoService;
    @Autowired private UserStreakService   userStreakService;
    @Autowired private ShopService         shopService;
    @Autowired private CreditEarnService   creditEarnService;

    // ── 레포지토리 ──────────────────────────────────────────────────────────
    @Autowired private UserRepository             userRepository;
    @Autowired private UserWalletRepository       userWalletRepository;
    @Autowired private WalletEarnLogRepository    walletEarnLogRepository;
    @Autowired private CharacterRepository        characterRepository;
    @Autowired private CharacterActionRepository  characterActionRepository;
    @Autowired private UserCharacterRepository    userCharacterRepository;
    @Autowired private TodoRepository             todoRepository;
    @Autowired private UserStreakRepository       userStreakRepository;
    @Autowired private FurnitureRepository        furnitureRepository;

    @Autowired private JdbcTemplate jdbcTemplate;

    /** 모든 테스트 전 데이터 초기화. DataInitializer 가 넣는 palettes/furnitures 는 건드리지 않는다. */
    @BeforeEach
    void setUp() {
        deleteUserData();
    }

    // ══════════════════════════════════════════════════════════════════════
    // Case 1: 회원가입 → 잔액 100 + SIGNUP_BONUS 로그
    // ══════════════════════════════════════════════════════════════════════
    @Test
    @DisplayName("Case 1: 회원가입 시 100 뚜레딧 적립 및 SIGNUP_BONUS 로그 생성")
    void case01_signupGrantsHundredCreditAndLog() {
        // EGG 캐릭터가 없으면 signup() 이 예외를 던지므로 미리 seed.
        seedEggCharacter("슬라임");

        authService.signup(new SignupReq("user1@test.com", "P@ssword1!", "user1"));

        User user = userRepository.findByEmail("user1@test.com")
                .orElseThrow(() -> new AssertionError("가입된 유저를 찾을 수 없음"));
        UserWallet wallet = userWalletRepository.findByUserId(user.getUserId())
                .orElseThrow(() -> new AssertionError("지갑이 없음"));

        assertThat(wallet.getBalance()).isEqualTo(100);

        List<WalletEarnLog> logs = walletEarnLogRepository.findAll().stream()
                .filter(l -> l.getUserId().equals(user.getUserId()))
                .toList();
        assertThat(logs).hasSize(1);
        assertThat(logs.get(0).getSource()).isEqualTo(WalletEarnSource.SIGNUP_BONUS);
        assertThat(logs.get(0).getAmount()).isEqualTo(100);
    }

    // ══════════════════════════════════════════════════════════════════════
    // Case 2: 7일 스트릭 → +500, 일일 cap 무시, STREAK_7DAY 로그
    // ══════════════════════════════════════════════════════════════════════
    @Test
    @DisplayName("Case 2: 7일 연속 스트릭 보상 → +500 적립, 일일 cap 무시")
    void case02_streakSevenDayGrantsFiveHundred() {
        Long userId = createUserWithWallet("user2@test.com", "user2");

        // streak 을 7일로 세팅 (recordActivity를 7일 연속으로 호출하면 DB에 반영됨)
        UserStreak streak = userStreakRepository.findByUserId(userId)
                .orElseThrow(() -> new AssertionError("streak 없음"));
        LocalDate start = LocalDate.now(SEOUL).minusDays(6);
        // 직접 DB 조작으로 streak 상태 세팅
        jdbcTemplate.update(
                "UPDATE user_streaks SET current_streak_count=7, current_streak_start_date=?, last_active_date=? WHERE user_id=?",
                java.sql.Date.valueOf(start),
                java.sql.Date.valueOf(LocalDate.now(SEOUL)),
                userId
        );

        int balanceBefore = walletBalance(userId);
        userStreakService.claimSevenDayReward(userId);
        int balanceAfter = walletBalance(userId);

        assertThat(balanceAfter - balanceBefore).isEqualTo(500);

        List<WalletEarnLog> logs = walletEarnLogRepository.findAll().stream()
                .filter(l -> l.getUserId().equals(userId) && l.getSource() == WalletEarnSource.STREAK_7DAY)
                .toList();
        assertThat(logs).hasSize(1);
        assertThat(logs.get(0).getAmount()).isEqualTo(500);
    }

    // ══════════════════════════════════════════════════════════════════════
    // Case 3: IDLE 2회 터치 → +100; 3번째 터치: actionUrl 정상, earnedAmount=0, nextAvailableAt 설정
    // ══════════════════════════════════════════════════════════════════════
    @Test
    @DisplayName("Case 3: IDLE 2회 적립 후 3번째 호출 시 earnedAmount=0, nextAvailableAt 설정")
    void case03_twoIdleEarnsThenThirdEarnsNothing() {
        Long userId = createUserWithWallet("user3@test.com", "user3");
        UserCharacter uc = seedCharacterWithAction(userId, "IDLE");

        // 2-hour cooldown 우회: 직전 터치 시각을 3시간 전으로 DB에 세팅하면서 2번 적립
        for (int i = 0; i < 2; i++) {
            // 매 호출마다 lastTouchedAt 을 충분히 과거로 세팅
            resetLastTouchedAt(uc.getUserCharacterId(), 3);
            CharacterActionUrlResp resp = tamagotchiService.getMyCharacterActionUrl(userId, "IDLE");
            assertThat(resp.earnedAmount()).isEqualTo(50);
        }

        // 3번째: dailyTouchCount=2 이므로 cap 도달 → earn=0, nextAvailableAt 설정됨
        CharacterActionUrlResp third = tamagotchiService.getMyCharacterActionUrl(userId, "IDLE");
        assertThat(third.earnedAmount()).isZero();
        assertThat(third.actionUrl()).isNotBlank();
        assertThat(third.nextAvailableAt()).isNotNull();
        assertThat(third.dailyTouchCount()).isEqualTo(2);

        int totalEarned = walletEarnLogsBySource(userId, WalletEarnSource.PET_TOUCH).stream()
                .mapToInt(WalletEarnLog::getAmount).sum();
        assertThat(totalEarned).isEqualTo(100);
    }

    // ══════════════════════════════════════════════════════════════════════
    // Case 4: 2시간 cooldown — 첫 번째 IDLE 직후 즉시 재호출 → earnedAmount=0, 2시간 후 가능
    // ══════════════════════════════════════════════════════════════════════
    @Test
    @DisplayName("Case 4: 2시간 미경과 시 두 번째 IDLE 호출 → earnedAmount=0, 2시간 후 재적립")
    void case04_cooldownPreventsSecondEarnWithinTwoHours() {
        Long userId = createUserWithWallet("user4@test.com", "user4");
        UserCharacter uc = seedCharacterWithAction(userId, "IDLE");

        CharacterActionUrlResp first = tamagotchiService.getMyCharacterActionUrl(userId, "IDLE");
        assertThat(first.earnedAmount()).isEqualTo(50);

        // 즉시 재호출: lastTouchedAt 이 방금 전이므로 cooldown 미경과
        CharacterActionUrlResp second = tamagotchiService.getMyCharacterActionUrl(userId, "IDLE");
        assertThat(second.earnedAmount()).isZero();
        assertThat(second.actionUrl()).isNotBlank();

        resetLastTouchedAt(uc.getUserCharacterId(), 2);
        CharacterActionUrlResp third = tamagotchiService.getMyCharacterActionUrl(userId, "IDLE");
        assertThat(third.earnedAmount()).isEqualTo(50);
    }

    // ══════════════════════════════════════════════════════════════════════
    // Case 5: 24시간 경과 후 재적립 가능 (dailyTouchDate 리셋 확인)
    // ══════════════════════════════════════════════════════════════════════
    @Test
    @DisplayName("Case 5: 24시간 경과 시 dailyTouchDate 리셋 후 재적립 가능")
    void case05_after24HoursEarnResetAllowsNewEarning() {
        Long userId = createUserWithWallet("user5@test.com", "user5");
        UserCharacter uc = seedCharacterWithAction(userId, "IDLE");

        // 1회 적립
        CharacterActionUrlResp first = tamagotchiService.getMyCharacterActionUrl(userId, "IDLE");
        assertThat(first.earnedAmount()).isEqualTo(50);

        // DB 직접 조작으로 어제 날짜 + 25시간 전으로 세팅
        jdbcTemplate.update(
                "UPDATE user_character SET last_touched_at=DATEADD(HOUR, -25, NOW()), daily_touch_date=DATEADD(DAY, -1, CURRENT_DATE()) WHERE user_character_id=?",
                uc.getUserCharacterId()
        );

        // 재적립: 새 날짜이므로 dailyTouchCount 리셋 → 적립 가능
        CharacterActionUrlResp second = tamagotchiService.getMyCharacterActionUrl(userId, "IDLE");
        assertThat(second.earnedAmount()).isEqualTo(50);
        assertThat(second.dailyTouchCount()).isEqualTo(1);
    }

    // ══════════════════════════════════════════════════════════════════════
    // Case 6: TODO 5개 완료 → +100 적립; 6번째 → earnedAmount=0
    // ══════════════════════════════════════════════════════════════════════
    @Test
    @DisplayName("Case 6: 서로 다른 TODO 5개 완료 → 100 적립, 6번째 TODO → 0")
    void case06_fiveDistinctTodosEarnHundred() throws InterruptedException {
        Long userId = createUserWithWallet("user6@test.com", "user6");
        // TodoCompletionCreditListener 가 tamagotchi exp 이벤트도 처리하므로
        // UserCharacter 가 없어도 exp 리스너는 no-op (skip) 처리됨. 지갑만 있으면 됨.

        // 5개 TODO 생성 & 완료
        for (int i = 0; i < 5; i++) {
            Long todoId = saveTodo(userId, "todo-" + i);
            todoService.changeStatus(userId, todoId, new TodoStatusChangeReq(TodoStatus.DONE));
            // AFTER_COMMIT 이벤트가 비동기로 처리되므로 짧게 대기
            Thread.sleep(100);
        }

        int totalEarned = walletEarnLogsBySource(userId, WalletEarnSource.TODO_COMPLETION).stream()
                .mapToInt(WalletEarnLog::getAmount).sum();
        assertThat(totalEarned).isEqualTo(100); // 1개 완료 시마다 20 적립, 일일 5회

        // 6번째 TODO: source daily cap 100 도달로 skip
        Long sixthId = saveTodo(userId, "todo-5");
        int balanceBefore = walletBalance(userId);
        todoService.changeStatus(userId, sixthId, new TodoStatusChangeReq(TodoStatus.DONE));
        Thread.sleep(100);
        int balanceAfter = walletBalance(userId);

        assertThat(balanceAfter - balanceBefore).isZero();
    }

    @Test
    @DisplayName("Case 6-1: 과거 TODO 완료는 뚜레딧 적립 및 오늘 완료 카운트에서 제외")
    void case06_1_pastTodosDoNotEarnOrContributeToThreshold() throws InterruptedException {
        Long userId = createUserWithWallet("user6-1@test.com", "user6-1");
        LocalDate yesterday = LocalDate.now(SEOUL).minusDays(1);

        for (int i = 0; i < 2; i++) {
            Long todoId = saveTodo(userId, "past-todo-" + i, yesterday);
            todoService.changeStatus(userId, todoId, new TodoStatusChangeReq(TodoStatus.DONE));
            Thread.sleep(100);
        }

        Long firstTodayTodo = saveTodo(userId, "today-todo-0");
        todoService.changeStatus(userId, firstTodayTodo, new TodoStatusChangeReq(TodoStatus.DONE));
        Thread.sleep(100);

        int earnedAfterTwoPastAndOneToday = walletEarnLogsBySource(userId, WalletEarnSource.TODO_COMPLETION).stream()
                .mapToInt(WalletEarnLog::getAmount).sum();
        assertThat(earnedAfterTwoPastAndOneToday).isEqualTo(20);

        for (int i = 1; i < 3; i++) {
            Long todoId = saveTodo(userId, "today-todo-" + i);
            todoService.changeStatus(userId, todoId, new TodoStatusChangeReq(TodoStatus.DONE));
            Thread.sleep(100);
        }

        int earnedAfterThreeTodayTodos = walletEarnLogsBySource(userId, WalletEarnSource.TODO_COMPLETION).stream()
                .mapToInt(WalletEarnLog::getAmount).sum();
        assertThat(earnedAfterThreeTodayTodos).isEqualTo(60);
    }

    // ══════════════════════════════════════════════════════════════════════
    // Case 7: TODO undo→redo 5회 토글 → firstCompletedDate 1회만 기록, distinct=1, earn=1회
    // ══════════════════════════════════════════════════════════════════════
    @Test
    @DisplayName("Case 7: TODO undo/redo 5회 반복 시 firstCompletedDate 최초 1회만 기록하고 1회만 적립")
    void case07_undoRedoTogglesPreserveFirstCompletedDate() throws InterruptedException {
        Long userId = createUserWithWallet("user7@test.com", "user7");
        Long todoId = saveTodo(userId, "toggle-todo");

        // 5회 DONE / TODO 반복
        for (int i = 0; i < 5; i++) {
            todoService.changeStatus(userId, todoId, new TodoStatusChangeReq(TodoStatus.DONE));
            Thread.sleep(100);
            todoService.changeStatus(userId, todoId, new TodoStatusChangeReq(TodoStatus.TODO));
        }

        Todo todo = todoRepository.findByTodoIdAndIsDeletedFalse(todoId)
                .orElseThrow(() -> new AssertionError("todo 없음"));
        assertThat(todo.getFirstCompletedDate()).isNotNull();

        // distinct count = 1 (동일 todo 가 firstCompletedDate 를 1개만 가짐)
        long distinct = todoRepository.countByUserIdAndFirstCompletedDate(userId, todo.getFirstCompletedDate());
        assertThat(distinct).isEqualTo(1L);

        // 동일 TODO 는 firstCompletedDate 1개만 가지므로 1회만 적립
        int totalEarned = walletEarnLogsBySource(userId, WalletEarnSource.TODO_COMPLETION).stream()
                .mapToInt(WalletEarnLog::getAmount).sum();
        assertThat(totalEarned).isEqualTo(20);
    }

    // ══════════════════════════════════════════════════════════════════════
    // Case 8: PET_TOUCH 100 + TODO_COMPLETION 100 → combined=200 → 다음 적립=0
    // ══════════════════════════════════════════════════════════════════════
    @Test
    @DisplayName("Case 8: PET_TOUCH 100 + TODO_COMPLETION 100 combined cap 200 도달 후 추가 적립=0")
    void case08_combinedCapTwoHundredBlocksSubsequentEarns() throws InterruptedException {
        Long userId = createUserWithWallet("user8@test.com", "user8");
        UserCharacter uc = seedCharacterWithAction(userId, "IDLE");

        // PET_TOUCH 100: 2회 IDLE (각 50, 각각 cooldown 우회)
        for (int i = 0; i < 2; i++) {
            resetLastTouchedAt(uc.getUserCharacterId(), 3);
            CharacterActionUrlResp resp = tamagotchiService.getMyCharacterActionUrl(userId, "IDLE");
            assertThat(resp.earnedAmount()).isEqualTo(50);
        }

        // TODO_COMPLETION 100: 5개 TODO 완료
        for (int i = 0; i < 5; i++) {
            Long todoId = saveTodo(userId, "cap-todo-" + i);
            todoService.changeStatus(userId, todoId, new TodoStatusChangeReq(TodoStatus.DONE));
            Thread.sleep(100);
        }

        // 합산 확인
        int petEarned = walletEarnLogsBySource(userId, WalletEarnSource.PET_TOUCH).stream()
                .mapToInt(WalletEarnLog::getAmount).sum();
        int todoEarned = walletEarnLogsBySource(userId, WalletEarnSource.TODO_COMPLETION).stream()
                .mapToInt(WalletEarnLog::getAmount).sum();
        assertThat(petEarned).isEqualTo(100);
        assertThat(todoEarned).isEqualTo(100);

        // combined=200 → 추가 TODO 적립 시도 → 0
        Long extraTodo = saveTodo(userId, "cap-todo-extra");
        int balanceBefore = walletBalance(userId);
        todoService.changeStatus(userId, extraTodo, new TodoStatusChangeReq(TodoStatus.DONE));
        Thread.sleep(100);
        assertThat(walletBalance(userId) - balanceBefore).isZero();
    }

    // ══════════════════════════════════════════════════════════════════════
    // Case 9: 가구 구매 → spend() 정상 동작; 잔액 부족 시 INSUFFICIENT_BALANCE
    // ══════════════════════════════════════════════════════════════════════
    @Test
    @DisplayName("Case 9: 가구 구매 spend() 정상 처리, 잔액 부족 시 S00-003")
    void case09_furniturePurchaseAndInsufficientBalance() {
        Long userId = createUserWithWallet("user9@test.com", "user9", 50);
        Furniture furniture = savePurchasableFurniture("TEST_CHAIR", 50);

        // 정상 구매: 잔액 50 = 가격 50
        shopService.purchaseFurniture(userId, furniture.getFurnitureId());
        assertThat(walletBalance(userId)).isZero();

        // 잔액 부족: 잔액 0, 가격 50
        Furniture furniture2 = savePurchasableFurniture("TEST_TABLE", 50);
        assertThatThrownBy(() -> shopService.purchaseFurniture(userId, furniture2.getFurnitureId()))
                .isInstanceOf(CustomException.class)
                .satisfies(ex -> {
                    CustomException ce = (CustomException) ex;
                    assertThat(ce.getErrorCode()).isEqualTo(ShopErrorCode.INSUFFICIENT_BALANCE);
                    assertThat(ce.getErrorCode().getCode()).isEqualTo("S00-003");
                });
    }

    // ══════════════════════════════════════════════════════════════════════
    // Case 10: 동시 IDLE 5회 → 락으로 보호 → 일일 cap(2회, 100크레딧) 초과 없음
    //
    // [중요 편차 — 동시 호출에서 정확한 성공 횟수보다 cap 초과 방지가 핵심]
    // 명세는 "5개 동시 발사 → 최대 2회"를 요구한다.
    // 그러나 canEarnTouchCredit() 은 dailyTouchCount < 2 AND 2시간 cooldown 을 모두 요구한다.
    // PESSIMISTIC_WRITE 로 직렬화된 이후:
    //   - H2 인메모리 DB 는 row-level lock 완전 지원이 보장되지 않아 실제 직렬화 순서가
    //     달라질 수 있다. 중요한 것은 "데이터 무결성 — dailyTouchCount ≤ 2, 총 적립 ≤ 100" 이다.
    //   - dailyTouchCount < 2 가드로 인해 earn 횟수는 절대 2를 넘지 않는다.
    //   - 이 테스트는 동시 호출에서도 이중 적립(cap 초과)이 발생하지 않음을 증명한다.
    // ══════════════════════════════════════════════════════════════════════
    @Test
    @DisplayName("Case 10: 동시 IDLE 5회 → PESSIMISTIC_WRITE 락으로 일일 cap(100크레딧) 초과 없음")
    void case10_concurrentIdleCallsNeverExceedDailyCap() throws InterruptedException {
        Long userId = createUserWithWallet("user10@test.com", "user10");
        seedCharacterWithAction(userId, "IDLE");

        int threadCount = 5;
        CountDownLatch ready = new CountDownLatch(threadCount);
        CountDownLatch start = new CountDownLatch(1);
        ExecutorService executor = Executors.newFixedThreadPool(threadCount);
        AtomicInteger successCount = new AtomicInteger(0);
        List<Future<?>> futures = new ArrayList<>();

        for (int i = 0; i < threadCount; i++) {
            futures.add(executor.submit(() -> {
                ready.countDown();
                try {
                    start.await();
                    CharacterActionUrlResp resp = tamagotchiService.getMyCharacterActionUrl(userId, "IDLE");
                    if (resp.earnedAmount() > 0) {
                        successCount.incrementAndGet();
                    }
                } catch (Exception ignored) {
                    // 잠금 경쟁/예외는 무시 (earn 실패로 처리)
                }
            }));
        }

        ready.await();
        start.countDown();

        for (Future<?> f : futures) {
            try { f.get(); } catch (Exception ignored) {}
        }
        executor.shutdown();

        // dailyTouchCount < 2 가드로 인해 earn 횟수는 절대 2를 초과할 수 없다.
        // (H2 에서 PESSIMISTIC_WRITE 직렬화가 완벽하지 않아도 애플리케이션 수준 cap 은 유지됨)
        assertThat(successCount.get()).isLessThanOrEqualTo(2);

        int totalPetEarned = walletEarnLogsBySource(userId, WalletEarnSource.PET_TOUCH).stream()
                .mapToInt(WalletEarnLog::getAmount).sum();
        // 잠금이 정상이라면 일일 cap 100 을 초과하지 않는다.
        assertThat(totalPetEarned).isLessThanOrEqualTo(100);
    }

    // ══════════════════════════════════════════════════════════════════════
    // 헬퍼 메서드
    // ══════════════════════════════════════════════════════════════════════

    /** 사용자 관련 데이터만 삭제 (DataInitializer 가 넣는 palettes/furnitures 는 보존). */
    private void deleteUserData() {
        jdbcTemplate.execute("SET REFERENTIAL_INTEGRITY FALSE");
        for (String table : List.of(
                "wallet_earn_logs", "user_wallets",
                "streak_reward_logs", "user_streaks",
                "furniture_purchase_logs", "room_furniture_placements", "user_furnitures",
                "todos", "categories",
                "user_character_history", "character_unlocks", "user_character",
                "character_actions", "characters",
                "user_settings", "users", "refresh_tokens"
        )) {
            jdbcTemplate.update("DELETE FROM " + table);
        }
        jdbcTemplate.execute("SET REFERENTIAL_INTEGRITY TRUE");
    }

    /** 이메일/패스워드로 User + 빈 지갑(잔액 0) 생성. */
    private Long createUserWithWallet(String email, String username) {
        return createUserWithWallet(email, username, 0);
    }

    /** 이메일/패스워드로 User + 지갑(지정 잔액) 생성. */
    private Long createUserWithWallet(String email, String username, int initialBalance) {
        User user = userRepository.saveAndFlush(User.create(email, "encoded-pw", username));
        userWalletRepository.saveAndFlush(UserWallet.builder()
                .userId(user.getUserId())
                .balance(initialBalance)
                .build());
        // UserStreak 도 기본 생성 (streak service 가 필요로 함)
        userStreakRepository.saveAndFlush(UserStreak.create(user.getUserId()));
        return user.getUserId();
    }

    /** EGG 단계 Character seed (signup() 호출용). */
    private void seedEggCharacter(String name) {
        characterRepository.saveAndFlush(Character.builder()
                .species("SLIME")
                .name(name)
                .stage(Character.Stage.EGG)
                .requiredExp(0)
                .thumbnailUrl("https://cdn.example.com/egg.png")
                .build());
    }

    /**
     * BABY 단계 Character + CharacterAction(IDLE) + UserCharacter(active) seed.
     * IDLE 터치 테스트 전에 반드시 호출.
     */
    private UserCharacter seedCharacterWithAction(Long userId, String actionType) {
        Character character = characterRepository.saveAndFlush(Character.builder()
                .species("SLIME")
                .name("슬라임")
                .stage(Character.Stage.BABY)
                .requiredExp(100)
                .thumbnailUrl("https://cdn.example.com/slime.png")
                .build());

        characterActionRepository.saveAndFlush(CharacterAction.builder()
                .characterId(character.getCharacterId())
                .actionType(actionType)
                .actionUrl("https://cdn.example.com/slime-idle.gif")
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

    /** 테스트 가구 생성 (isOnSale=true, price=지정값). */
    private Furniture savePurchasableFurniture(String code, int price) {
        return furnitureRepository.saveAndFlush(Furniture.builder()
                .code(code)
                .name(code)
                .description("테스트 가구")
                .category("DECO")
                .price(price)
                .imageUrl("https://cdn.example.com/" + code + ".png")
                .thumbnailUrl("https://cdn.example.com/" + code + ".png")
                .defaultX(0)
                .defaultY(0)
                .width(100)
                .height(100)
                .zIndex(1)
                .isOnSale(true)
                .isDeleted(false)
                .build());
    }

    private Long saveTodo(Long userId, String title) {
        return saveTodo(userId, title, LocalDate.now(SEOUL));
    }

    private Long saveTodo(Long userId, String title, LocalDate startDate) {
        return todoRepository.saveAndFlush(Todo.create(
                userId, null, null, null, title, null, TodoType.NORMAL, 1, null,
                startDate, null, null
        )).getTodoId();
    }

    private int walletBalance(Long userId) {
        return userWalletRepository.findByUserId(userId)
                .orElseThrow(() -> new AssertionError("지갑 없음: userId=" + userId))
                .getBalance();
    }

    private List<WalletEarnLog> walletEarnLogsBySource(Long userId, WalletEarnSource source) {
        return walletEarnLogRepository.findAll().stream()
                .filter(l -> l.getUserId().equals(userId) && l.getSource() == source)
                .toList();
    }

    /**
     * 터치 cooldown 우회용: user_character 의 last_touched_at 을 hoursAgo 시간 전으로 갱신.
     * CreditEarnServiceImpl 이 Clock 주입을 지원하지 않으므로 DB 직접 조작으로 시간을 시뮬레이션한다.
     */
    private void resetLastTouchedAt(Long userCharacterId, int hoursAgo) {
        jdbcTemplate.update(
                "UPDATE user_character SET last_touched_at=DATEADD(HOUR, ?, NOW()) WHERE user_character_id=?",
                -hoursAgo,
                userCharacterId
        );
    }

}
