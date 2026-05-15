package com.doitdo.domain.notice.entity;

import com.doitdo.global.entity.BaseTimeEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@Table(
		name = "notice_dismissals",
		uniqueConstraints = @UniqueConstraint(
				name = "uk_notice_dismissals_user_notice",
				columnNames = {"user_id", "notice_id"}
		)
)
@Builder
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class NoticeDismissal extends BaseTimeEntity {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "notice_dismissal_id")
	private Long noticeDismissalId;

	@Column(name = "user_id", nullable = false)
	private Long userId;

	@Column(name = "notice_id", nullable = false)
	private Long noticeId;

	public static NoticeDismissal create(Long userId, Long noticeId) {
		return NoticeDismissal.builder()
				.userId(userId)
				.noticeId(noticeId)
				.build();
	}
}
