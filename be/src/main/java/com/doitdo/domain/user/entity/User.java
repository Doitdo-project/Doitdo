package com.doitdo.domain.user.entity;

import com.doitdo.global.entity.BaseTimeEntity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@Table(name = "users")
@Builder
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class User extends BaseTimeEntity {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "user_id")
	private Long userId;

	@Column(length = 50, unique = true)
	private String username;

	@Column(length = 255)
	private String password;

	@Column(length = 255, unique = true)
	private String email;

	@Column(name = "streak_count", nullable = false)
	private Integer streakCount;

	@Column(name = "is_deleted", nullable = false)
	private Boolean isDeleted;

	public static User create(String email, String encodedPassword, String username) {
		return User.builder()
				.email(email)
				.password(encodedPassword)
				.username(username)
				.streakCount(0)
				.isDeleted(false)
				.build();
	}

	public static User createOAuthUser(String email, String username) {
		return User.builder()
				.email(email)
				.password(null)
				.username(username)
				.streakCount(0)
				.isDeleted(false)
				.build();
	}

	public void updatePassword(String encodedPassword) {
		this.password = encodedPassword;
	}
}
