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

	/**
	 * 사용자가 {@code today} 에 활동(투두 완료 등)을 기록했음을 반영해 streak 를 갱신한다.
	 *
	 * <ul>
	 *   <li>{@code lastActiveDate == null} → 최초 활동: current=1, start=today, last=today</li>
	 *   <li>{@code lastActiveDate == today} → 당일 중복: 아무 변화 없음 (증가 방지)</li>
	 *   <li>{@code lastActiveDate == today.minusDays(1)} → 연속: current +=1, last=today</li>
	 *   <li>그 외 → 끊김: current=1, start=today, last=today (리셋)</li>
	 * </ul>
	 *
	 * <p>갱신 후 current 가 longest 를 넘어서면 longest 기록을 같이 갱신한다.
	 */
	public void recordActivity(LocalDate today) {
		if (this.lastActiveDate == null) {
			this.currentStreakCount = 1;
			this.currentStreakStartDate = today;
			this.lastActiveDate = today;
		} else if (this.lastActiveDate.equals(today)) {
			return;
		} else if (this.lastActiveDate.equals(today.minusDays(1))) {
			this.currentStreakCount += 1;
			this.lastActiveDate = today;
		} else {
			this.currentStreakCount = 1;
			this.currentStreakStartDate = today;
			this.lastActiveDate = today;
		}

		if (this.currentStreakCount > this.longestStreakCount) {
			this.longestStreakCount = this.currentStreakCount;
			this.longestStreakStartDate = this.currentStreakStartDate;
			this.longestStreakEndDate = today;
		}
	}
}
