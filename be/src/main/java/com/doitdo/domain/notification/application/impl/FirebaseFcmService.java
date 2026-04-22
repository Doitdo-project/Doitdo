package com.doitdo.domain.notification.application.impl;

import com.doitdo.domain.notification.application.FcmService;
import com.doitdo.domain.notification.entity.DeviceToken;
import com.doitdo.domain.notification.repository.DeviceTokenRepository;
import com.google.firebase.messaging.BatchResponse;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import com.google.firebase.messaging.SendResponse;
import com.google.firebase.messaging.MessagingErrorCode;
import jakarta.annotation.PostConstruct;
import java.util.ArrayList;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
@ConditionalOnProperty(name = "firebase.enabled", havingValue = "true")
public class FirebaseFcmService implements FcmService {

	private final FirebaseMessaging firebaseMessaging;
	private final DeviceTokenRepository deviceTokenRepository;

	@PostConstruct
	void logStartup() {
		log.info("[fcm] FirebaseFcmService is active.");
	}

	@Override
	@Transactional
	public SendResult send(List<DeviceToken> tokens, String title, String body) {
		if (tokens.isEmpty()) {
			return new SendResult(0, List.of());
		}

		int successCount = 0;
		List<Long> deactivatedTokenIds = new ArrayList<>();

		for (DeviceToken token : tokens) {
			Message message = Message.builder()
					.setToken(token.getFcmToken())
					.setNotification(Notification.builder()
							.setTitle(title)
							.setBody(body)
							.build())
					.build();

			try {
				String messageId = firebaseMessaging.send(message);
				if (messageId != null) {
					successCount++;
				}
			} catch (FirebaseMessagingException e) {
				log.warn("[fcm] failed to send to tokenId={}, reason={}", token.getDeviceTokenId(), e.getMessage());
				if (shouldDeactivate(e)) {
					token.deactivate();
					deactivatedTokenIds.add(token.getDeviceTokenId());
				}
			}
		}

		return new SendResult(successCount, deactivatedTokenIds);
	}

	private boolean shouldDeactivate(FirebaseMessagingException e) {
		MessagingErrorCode errorCode = e.getMessagingErrorCode();
		return errorCode == MessagingErrorCode.UNREGISTERED
				|| errorCode == MessagingErrorCode.INVALID_ARGUMENT;
	}
}
