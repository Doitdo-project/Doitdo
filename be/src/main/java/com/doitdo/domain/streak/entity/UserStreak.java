package com.doitdo.domain.streak.entity;

import com.doitdo.global.entity.BaseTimeEntity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.LocalDate;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@Table(
		name = "user_streaks",
		uniqueConstraints = {
				@UniqueConstraint(
						name = "uk_user_streaks_user_id",
						columnNames = "user_id"
				)
		}
)
@Builder
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class UserStreak extends BaseTimeEntity {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "user_streak_id")
	private Long userStreakId;

	@Column(name = "user_id", nullable = false)
	private Long userId;

	@Column(name = "current_streak_count", nullable = false)
	private Integer currentStreakCount;

	@Column(name = "current_streak_start_date")
	private LocalDate currentStreakStartDate;

	@Column(name = "last_active_date")
	private LocalDate lastActiveDate;

	@Column(name = "longest_streak_count", nullable = false)
	private Integer longestStreakCount;

	@Column(name = "longest_streak_start_date")
	private LocalDate longestStreakStartDate;

	@Column(name = "longest_streak_end_date")
	private LocalDate longestStreakEndDate;

	public static UserStreak create(Long userId) {
		return UserStreak.builder()
				.userId(userId)
				.currentStreakCount(0)
				.longestStreakCount(0)
				.build();
	}
}
