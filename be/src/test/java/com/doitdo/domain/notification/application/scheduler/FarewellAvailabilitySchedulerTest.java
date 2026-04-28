package com.doitdo.domain.notification.application.scheduler;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoMoreInteractions;

import com.doitdo.domain.notification.application.NotificationService;
import com.doitdo.domain.tamagotchi.entity.UserCharacter;
import com.doitdo.domain.tamagotchi.repository.UserCharacterRepository;
import com.doitdo.global.config.JpaAuditingConfig;
import jakarta.persistence.EntityManager;
import java.time.LocalDateTime;
import java.time.ZoneId;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.context.annotation.Import;

@DataJpaTest
@Import(JpaAuditingConfig.class)
class FarewellAvailabilitySchedulerTest {

	@Autowired
	private UserCharacterRepository userCharacterRepository;

	@Autowired
	private EntityManager entityManager;

	@Test
	void runSweepsOnlyDueActiveUnnotifiedUserCharacters() {
		NotificationService notificationService = mock(NotificationService.class);
		FarewellAvailabilityScheduler scheduler =
				new FarewellAvailabilityScheduler(userCharacterRepository, notificationService);
		LocalDateTime now = LocalDateTime.now(ZoneId.of("Asia/Seoul"));

		UserCharacter due = persistUserCharacter(1L, " ", now.minusMinutes(1), false, true, false);
		UserCharacter future = persistUserCharacter(2L, "future", now.plusHours(1), false, true, false);
		UserCharacter alreadyNotified = persistUserCharacter(3L, "notified", now.minusMinutes(1), true, true, false);
		UserCharacter inactive = persistUserCharacter(4L, "inactive", now.minusMinutes(1), false, false, false);
		UserCharacter deleted = persistUserCharacter(5L, "deleted", now.minusMinutes(1), false, true, true);
		entityManager.flush();
		Long dueId = due.getUserCharacterId();
		Long futureId = future.getUserCharacterId();
		Long alreadyNotifiedId = alreadyNotified.getUserCharacterId();
		Long inactiveId = inactive.getUserCharacterId();
		Long deletedId = deleted.getUserCharacterId();
		entityManager.clear();

		scheduler.run();
		entityManager.flush();
		entityManager.clear();

		assertThat(userCharacterRepository.findById(dueId).orElseThrow().getFarewellNotified()).isTrue();
		assertThat(userCharacterRepository.findById(futureId).orElseThrow().getFarewellNotified()).isFalse();
		assertThat(userCharacterRepository.findById(alreadyNotifiedId).orElseThrow().getFarewellNotified()).isTrue();
		assertThat(userCharacterRepository.findById(inactiveId).orElseThrow().getFarewellNotified()).isFalse();
		assertThat(userCharacterRepository.findById(deletedId).orElseThrow().getFarewellNotified()).isFalse();
		verify(notificationService).sendTamagotchiFarewell(1L, dueId, "다마고치");
		verifyNoMoreInteractions(notificationService);
	}

	private UserCharacter persistUserCharacter(
			Long userId,
			String name,
			LocalDateTime farewellAvailableAt,
			boolean farewellNotified,
			boolean isActive,
			boolean isDeleted) {
		UserCharacter userCharacter = UserCharacter.builder()
				.userId(userId)
				.characterId(100L + userId)
				.name(name)
				.currentExp(300)
				.isActive(isActive)
				.isDeleted(isDeleted)
				.farewellAvailableAt(farewellAvailableAt)
				.farewellNotified(farewellNotified)
				.build();
		entityManager.persist(userCharacter);
		return userCharacter;
	}
}
