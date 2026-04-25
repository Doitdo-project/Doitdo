package com.doitdo.domain.notification.application.listener;

import com.doitdo.domain.notification.application.NotificationService;
import com.doitdo.domain.tamagotchi.event.TamagotchiGrowthEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * 다마고치 성장(부화/진화) 이벤트를 구독해 FCM 알림을 발송하는 리스너.
 * HATCHED 와 EVOLVED 를 단일 리스너로 통합 처리한다.
 *
 * <p>설계 포인트:
 * <ul>
 *   <li>{@code AFTER_COMMIT}: 성장 처리가 커밋된 뒤에만 발동</li>
 *   <li>{@code REQUIRES_NEW}: 알림 처리를 별도 TX 로 격리 → 알림 실패가 성장 도메인에 영향 없음</li>
 *   <li>referenceId 는 성장한 UserCharacter 의 userCharacterId</li>
 * </ul>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class TamagotchiGrowthNotificationListener {

	private final NotificationService notificationService;

	@TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
	@Transactional(propagation = Propagation.REQUIRES_NEW)
	public void onTamagotchiGrowth(TamagotchiGrowthEvent event) {
		notificationService.sendTamagotchiGrowth(
				event.userId(), event.userCharacterId(), event.characterName(), event.afterStage());
	}
}
