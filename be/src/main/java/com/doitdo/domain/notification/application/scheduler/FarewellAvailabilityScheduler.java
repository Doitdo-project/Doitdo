package com.doitdo.domain.notification.application.scheduler;

import com.doitdo.domain.notification.application.NotificationService;
import com.doitdo.domain.tamagotchi.entity.UserCharacter;
import com.doitdo.domain.tamagotchi.repository.UserCharacterRepository;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(
		name = "notification.farewell-available.enabled",
		havingValue = "true",
		matchIfMissing = true)
public class FarewellAvailabilityScheduler {

	private final UserCharacterRepository userCharacterRepository;
	private final NotificationService notificationService;

	@Scheduled(cron = "0 * * * * *", zone = "Asia/Seoul")
	@Transactional
	public void run() {
		LocalDateTime now = LocalDateTime.now(ZoneId.of("Asia/Seoul"));
		List<UserCharacter> targets = userCharacterRepository.findFarewellAvailableTargets(now);
		for (UserCharacter uc : targets) {
			try {
				uc.markFarewellNotified();
				String name = (uc.getName() == null || uc.getName().isBlank()) ? "다마고치" : uc.getName();
				notificationService.sendTamagotchiFarewell(uc.getUserId(), uc.getUserCharacterId(), name);
			} catch (Exception ex) {
				log.warn("[farewell-available] send failed userCharacterId={}", uc.getUserCharacterId(), ex);
			}
		}
	}
}
