package com.doitdo.domain.streak.application;

import com.doitdo.domain.streak.api.dto.resp.UserStreakResp;

public interface UserStreakService {

	/**
	 * 사용자가 오늘 활동(투두 완료 등)했음을 기록해 streak 을 갱신한다.
	 * streak row 가 없으면 생성, 있으면 판정 로직에 따라 증가/유지/리셋.
	 */
	void recordActivity(Long userId);

	/**
	 * 사용자 본인의 streak 정보 조회 (현재 streak + 최장 기록).
	 * 정상 가입된 유저는 회원가입 시 row 자동 생성되므로 존재함.
	 */
	UserStreakResp getMyStreak(Long userId);
}
