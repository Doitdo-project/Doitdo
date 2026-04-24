package com.doitdo.domain.tamagotchi.event;

/**
 * 다마고치 성장(부화 또는 진화) 시 발행되는 도메인 이벤트.
 *
 * <p>발행 시점:
 * <ul>
 *   <li>부화(HATCHED): {@code TamagotchiServiceImpl.hatch()} 내부, saveHistory 직후</li>
 *   <li>진화(EVOLVED): {@code TamagotchiServiceImpl.evolve()} 내부, saveHistory 직후</li>
 * </ul>
 * 수신자는 {@code AFTER_COMMIT} 단계에서 실행되므로 성장 처리가 커밋된 뒤 동작한다.
 *
 * @param userId          발행 주체 사용자 ID
 * @param userCharacterId 성장한 UserCharacter ID (referenceId 로 사용)
 * @param beforeStage     성장 이전 스테이지 (예: "EGG", "BABY", "TEEN")
 * @param afterStage      성장 이후 스테이지 (예: "BABY", "TEEN", "ADULT")
 * @param characterName   캐릭터 이름 (알림 본문에 표시)
 */
public record TamagotchiGrowthEvent(
		Long userId,
		Long userCharacterId,
		String beforeStage,
		String afterStage,
		String characterName
) {}
