package com.doitdo.domain.notification.api.dto.resp;

import com.doitdo.domain.notification.entity.Notification;
import java.util.List;
import org.springframework.data.domain.Page;

public record NotificationListResp(
		List<NotificationResp> items,
		int page,
		int size,
		long totalElements,
		int totalPages
) {

	public static NotificationListResp from(Page<Notification> pageResult) {
		return new NotificationListResp(
				pageResult.getContent().stream()
						.map(NotificationResp::from)
						.toList(),
				pageResult.getNumber(),
				pageResult.getSize(),
				pageResult.getTotalElements(),
				pageResult.getTotalPages()
		);
	}
}
