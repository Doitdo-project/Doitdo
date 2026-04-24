package com.doitdo.domain.streak.application.impl;

import com.doitdo.domain.streak.api.dto.resp.UserStreakResp;
import com.doitdo.domain.streak.application.UserStreakService;
import com.doitdo.domain.streak.entity.UserStreak;
import com.doitdo.domain.streak.repository.UserStreakRepository;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.UserErrorCode;
import java.time.LocalDate;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UserStreakServiceImpl implements UserStreakService {

	private final UserStreakRepository userStreakRepository;

	@Override
	@Transactional
	public void recordActivity(Long userId) {
		UserStreak streak = userStreakRepository.findByUserId(userId)
				.orElseGet(() -> userStreakRepository.save(UserStreak.create(userId)));
		streak.recordActivity(LocalDate.now());
	}

	@Override
	@Transactional(readOnly = true)
	public UserStreakResp getMyStreak(Long userId) {
		UserStreak streak = userStreakRepository.findByUserId(userId)
				.orElseThrow(() -> new CustomException(UserErrorCode.U06_002));
		return UserStreakResp.from(streak);
	}
}
