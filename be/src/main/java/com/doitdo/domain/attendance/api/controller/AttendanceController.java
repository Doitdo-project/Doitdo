package com.doitdo.domain.attendance.api.controller;

import com.doitdo.domain.attendance.api.dto.resp.AttendanceClaimResp;
import com.doitdo.domain.attendance.application.AttendanceService;
import com.doitdo.domain.auth.application.CustomUserDetails;
import com.doitdo.global.api.response.GlobalApiResponse;
import com.doitdo.global.swagger.ApiErrorCodes;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "attendance", description = "출석 보상 API")
@RestController
@RequestMapping("/api/users/me/attendance")
@RequiredArgsConstructor
public class AttendanceController {

	private final AttendanceService attendanceService;

	@Operation(summary = "일일 출석 보상 수령",
			description = "Asia/Seoul 기준 하루 1회 출석 보상 100 뚜레딧을 지급한다.")
	@ApiErrorCodes({"U07-001", "U05-001"})
	@PostMapping
	public GlobalApiResponse<AttendanceClaimResp> claim(
			@AuthenticationPrincipal CustomUserDetails userDetails) {
		return GlobalApiResponse.ok("출석 보상 수령 완료",
				attendanceService.claim(userDetails.getUserId()));
	}
}
