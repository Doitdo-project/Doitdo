package com.doitdo.domain.auth.application.cache;

import com.doitdo.domain.user.entity.User;
import java.time.LocalDate;
import java.time.LocalDateTime;

public record AuthUserSnapshot(
		Long userId,
		String username,
		String password,
		Boolean isDeleted,
		LocalDate birthDate,
		LocalDateTime termsAgreedAt,
		LocalDateTime privacyAgreedAt,
		String termsVersion
) {

	public static AuthUserSnapshot from(User user) {
		return new AuthUserSnapshot(
				user.getUserId(),
				user.getUsername(),
				user.getPassword(),
				user.getIsDeleted(),
				user.getBirthDate(),
				user.getTermsAgreedAt(),
				user.getPrivacyAgreedAt(),
				user.getTermsVersion()
		);
	}

	public User toUser() {
		return User.builder()
				.userId(userId)
				.username(username)
				.password(password)
				.isDeleted(isDeleted)
				.birthDate(birthDate)
				.termsAgreedAt(termsAgreedAt)
				.privacyAgreedAt(privacyAgreedAt)
				.termsVersion(termsVersion)
				.build();
	}
}
