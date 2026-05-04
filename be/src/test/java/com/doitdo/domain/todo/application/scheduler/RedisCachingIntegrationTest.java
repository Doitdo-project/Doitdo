package com.doitdo.domain.todo.application.scheduler;

import static org.assertj.core.api.Assertions.assertThat;

import com.doitdo.domain.tamagotchi.api.dto.resp.CurrentCharacterResp;
import com.doitdo.domain.tamagotchi.application.TamagotchiService;
import com.doitdo.domain.tamagotchi.entity.Character;
import com.doitdo.domain.tamagotchi.entity.UserCharacter;
import com.doitdo.domain.tamagotchi.repository.CharacterRepository;
import com.doitdo.domain.tamagotchi.repository.UserCharacterRepository;
import com.doitdo.domain.todo.api.dto.req.CategoryCreateReq;
import com.doitdo.domain.todo.api.dto.req.CategoryUpdateReq;
import com.doitdo.domain.todo.api.dto.req.TodoCreateReq;
import com.doitdo.domain.todo.api.dto.req.TodoListReq;
import com.doitdo.domain.todo.api.dto.req.TodoPriorityChangeReq;
import com.doitdo.domain.todo.api.dto.req.TodoSnoozeReq;
import com.doitdo.domain.todo.api.dto.req.TodoStatusChangeReq;
import com.doitdo.domain.todo.api.dto.req.TodoUpdateReq;
import com.doitdo.domain.todo.api.dto.resp.CategoryListResp;
import com.doitdo.domain.todo.api.dto.resp.TodoListResp;
import com.doitdo.domain.todo.application.CategoryService;
import com.doitdo.domain.todo.application.TodoService;
import com.doitdo.domain.todo.entity.Category;
import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.entity.Todo.TodoStatus;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import com.doitdo.domain.todo.repository.CategoryRepository;
import com.doitdo.domain.todo.repository.TodoRepository;
import com.doitdo.domain.user.entity.User;
import com.doitdo.domain.user.repository.UserRepository;
import com.redis.testcontainers.RedisContainer;
import jakarta.persistence.EntityManagerFactory;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.Set;
import java.util.concurrent.atomic.AtomicReference;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

@SpringBootTest
@ActiveProfiles("test")
@Testcontainers(disabledWithoutDocker = true)
class RedisCachingIntegrationTest {

	private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

	@Container
	static final RedisContainer REDIS = new RedisContainer(RedisContainer.DEFAULT_IMAGE_NAME.withTag("7-alpine"));

	@DynamicPropertySource
	static void redisProperties(DynamicPropertyRegistry registry) {
		registry.add("spring.cache.type", () -> "redis");
		registry.add("spring.data.redis.host", REDIS::getHost);
		registry.add("spring.data.redis.port", () -> REDIS.getMappedPort(6379));
		registry.add("spring.jpa.properties.hibernate.generate_statistics", () -> "true");
	}

	@Autowired
	private TodoService todoService;

	@Autowired
	private CategoryService categoryService;

	@Autowired
	private TamagotchiService tamagotchiService;

	@Autowired
	private RecurrenceMaterializeScheduler recurrenceMaterializeScheduler;

	@Autowired
	private TodoRepository todoRepository;

	@Autowired
	private CategoryRepository categoryRepository;

	@Autowired
	private UserRepository userRepository;

	@Autowired
	private CharacterRepository characterRepository;

	@Autowired
	private UserCharacterRepository userCharacterRepository;

	@Autowired
	private StringRedisTemplate redisTemplate;

	@Autowired
	private JdbcTemplate jdbcTemplate;

	@Autowired
	private EntityManagerFactory entityManagerFactory;

	private Statistics statistics;

	@BeforeEach
	void setUp() {
		statistics = entityManagerFactory.unwrap(SessionFactory.class).getStatistics();
		statistics.setStatisticsEnabled(true);
		flushRedis();
		deleteRows("streak_reward_logs", "user_streaks", "snooze_history", "todos", "categories",
				"user_character_history", "character_unlocks", "user_character", "characters", "users");
		statistics.clear();
	}

	@Test
	void cacheHitForHomeQueriesDoesNotIssueSqlOnSecondCall() {
		Long userId = createUser("home");
		saveTodo(userId, "today", TodoType.NORMAL, LocalDate.now(SEOUL), null);
		saveTodo(userId, "someday", TodoType.SOMEDAY, null, null);
		saveActiveCharacter(userId, 0);

		todoService.list(userId, todayReq());
		assertNoSql(() -> todoService.list(userId, todayReq()));

		todoService.list(userId, somedayReq());
		assertNoSql(() -> todoService.list(userId, somedayReq()));

		tamagotchiService.getCurrentCharacter(userId);
		assertNoSql(() -> tamagotchiService.getCurrentCharacter(userId));
	}

