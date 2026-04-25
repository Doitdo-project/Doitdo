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
		name = "streak_reward_logs",
		uniqueConstraints = {
				@UniqueConstraint(
						name = "uk_streak_reward_logs_segment",
						columnNames = {"user_id", "streak_start_date", "streak_count"}
				)
		}
)
@Builder
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class StreakRewardLog extends BaseTimeEntity {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "streak_reward_log_id")
	private Long streakRewardLogId;

	@Column(name = "user_id", nullable = false)
	private Long userId;

	@Column(name = "streak_start_date", nullable = false)
	private LocalDate streakStartDate;

	@Column(name = "streak_count", nullable = false)
	private Integer streakCount;

	@Column(name = "reward_amount", nullable = false)
	private Integer rewardAmount;

	public static StreakRewardLog create(Long userId, LocalDate streakStartDate, Integer streakCount,
			Integer rewardAmount) {
		return StreakRewardLog.builder()
				.userId(userId)
				.streakStartDate(streakStartDate)
				.streakCount(streakCount)
				.rewardAmount(rewardAmount)
				.build();
	}
}
