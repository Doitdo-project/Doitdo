package com.doitdo.domain.auth.application.cache;

import static org.assertj.core.api.Assertions.assertThat;

import com.doitdo.domain.auth.application.CustomUserDetails;
import com.doitdo.domain.auth.application.CustomUserDetailsService;
import com.doitdo.domain.user.api.dto.req.RegisterAgreementsReq;
import com.doitdo.domain.user.api.dto.req.RegisterBirthDateReq;
import com.doitdo.domain.user.api.dto.req.WithdrawReq;
import com.doitdo.domain.user.application.impl.UserServiceImpl;
import com.doitdo.domain.user.entity.User;
import com.doitdo.domain.user.repository.UserRepository;
import jakarta.persistence.EntityManagerFactory;
import java.time.LocalDate;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;

@ActiveProfiles("test")
@SpringBootTest(properties = {
		"auth.user-cache.provider=caffeine",
		"spring.jpa.properties.hibernate.generate_statistics=true"
})
class JwtAuthUserCacheCaffeineIntegrationTest {

	@Autowired
	private CustomUserDetailsService userDetailsService;

	@Autowired
	private UserServiceImpl userService;

	@Autowired
	private UserRepository userRepository;

	@Autowired
	private PasswordEncoder passwordEncoder;

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
	void caffeineProviderDoesNotQueryDatabaseOnSecondLoadUserByIdCall() {
		Long userId = createUser("caffeine", "encoded");

		statistics.clear();
		userDetailsService.loadUserById(userId);
		assertThat(statistics.getPrepareStatementCount()).isEqualTo(1);

		statistics.clear();
		userDetailsService.loadUserById(userId);
		assertThat(statistics.getPrepareStatementCount()).isZero();
	}

	@Test
	void onboardingUpdatesEvictCachedSnapshot() {
		Long userId = createUser("onboarding", "encoded");
		userDetailsService.loadUserById(userId);

		LocalDate birthDate = LocalDate.of(1995, 1, 1);
		userService.registerBirthDate(userId, new RegisterBirthDateReq(birthDate));
		userService.registerAgreements(userId, new RegisterAgreementsReq(true, true, false));

		statistics.clear();
		CustomUserDetails reloaded = (CustomUserDetails) userDetailsService.loadUserById(userId);

		assertThat(statistics.getPrepareStatementCount()).isEqualTo(1);
		assertThat(reloaded.getUser().getBirthDate()).isEqualTo(birthDate);
		assertThat(reloaded.getUser().getTermsAgreedAt()).isNotNull();
	}

	@Test
	void withdrawEvictsCachedSnapshotSoDeletedUserIsDisabled() {
		String rawPassword = "Password1!";
		Long userId = createUser("withdraw", passwordEncoder.encode(rawPassword));
		UserDetails beforeWithdraw = userDetailsService.loadUserById(userId);
		assertThat(beforeWithdraw.isEnabled()).isTrue();

		userService.withdraw(userId, new WithdrawReq(rawPassword));

		statistics.clear();
		UserDetails afterWithdraw = userDetailsService.loadUserById(userId);

		assertThat(statistics.getPrepareStatementCount()).isEqualTo(1);
		assertThat(afterWithdraw.isEnabled()).isFalse();
	}

	private Long createUser(String suffix, String password) {
		User user = userRepository.saveAndFlush(User.create(
				"auth-cache-" + suffix + "-" + System.nanoTime() + "@test.local",
				password,
				"auth_cache_" + suffix + "_" + System.nanoTime()));
		return user.getUserId();
	}
}
