package com.doitdo.domain.notification.application.listener;

import com.doitdo.domain.notification.application.NotificationService;
import com.doitdo.domain.tamagotchi.event.TamagotchiFarewellEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * 다마고치 이별(독립 승인) 시점 알림은 현재 비활성화 상태다.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class TamagotchiFarewellNotificationListener {

	private final NotificationService notificationService;

	@TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
	@Transactional(propagation = Propagation.REQUIRES_NEW)
	public void onTamagotchiFarewell(TamagotchiFarewellEvent event) {
		// 비활성화: 이별 시점 알림은 제거하고 독립 준비 완료 스케줄러에서 발송한다.
	}
}
