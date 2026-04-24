package com.doitdo.domain.streak.application;

public interface UserStreakService {

	/**
	 * 사용자가 오늘 활동(투두 완료 등)했음을 기록해 streak 을 갱신한다.
	 * streak row 가 없으면 생성, 있으면 판정 로직에 따라 증가/유지/리셋.
	 */
	void recordActivity(Long userId);
}
