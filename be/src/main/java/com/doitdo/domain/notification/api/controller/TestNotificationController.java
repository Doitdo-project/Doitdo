package com.doitdo.domain.notification.api.controller;

import com.doitdo.domain.auth.application.CustomUserDetails;
import com.doitdo.domain.notification.api.dto.req.TestNotificationSendReq;
import com.doitdo.domain.notification.application.NotificationService;
import com.doitdo.global.api.response.GlobalApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Profile;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "notification", description = "알림 관련 API")
@Profile({"local", "dev", "test"})
@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class TestNotificationController {

	private final NotificationService notificationService;

	@Operation(summary = "테스트 알림 발송", description = "현재 로그인한 사용자에게 테스트 알림을 저장하고 FCM 푸시를 즉시 발송한다.")
	@PostMapping("/test-send")
	public GlobalApiResponse<Void> sendTestNotification(
			@AuthenticationPrincipal CustomUserDetails userDetails,
			@Valid @RequestBody TestNotificationSendReq req) {
		notificationService.sendTestNotification(userDetails.getUserId(), req);
		return GlobalApiResponse.ok("테스트 알림 발송 성공", null);
	}
}
