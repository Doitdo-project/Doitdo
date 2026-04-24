package com.doitdo.domain.todo.event;

/**
 * TODO 가 DONE 으로 전이되었을 때 발행되는 도메인 이벤트.
 * 수신자: Tamagotchi 도메인 (exp 지급), 향후 추가 가능 (알림/통계 등).
 *
 * <p>발행 시점: {@code TodoServiceImpl.changeStatus()} 내부, DONE 전이 확정 시.
 * 수신자는 {@code AFTER_COMMIT} 단계에서 실행되므로 Todo 저장이 커밋된 뒤 동작한다.
 */
public record TodoCompletedEvent(
		Long userId,
		Long todoId
) {}
