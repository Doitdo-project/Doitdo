package com.doitdo.domain.tamagotchi.event;

/**
 * 다마고치 독립 승인 시 발행되는 도메인 이벤트.
 *
 * <p>발행 시점: {@code TamagotchiServiceImpl.approveIndependence()} 내부, saveHistory 직후.
 * 수신자는 {@code AFTER_COMMIT} 단계에서 실행되므로 이별 처리가 커밋된 뒤 동작한다.
 *
 * @param userId                발행 주체 사용자 ID
 * @param beforeUserCharacterId 독립한 어덜트 캐릭터의 userCharacterId
 * @param afterUserCharacterId  새로 생성된 EGG 캐릭터의 userCharacterId (referenceId 로 사용)
 * @param beforeCharacterName   독립한 캐릭터의 이름 (알림 본문에 표시)
 */
public record TamagotchiFarewellEvent(
		Long userId,
		Long beforeUserCharacterId,
		Long afterUserCharacterId,
		String beforeCharacterName
) {}
