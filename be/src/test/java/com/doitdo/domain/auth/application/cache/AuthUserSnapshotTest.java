package com.doitdo.domain.auth.application.cache;

import static org.assertj.core.api.Assertions.assertThat;

import com.doitdo.domain.auth.application.CustomUserDetails;
import com.doitdo.domain.user.entity.User;
import java.time.LocalDate;
import java.time.LocalDateTime;
import org.junit.jupiter.api.Test;

class AuthUserSnapshotTest {

	@Test
	void snapshotKeepsSecurityAndOnboardingFields() {
		LocalDate birthDate = LocalDate.of(1995, 1, 1);
		LocalDateTime termsAgreedAt = LocalDateTime.of(2026, 5, 15, 12, 0);
		LocalDateTime privacyAgreedAt = LocalDateTime.of(2026, 5, 15, 12, 1);
		User user = User.builder()
				.userId(1L)
				.username("auth-user")
				.password("encoded")
				.isDeleted(false)
				.birthDate(birthDate)
				.termsAgreedAt(termsAgreedAt)
				.privacyAgreedAt(privacyAgreedAt)
				.termsVersion("1.0")
				.build();

		CustomUserDetails details = new CustomUserDetails(AuthUserSnapshot.from(user).toUser());

		assertThat(details.getUserId()).isEqualTo(1L);
		assertThat(details.getUsername()).isEqualTo("auth-user");
		assertThat(details.getPassword()).isEqualTo("encoded");
		assertThat(details.isEnabled()).isTrue();
		assertThat(details.getUser().getBirthDate()).isEqualTo(birthDate);
		assertThat(details.getUser().getTermsAgreedAt()).isEqualTo(termsAgreedAt);
		assertThat(details.getUser().getPrivacyAgreedAt()).isEqualTo(privacyAgreedAt);
		assertThat(details.getUser().getTermsVersion()).isEqualTo("1.0");
	}

	@Test
	void deletedUserSnapshotIsDisabled() {
		User user = User.builder()
				.userId(2L)
				.username("deleted-user")
				.password(null)
				.isDeleted(true)
				.build();

		CustomUserDetails details = new CustomUserDetails(AuthUserSnapshot.from(user).toUser());

		assertThat(details.isEnabled()).isFalse();
	}
}
