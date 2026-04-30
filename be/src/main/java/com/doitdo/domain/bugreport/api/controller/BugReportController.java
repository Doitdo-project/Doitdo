package com.doitdo.domain.bugreport.api.controller;

import com.doitdo.domain.auth.application.CustomUserDetails;
import com.doitdo.domain.bugreport.api.dto.req.CreateBugReportReq;
import com.doitdo.domain.bugreport.api.dto.resp.BugReportResp;
import com.doitdo.domain.bugreport.application.BugReportService;
import com.doitdo.global.api.response.GlobalApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "bugreport", description = "버그 신고 API")
@RestController
@RequestMapping("/api/bug-reports")
@RequiredArgsConstructor
public class BugReportController {

	private final BugReportService bugReportService;

	@Operation(summary = "버그 신고 접수", description = "제목과 내용을 입력해 버그를 신고한다. 이미지 첨부는 미지원(후속 이슈).")
	@PostMapping
	@ResponseStatus(HttpStatus.CREATED)
	public GlobalApiResponse<BugReportResp> create(
			@AuthenticationPrincipal CustomUserDetails userDetails,
			@Valid @RequestBody CreateBugReportReq req) {
		return GlobalApiResponse.created(
				"버그 신고가 접수되었습니다.",
				bugReportService.create(userDetails.getUserId(), req));
	}
}
