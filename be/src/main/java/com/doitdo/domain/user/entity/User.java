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

	@Column(name = "is_deleted", nullable = false)
	private Boolean isDeleted;

	public static User create(String email, String encodedPassword, String username) {
		return User.builder()
				.email(email)
				.password(encodedPassword)
				.username(username)
				.isDeleted(false)
				.build();
	}

	public static User createOAuthUser(String email, String username) {
		return User.builder()
				.email(email)
				.password(null)
				.username(username)
				.isDeleted(false)
				.build();
	}

	public void updatePassword(String encodedPassword) {
		this.password = encodedPassword;
	}

	/**
	 * 회원탈퇴 처리.
	 *
	 * <p>{@code isDeleted=true} 로 soft delete 하고 개인정보 필드를 익명화한다.
	 * <ul>
	 *   <li>{@code email}: {@code deleted_<userId>_<timestamp>@deleted.local} 로 치환 — UNIQUE 충돌 방지, 같은 이메일로 재가입 가능</li>
	 *   <li>{@code username}: {@code deleted_<userId>_<timestamp>} 로 치환 — 동일</li>
	 *   <li>{@code password}: null — 탈퇴 후 로그인 경로 차단</li>
	 * </ul>
	 */
	public void withdraw() {
		this.isDeleted = true;
		String marker = "deleted_" + this.userId + "_" + System.currentTimeMillis();
		this.email = marker + "@deleted.local";
		this.username = marker;
		this.password = null;
	}
}
