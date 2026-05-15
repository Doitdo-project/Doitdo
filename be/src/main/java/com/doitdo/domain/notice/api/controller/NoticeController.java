package com.doitdo.domain.notice.api.controller;

import com.doitdo.domain.auth.application.CustomUserDetails;
import com.doitdo.domain.notice.api.dto.resp.NoticeListResp;
import com.doitdo.domain.notice.api.dto.resp.NoticePopupResp;
import com.doitdo.domain.notice.api.dto.resp.NoticeResp;
import com.doitdo.domain.notice.application.NoticeService;
import com.doitdo.global.api.response.GlobalApiResponse;
import com.doitdo.global.swagger.ApiErrorCodes;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "notice", description = "공지사항 API")
@RestController
@RequestMapping("/api/notices")
@RequiredArgsConstructor
public class NoticeController {

	private final NoticeService noticeService;

	@Operation(summary = "초기 진입 공지 팝업 조회", description = "최신 활성 공지 1개와 현재 사용자의 다시 안보기 여부를 함께 반환한다.")
	@GetMapping("/latest-popup")
	public GlobalApiResponse<NoticePopupResp> getLatestPopup(
			@AuthenticationPrincipal CustomUserDetails userDetails) {
		return GlobalApiResponse.ok(
				"초기 진입 공지 팝업 조회 성공",
				noticeService.getLatestPopup(userDetails.getUserId())
		);
	}

	@Operation(summary = "공지사항 목록 조회", description = "활성 공지사항 목록을 최신순으로 조회한다.")
	@GetMapping
	public GlobalApiResponse<NoticeListResp> getNotices() {
		return GlobalApiResponse.ok(
				"공지사항 목록 조회 성공",
				noticeService.getNotices()
		);
	}

	@Operation(summary = "공지사항 상세 조회", description = "공지사항 ID로 활성 공지 상세를 조회한다.")
	@ApiErrorCodes({"O00-001"})
	@GetMapping("/{noticeId}")
	public GlobalApiResponse<NoticeResp> getNotice(@PathVariable Long noticeId) {
		return GlobalApiResponse.ok(
				"공지사항 상세 조회 성공",
				noticeService.getNotice(noticeId)
		);
	}

	@Operation(summary = "공지사항 다시 안보기", description = "현재 로그인한 사용자가 해당 공지를 다시 보지 않도록 저장한다.")
	@ApiErrorCodes({"O00-001"})
	@PostMapping("/{noticeId}/dismiss")
	@ResponseStatus(HttpStatus.NO_CONTENT)
	public GlobalApiResponse<Void> dismiss(
			@AuthenticationPrincipal CustomUserDetails userDetails,
			@PathVariable Long noticeId) {
		noticeService.dismiss(userDetails.getUserId(), noticeId);
		return GlobalApiResponse.noContent("공지사항 다시 안보기 저장 성공");
	}
}
