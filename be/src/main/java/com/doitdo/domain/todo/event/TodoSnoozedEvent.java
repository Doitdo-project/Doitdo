package com.doitdo.domain.todo.event;

import java.time.LocalDate;

/**
 * TODO 가 미뤄졌을 때 발행되는 도메인 이벤트.
 *
 * <p>발행 시점: {@code TodoServiceImpl.snooze()} 내부, snoozeHistory 저장 직후.
 * 수신자는 {@code AFTER_COMMIT} 단계에서 실행되므로 snooze 저장이 커밋된 뒤 동작한다.
 */
public record TodoSnoozedEvent(
		Long userId,
		Long todoId,
		LocalDate fromDate,
		LocalDate toDate
) {}
