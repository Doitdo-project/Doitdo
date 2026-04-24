package com.doitdo.domain.streak.api.controller;

import com.doitdo.domain.auth.application.CustomUserDetails;
import com.doitdo.domain.streak.api.dto.resp.UserStreakResp;
import com.doitdo.domain.streak.application.UserStreakService;
import com.doitdo.global.api.response.GlobalApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "streak", description = "스트릭(연속 달성 기록) 조회")
@RestController
@RequestMapping("/api/users/me/streak")
@RequiredArgsConstructor
public class UserStreakController {

	private final UserStreakService userStreakService;

	@Operation(summary = "내 스트릭 조회",
			description = "현재 연속 일수와 최장 기록을 반환. 회원가입 시 row 자동 생성되어 정상 유저는 항상 조회 가능.")
	@GetMapping
	public GlobalApiResponse<UserStreakResp> getMyStreak(
			@AuthenticationPrincipal CustomUserDetails userDetails) {
		return GlobalApiResponse.ok(userStreakService.getMyStreak(userDetails.getUserId()));
	}
}
