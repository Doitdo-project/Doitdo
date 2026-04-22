package com.doitdo.domain.notification.api.controller;

import com.doitdo.domain.auth.application.CustomUserDetails;
import com.doitdo.domain.notification.api.dto.req.DeviceTokenRegisterReq;
import com.doitdo.domain.notification.api.dto.req.DeviceTokenUnregisterReq;
import com.doitdo.domain.notification.api.dto.resp.DeviceTokenResp;
import com.doitdo.domain.notification.api.dto.resp.NotificationListResp;
import com.doitdo.domain.notification.api.dto.resp.NotificationReadAllResp;
import com.doitdo.domain.notification.api.dto.resp.NotificationReadResp;
import com.doitdo.domain.notification.application.DeviceTokenService;
import com.doitdo.domain.notification.application.NotificationService;
import com.doitdo.global.api.response.GlobalApiResponse;
import com.doitdo.global.swagger.ApiErrorCodes;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "notification", description = "알림 관련 API")
@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

	private final NotificationService notificationService;
	private final DeviceTokenService deviceTokenService;

	@Operation(summary = "디바이스 토큰 등록", description = "현재 로그인한 사용자에게 FCM 디바이스 토큰을 등록한다.")
	@ApiErrorCodes({"N03-002"})
	@PostMapping("/device-token")
	@ResponseStatus(HttpStatus.CREATED)
	public GlobalApiResponse<DeviceTokenResp> registerDeviceToken(
			@AuthenticationPrincipal CustomUserDetails userDetails,
			@RequestBody DeviceTokenRegisterReq req) {
		return GlobalApiResponse.created(
				"디바이스 토큰 등록 성공",
				deviceTokenService.register(userDetails.getUserId(), req)
		);
	}

	@Operation(summary = "디바이스 토큰 해제", description = "현재 로그인한 사용자의 FCM 디바이스 토큰을 비활성화한다.")
	@ApiErrorCodes({"N02-002"})
	@DeleteMapping("/device-token")
	@ResponseStatus(HttpStatus.NO_CONTENT)
	public GlobalApiResponse<Void> unregisterDeviceToken(
			@AuthenticationPrincipal CustomUserDetails userDetails,
			@Valid @RequestBody DeviceTokenUnregisterReq req) {
		deviceTokenService.unregister(userDetails.getUserId(), req);
		return GlobalApiResponse.noContent("디바이스 토큰 해제 성공");
	}

	@Operation(summary = "알림 목록 조회", description = "현재 로그인한 사용자의 알림 목록을 페이지네이션과 읽음 여부 필터로 조회한다.")
	@ApiErrorCodes({"N04-002"})
	@GetMapping
	public GlobalApiResponse<NotificationListResp> list(
			@AuthenticationPrincipal CustomUserDetails userDetails,
			@RequestParam(required = false) Boolean isRead,
			@RequestParam(defaultValue = "0") int page,
			@RequestParam(defaultValue = "20") int size) {
		return GlobalApiResponse.ok(
				"알림 목록 조회 성공",
				notificationService.list(userDetails.getUserId(), isRead, page, size)
		);
	}

	@Operation(summary = "알림 읽음 처리", description = "단일 알림을 읽음 상태로 변경한다.")
	@ApiErrorCodes({"N05-002", "N05-003"})
	@PatchMapping("/{notificationId}/read")
	public GlobalApiResponse<NotificationReadResp> read(
			@AuthenticationPrincipal CustomUserDetails userDetails,
			@PathVariable Long notificationId) {
		return GlobalApiResponse.ok(
				"알림 읽음 처리 성공",
				notificationService.read(userDetails.getUserId(), notificationId)
		);
	}

	@Operation(summary = "알림 전체 읽음 처리", description = "현재 로그인한 사용자의 읽지 않은 알림을 모두 읽음 처리한다.")
	@ApiErrorCodes({"N06-002"})
	@PatchMapping("/read-all")
	public GlobalApiResponse<NotificationReadAllResp> readAll(
			@AuthenticationPrincipal CustomUserDetails userDetails) {
		return GlobalApiResponse.ok(
				"알림 전체 읽음 처리 성공",
				notificationService.readAll(userDetails.getUserId())
		);
	}

	@Operation(summary = "알림 삭제", description = "단일 알림을 소프트 삭제한다.")
	@ApiErrorCodes({"N07-002", "N07-003"})
	@DeleteMapping("/{notificationId}")
	@ResponseStatus(HttpStatus.NO_CONTENT)
	public GlobalApiResponse<Void> delete(
			@AuthenticationPrincipal CustomUserDetails userDetails,
			@PathVariable Long notificationId) {
		notificationService.delete(userDetails.getUserId(), notificationId);
		return GlobalApiResponse.noContent("알림 삭제 성공");
	}
}
