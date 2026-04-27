package com.doitdo.domain.notification.api.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.BDDMockito.then;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.doitdo.domain.auth.application.CustomUserDetails;
import com.doitdo.domain.notification.api.dto.req.TestNotificationSendReq;
import com.doitdo.domain.notification.application.NotificationService;
import com.doitdo.domain.user.entity.User;
import com.doitdo.global.api.response.GlobalApiResponse;

@ExtendWith(MockitoExtension.class)
class NotificationControllerTest {

	@Mock
	private NotificationService notificationService;

	@Test
	void sendTestNotificationReturnsGlobalApiResponse() {
		TestNotificationController controller = new TestNotificationController(notificationService);
		CustomUserDetails userDetails = new CustomUserDetails(User.builder()
				.userId(1L)
				.email("user@example.com")
				.username("user")
				.password("password")
				.isDeleted(false)
				.build());
		TestNotificationSendReq req = new TestNotificationSendReq("테스트 알림", "모바일 푸시 테스트입니다.");

		GlobalApiResponse<Void> resp = controller.sendTestNotification(userDetails, req);

		assertThat(resp.getStatus()).isEqualTo(200);
		assertThat(resp.getMessage()).isEqualTo("테스트 알림 발송 성공");
		then(notificationService).should().sendTestNotification(1L, req);
	}
}
