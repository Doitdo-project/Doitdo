package com.doitdo.domain.notification.application.impl;

import com.doitdo.domain.notification.application.FcmService;
import com.doitdo.domain.notification.entity.DeviceToken;
import jakarta.annotation.PostConstruct;
import java.util.List;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@ConditionalOnProperty(name = "firebase.enabled", havingValue = "false", matchIfMissing = true)
public class NoopFcmService implements FcmService {

	@PostConstruct
	void logStartup() {
		log.info("[fcm-noop] Firebase disabled. NoopFcmService is active.");
	}

	@Override
	public SendResult send(List<DeviceToken> tokens, String title, String body) {
		log.info("[fcm-noop] would send to {} tokens: title='{}', body='{}'", tokens.size(), title, body);
		return new SendResult(tokens.size(), List.of());
	}
}
