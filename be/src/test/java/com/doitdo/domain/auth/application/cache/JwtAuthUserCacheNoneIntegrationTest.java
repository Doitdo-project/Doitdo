package com.doitdo.domain.auth.application.cache;

import static org.assertj.core.api.Assertions.assertThat;

import com.doitdo.domain.auth.application.CustomUserDetailsService;
import com.doitdo.domain.user.entity.User;
import com.doitdo.domain.user.repository.UserRepository;
import jakarta.persistence.EntityManagerFactory;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@ActiveProfiles("test")
@SpringBootTest(properties = {
		"auth.user-cache.provider=none",
		"spring.jpa.properties.hibernate.generate_statistics=true"
})
class JwtAuthUserCacheNoneIntegrationTest {

	@Autowired
	private CustomUserDetailsService userDetailsService;

	@Autowired
	private UserRepository userRepository;

	@Autowired
	private EntityManagerFactory entityManagerFactory;

	private Statistics statistics;

	@BeforeEach
	void setUp() {
		statistics = entityManagerFactory.unwrap(SessionFactory.class).getStatistics();
		statistics.setStatisticsEnabled(true);
		statistics.clear();
	}

	@Test
	void noneProviderQueriesDatabaseForEveryLoadUserByIdCall() {
		Long userId = createUser("none");

		statistics.clear();
		userDetailsService.loadUserById(userId);
		userDetailsService.loadUserById(userId);

		assertThat(statistics.getPrepareStatementCount()).isEqualTo(2);
	}

	private Long createUser(String suffix) {
		User user = userRepository.saveAndFlush(User.create(
				"auth-cache-" + suffix + "-" + System.nanoTime() + "@test.local",
				"encoded",
				"auth_cache_" + suffix + "_" + System.nanoTime()));
		return user.getUserId();
	}
}
