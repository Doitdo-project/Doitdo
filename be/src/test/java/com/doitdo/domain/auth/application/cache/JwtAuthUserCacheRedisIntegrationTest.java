package com.doitdo.domain.auth.application.cache;

import static org.assertj.core.api.Assertions.assertThat;

import com.doitdo.domain.auth.application.CustomUserDetailsService;
import com.doitdo.domain.user.entity.User;
import com.doitdo.domain.user.repository.UserRepository;
import com.redis.testcontainers.RedisContainer;
import jakarta.persistence.EntityManagerFactory;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

@ActiveProfiles("test")
@SpringBootTest(properties = {
		"auth.user-cache.provider=redis",
		"spring.jpa.properties.hibernate.generate_statistics=true"
})
@Testcontainers(disabledWithoutDocker = true)
class JwtAuthUserCacheRedisIntegrationTest {

	@Container
	static final RedisContainer REDIS = new RedisContainer(RedisContainer.DEFAULT_IMAGE_NAME.withTag("7-alpine"));

	@DynamicPropertySource
	static void redisProperties(DynamicPropertyRegistry registry) {
		registry.add("spring.data.redis.host", REDIS::getHost);
		registry.add("spring.data.redis.port", () -> REDIS.getMappedPort(6379));
	}

	@Autowired
	private CustomUserDetailsService userDetailsService;

	@Autowired
	private UserRepository userRepository;

	@Autowired
	private StringRedisTemplate redisTemplate;

	@Autowired
	private EntityManagerFactory entityManagerFactory;

	private Statistics statistics;

	@BeforeEach
	void setUp() {
		statistics = entityManagerFactory.unwrap(SessionFactory.class).getStatistics();
		statistics.setStatisticsEnabled(true);
		statistics.clear();
		redisTemplate.getConnectionFactory().getConnection().serverCommands().flushDb();
	}

	@Test
	void redisProviderDoesNotQueryDatabaseOnSecondLoadUserByIdCall() {
		Long userId = createUser("redis");

		statistics.clear();
		userDetailsService.loadUserById(userId);
		assertThat(statistics.getPrepareStatementCount()).isEqualTo(1);

		statistics.clear();
		userDetailsService.loadUserById(userId);
		assertThat(statistics.getPrepareStatementCount()).isZero();
	}

	private Long createUser(String suffix) {
		User user = userRepository.saveAndFlush(User.create(
				"auth-cache-" + suffix + "-" + System.nanoTime() + "@test.local",
				"encoded",
				"auth_cache_" + suffix + "_" + System.nanoTime()));
		return user.getUserId();
	}
}