	@Test
	void todoMutationsEvictUserTodoListAndItemCaches() {
		Long userId = createUser("mutations");
		Long updateTodoId = saveTodo(userId, "update-before", TodoType.NORMAL, LocalDate.now(SEOUL), null).getTodoId();
		Long priorityTodoId = saveTodo(userId, "priority", TodoType.NORMAL, LocalDate.now(SEOUL), null).getTodoId();
		Long statusTodoId = saveTodo(userId, "status", TodoType.NORMAL, LocalDate.now(SEOUL), null).getTodoId();
		Long snoozeTodoId = saveTodo(userId, "snooze", TodoType.NORMAL, LocalDate.now(SEOUL), null).getTodoId();
		Long deleteTodoId = saveTodo(userId, "delete", TodoType.NORMAL, LocalDate.now(SEOUL), null).getTodoId();

		todoService.list(userId, todayReq());
		todoService.create(userId, new TodoCreateReq(
				"created", null, null, TodoType.NORMAL, LocalDate.now(SEOUL), null, null, 1, null));
		assertThat(titles(todoService.list(userId, todayReq()))).contains("created");

		todoService.list(userId, todayReq());
		todoService.update(userId, updateTodoId, new TodoUpdateReq(
				"update-after", null, null, null, null, null, null, null, false));
		assertThat(titles(todoService.list(userId, todayReq()))).contains("update-after").doesNotContain("update-before");

		todoService.detail(userId, priorityTodoId);
		todoService.list(userId, todayReq());
		todoService.changePriority(userId, priorityTodoId, new TodoPriorityChangeReq(1));
		assertThat(todoService.detail(userId, priorityTodoId).priority()).isEqualTo(1);

		todoService.list(userId, todayReq());
		todoService.changeStatus(userId, statusTodoId, new TodoStatusChangeReq(TodoStatus.DONE));
		assertThat(todoService.detail(userId, statusTodoId).status()).isEqualTo(TodoStatus.DONE);

		todoService.list(userId, todayReq());
		todoService.snooze(userId, snoozeTodoId, new TodoSnoozeReq(null));
		assertThat(titles(todoService.list(userId, todayReq()))).doesNotContain("snooze");

		todoService.list(userId, todayReq());
		todoService.delete(userId, deleteTodoId, null);
		assertThat(titles(todoService.list(userId, todayReq()))).doesNotContain("delete");
	}

	@Test
	void userTodoEvictDoesNotClearOtherUsersCachedList() {
		Long userA = createUser("a");
		Long userB = createUser("b");
		saveTodo(userA, "a-old", TodoType.NORMAL, LocalDate.now(SEOUL), null);
		saveTodo(userB, "b-old", TodoType.NORMAL, LocalDate.now(SEOUL), null);

		todoService.list(userB, todayReq());
		todoService.create(userA, new TodoCreateReq(
				"a-new", null, null, TodoType.NORMAL, LocalDate.now(SEOUL), null, null, 1, null));

		AtomicReference<TodoListResp> userBResp = new AtomicReference<>();
		assertNoSql(() -> userBResp.set(todoService.list(userB, todayReq())));
		assertThat(titles(userBResp.get())).containsExactly("b-old");
		assertThat(titles(todoService.list(userA, todayReq()))).contains("a-new");
	}

	@Test
	void doneStatusEvictsCurrentCharacterAfterExpGranted() {
		Long userId = createUser("exp");
		saveActiveCharacter(userId, 0);
		Long todoId = saveTodo(userId, "done", TodoType.NORMAL, LocalDate.now(SEOUL), null).getTodoId();

		CurrentCharacterResp before = tamagotchiService.getCurrentCharacter(userId);
		todoService.changeStatus(userId, todoId, new TodoStatusChangeReq(TodoStatus.DONE));
		CurrentCharacterResp after = tamagotchiService.getCurrentCharacter(userId);

		assertThat(before.currentExp()).isZero();
		assertThat(after.currentExp()).isGreaterThan(0);
	}

	@Test
	void categoryCudEvictsCategoriesAndTodoListCaches() {
		Long userId = createUser("category");
		Category work = categoryRepository.saveAndFlush(Category.create(userId, "work", 1));
		saveTodo(userId, "categorized", TodoType.NORMAL, LocalDate.now(SEOUL), work.getCategoryId());

		categoryService.list(userId);
		todoService.list(userId, todayReq());
		categoryService.create(userId, new CategoryCreateReq("study", 1));
		CategoryListResp afterCreate = categoryService.list(userId);
		assertThat(categoryNames(afterCreate)).contains("study");
		assertSqlIssued(() -> todoService.list(userId, todayReq()));

		categoryService.list(userId);
		todoService.list(userId, todayReq());
		categoryService.update(userId, work.getCategoryId(), new CategoryUpdateReq("work-new", null));
		assertThat(categoryNames(categoryService.list(userId))).contains("work-new");
		assertThat(todoService.list(userId, todayReq()).items())
				.extracting(item -> item.category())
				.contains("work-new");

		categoryService.list(userId);
		todoService.list(userId, todayReq());
		categoryService.delete(userId, work.getCategoryId());
		assertThat(categoryNames(categoryService.list(userId))).doesNotContain("work-new");
		assertThat(todoService.list(userId, todayReq()).items())
				.extracting(item -> item.category())
				.containsNull();
	}

