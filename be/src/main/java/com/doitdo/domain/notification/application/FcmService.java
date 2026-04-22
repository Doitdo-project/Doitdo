package com.doitdo.domain.notification.application;

import com.doitdo.domain.notification.entity.DeviceToken;
import java.util.List;

public interface FcmService {

	SendResult send(List<DeviceToken> tokens, String title, String body);

	record SendResult(int successCount, List<Long> deactivatedTokenIds) {
	}
}
