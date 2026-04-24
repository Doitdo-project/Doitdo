package com.doitdo.domain.tamagotchi.entity;

import com.doitdo.global.entity.BaseTimeEntity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@Table(name = "user_character_history")
@Builder
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class UserCharacterHistory extends BaseTimeEntity {

	public enum EventType {
		CREATED,
		NAME_UPDATED,
		HATCHED,
		EVOLVED,
		FAREWELL
	}

	public enum ActorType {
		USER,
		SYSTEM,
		ADMIN
	}

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "user_character_history_id")
	private Long userCharacterHistoryId;

	@Column(name = "user_character_id", nullable = false)
	private Long userCharacterId;

	@Column(name = "user_id", nullable = false)
	private Long userId;

	@Enumerated(EnumType.STRING)
	@Column(name = "event_type", nullable = false, length = 30)
	private EventType eventType;

	@Column(name = "before_character_id")
	private Long beforeCharacterId;

	@Column(name = "after_character_id")
	private Long afterCharacterId;

	@Column(name = "before_name", length = 50)
	private String beforeName;

	@Column(name = "after_name", length = 50)
	private String afterName;

	@Column(name = "before_exp")
	private Integer beforeExp;

	@Column(name = "after_exp")
	private Integer afterExp;

	@Column(name = "reason", length = 100)
	private String reason;

	@Column(name = "request_id", length = 100)
	private String requestId;

	@Enumerated(EnumType.STRING)
	@Column(name = "actor_type", nullable = false, length = 20)
	private ActorType actorType;

	@Column(name = "actor_id")
	private Long actorId;
}
