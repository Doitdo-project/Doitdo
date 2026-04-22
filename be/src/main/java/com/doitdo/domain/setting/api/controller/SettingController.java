package com.doitdo.domain.setting.api.controller;

import com.doitdo.domain.auth.application.CustomUserDetails;
import com.doitdo.domain.setting.api.dto.req.UserSettingUpdateReq;
import com.doitdo.domain.setting.api.dto.resp.UserSettingResp;
import com.doitdo.domain.setting.application.SettingService;
import com.doitdo.global.api.response.GlobalApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "setting", description = "사용자 설정 API")
@RestController
@RequestMapping("/api/settings")
@RequiredArgsConstructor
public class SettingController {

	private final SettingService settingService;

	@Operation(summary = "내 설정 조회", description = "방해금지 / 아침·저녁 리마인드 설정을 조회")
	@GetMapping
	public GlobalApiResponse<UserSettingResp> getMySetting(
			@AuthenticationPrincipal CustomUserDetails userDetails) {
		return GlobalApiResponse.ok(settingService.getMySetting(userDetails.getUserId()));
	}

	@Operation(summary = "내 설정 수정", description = "방해금지 / 아침·저녁 리마인드 설정을 부분 업데이트. null 필드는 기존값 유지")
	@PatchMapping
	public GlobalApiResponse<UserSettingResp> updateMySetting(
			@AuthenticationPrincipal CustomUserDetails userDetails,
			@RequestBody UserSettingUpdateReq req) {
		return GlobalApiResponse.ok(
				"설정 수정 완료",
				settingService.updateMySetting(userDetails.getUserId(), req));
	}
}
