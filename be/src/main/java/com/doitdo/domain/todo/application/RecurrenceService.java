package com.doitdo.domain.todo.application;

import com.doitdo.domain.todo.api.dto.req.TodoCalendarReq;
import com.doitdo.domain.todo.api.dto.req.TodoSnoozeReq;
import com.doitdo.domain.todo.api.dto.resp.TodoCalendarResp;
import com.doitdo.domain.todo.entity.Todo;
import java.time.LocalDate;

public interface RecurrenceService {

	TodoCalendarResp calendar(Long userId, TodoCalendarReq req);

	/**
	 * RECURRING 마스터면 occurrenceDate 기반으로 on-demand 실체화하여 NORMAL 인스턴스를 반환.
	 * NORMAL/PERIOD 면 전달받은 todo 를 그대로 반환.
	 * @throws com.doitdo.global.exception.CustomException T05_004 (RECURRING 인데 occurrenceDate 유효하지 않음)
	 */
	Todo materializeRecurringIfNeeded(Long userId, Todo todo, TodoSnoozeReq req);

	/**
	 * RECURRING 마스터의 특정 발생일을 on-demand 실체화하여 NORMAL 인스턴스를 반환.
	 * @throws com.doitdo.global.exception.CustomException T03_004 (occurrenceDate 유효하지 않음)
	 */
	Todo materializeRecurringOccurrence(Long userId, Todo master, LocalDate occurrenceDate);
}