	@Test
	void recurrenceMaterializeEvictsAffectedUsersTodoListCache() {
		Long userId = createUser("recurrence");
		LocalDate today = LocalDate.now(SEOUL);
		saveRecurringMaster(userId, "repeat", today);

		TodoListResp before = todoService.list(userId, todayReq());
		recurrenceMaterializeScheduler.materialize(today);
		TodoListResp after = todoService.list(userId, todayReq());

		assertThat(after.items()).hasSize(before.items().size() + 1);
		assertThat(after.items()).extracting(item -> item.title()).contains("repeat");
	}

	@Test
	void somedayDoneUsesDateSeparatedCacheKeyAcrossMidnight() {
		Long userId = createUser("date");
		LocalDate today = LocalDate.now(SEOUL);
		String yesterdayKey = "todos:list::" + userId + ":all:SOMEDAY:X:X:X:X:" + today.minusDays(1);
		redisTemplate.opsForValue().set(yesterdayKey, "stale-yesterday");
		todoRepository.saveAndFlush(Todo.builder()
				.userId(userId)
				.title("expired someday")
				.type(TodoType.SOMEDAY)
				.status(TodoStatus.DONE)
				.doneDate(today.minusDays(1))
				.priority(1)
				.isDeleted(false)
				.expGranted(false)
				.build());

		TodoListResp resp = todoService.list(userId, somedayReq());
		Set<String> todayKeys = redisTemplate.keys(
				"todos:list::" + userId + ":all:SOMEDAY:X:X:X:X:" + today);

		assertThat(resp.items()).isEmpty();
		assertThat(Boolean.TRUE.equals(redisTemplate.hasKey(yesterdayKey))).isTrue();
		assertThat(todayKeys).isNotNull().hasSize(1);
		assertThat(todayKeys).doesNotContain(yesterdayKey);
	}

	private Long createUser(String suffix) {
		User user = userRepository.saveAndFlush(User.create(
				"redis-cache-" + suffix + "@example.com",
				"encoded-password",
				"redis-cache-" + suffix));
		return user.getUserId();
	}

	private Todo saveTodo(Long userId, String title, TodoType type, LocalDate startDate, Long categoryId) {
		return todoRepository.saveAndFlush(Todo.create(
				userId,
				categoryId,
				title,
				null,
				type,
				1,
				null,
				startDate,
				null,
				null));
	}

	private void saveRecurringMaster(Long userId, String title, LocalDate startDate) {
		todoRepository.saveAndFlush(Todo.create(
				userId,
				null,
				title,
				null,
				TodoType.RECURRING,
				1,
				null,
				startDate,
				null,
				Set.of(startDate.getDayOfWeek())));
	}

	private void saveActiveCharacter(Long userId, int currentExp) {
		Character character = characterRepository.saveAndFlush(Character.builder()
				.species("SLIME")
				.name("slime")
				.stage(Character.Stage.BABY)
				.requiredExp(100)
				.thumbnailUrl("https://cdn.example.com/slime.png")
				.build());
		userCharacterRepository.saveAndFlush(UserCharacter.builder()
				.userId(userId)
				.characterId(character.getCharacterId())
				.name("slime")
				.currentExp(currentExp)
				.isActive(true)
				.isDeleted(false)
				.farewellNotified(false)
				.build());
	}

	private TodoListReq todayReq() {
		return new TodoListReq("today", null, null, null, null, null, null);
	}

	private TodoListReq somedayReq() {
		return new TodoListReq(null, null, null, TodoType.SOMEDAY, null, null, null);
	}

	private List<String> titles(TodoListResp resp) {
		return resp.items().stream()
				.map(item -> item.title())
				.toList();
	}

	private List<String> categoryNames(CategoryListResp resp) {
		return resp.items().stream()
				.map(item -> item.name())
				.toList();
	}

	private void assertNoSql(Runnable action) {
		statistics.clear();
		action.run();
		assertThat(statistics.getPrepareStatementCount()).isZero();
	}

	private void assertSqlIssued(Runnable action) {
		statistics.clear();
		action.run();
		assertThat(statistics.getPrepareStatementCount()).isPositive();
	}

	private void flushRedis() {
		redisTemplate.getConnectionFactory().getConnection().serverCommands().flushDb();
	}

	private void deleteRows(String... tables) {
		jdbcTemplate.execute("SET REFERENTIAL_INTEGRITY FALSE");
		for (String table : tables) {
			jdbcTemplate.update("DELETE FROM " + table);
		}
		jdbcTemplate.execute("SET REFERENTIAL_INTEGRITY TRUE");
	}
}
