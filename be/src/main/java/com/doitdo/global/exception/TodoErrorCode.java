package com.doitdo.global.exception;

import org.springframework.http.HttpStatus;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum TodoErrorCode implements ErrorCode {

	// T00 - GET /todos/{todoId} (상세 조회)
	T00_001("T00-001", HttpStatus.NOT_FOUND, "해당 TODO를 찾을 수 없음"),
	T00_002("T00-002", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	T00_003("T00-003", HttpStatus.FORBIDDEN, "다른 사용자의 TODO에 접근 불가"),
	T00_004("T00-004", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// T01 - DELETE /todos/{todoId} (삭제)
	T01_001("T01-001", HttpStatus.NOT_FOUND, "삭제할 TODO를 찾을 수 없음"),
	T01_002("T01-002", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	T01_003("T01-003", HttpStatus.FORBIDDEN, "다른 사용자의 TODO 삭제 불가"),
	T01_004("T01-004", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// T02 - GET /todos (목록 조회)
	T02_001("T02-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	T02_002("T02-002", HttpStatus.UNPROCESSABLE_ENTITY, "필터 파라미터 형식 오류 (날짜 형식 잘못됨)"),
	T02_003("T02-003", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// T03 - PATCH /todos/{todoId}/status (상태 변경)
	T03_001("T03-001", HttpStatus.NOT_FOUND, "해당 TODO를 찾을 수 없음"),
	T03_002("T03-002", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	T03_003("T03-003", HttpStatus.FORBIDDEN, "다른 사용자의 TODO 상태 변경 불가"),
	T03_004("T03-004", HttpStatus.UNPROCESSABLE_ENTITY, "유효하지 않은 상태 값으로 변경 시도"),

	// T04 - PATCH /todos/{todoId} (수정)
	T04_001("T04-001", HttpStatus.NOT_FOUND, "수정할 TODO를 찾을 수 없음"),
	T04_002("T04-002", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	T04_003("T04-003", HttpStatus.FORBIDDEN, "다른 사용자의 TODO 수정 불가"),
	T04_004("T04-004", HttpStatus.UNPROCESSABLE_ENTITY, "진행 중 또는 완료된 TODO는 수정 불가"),
	T04_005("T04-005", HttpStatus.UNPROCESSABLE_ENTITY, "유효하지 않은 카테고리 ID 지정"),

	// T05 - POST /todos/{todoId}/snooze (미루기)
	T05_001("T05-001", HttpStatus.NOT_FOUND, "미루기할 TODO를 찾을 수 없음"),
	T05_002("T05-002", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	T05_003("T05-003", HttpStatus.FORBIDDEN, "다른 사용자의 TODO 미루기 불가"),
	T05_004("T05-004", HttpStatus.UNPROCESSABLE_ENTITY, "반복 TODO 미루기 시 occurrenceDate 필수"),

	// T06 - POST /todos (작성)
	T06_001("T06-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	T06_002("T06-002", HttpStatus.UNPROCESSABLE_ENTITY, "필수 파라미터 누락 (title 등)"),
	T06_003("T06-003", HttpStatus.UNPROCESSABLE_ENTITY, "유효하지 않은 카테고리 ID 지정"),
	T06_004("T06-004", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// T07 - PATCH /todos/{todoId}/priority (우선순위 변경)
	T07_001("T07-001", HttpStatus.NOT_FOUND, "해당 TODO를 찾을 수 없음"),
	T07_002("T07-002", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	T07_003("T07-003", HttpStatus.FORBIDDEN, "다른 사용자의 TODO 우선순위 변경 불가"),
	T07_004("T07-004", HttpStatus.UNPROCESSABLE_ENTITY, "유효하지 않은 우선순위 값 지정"),

	// T08 - GET /todos/calendar (캘린더 조회)
	T08_001("T08-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	T08_002("T08-002", HttpStatus.UNPROCESSABLE_ENTITY, "날짜 범위 지정 오류 (from/to 형식 오류 또는 from > to)"),
	T08_003("T08-003", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// T09 - GET /todos/search (검색)
	T09_001("T09-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	T09_002("T09-002", HttpStatus.UNPROCESSABLE_ENTITY, "검색 파라미터(q)가 누락되거나 빈 문자열"),
	T09_003("T09-003", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// T10 - POST /categories (카테고리 추가)
	T10_001("T10-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	T10_002("T10-002", HttpStatus.UNPROCESSABLE_ENTITY, "카테고리 이름 또는 색상 누락"),
	T10_003("T10-003", HttpStatus.UNPROCESSABLE_ENTITY, "카테고리 최대 6개 초과"),
	T10_004("T10-004", HttpStatus.CONFLICT, "중복된 카테고리 이름"),

	// T11 - DELETE /categories/{categoryId} (카테고리 삭제)
	T11_001("T11-001", HttpStatus.NOT_FOUND, "카테고리를 찾을 수 없음"),
	T11_002("T11-002", HttpStatus.UNAUTHORIZED, "인증되지 않은 요청"),
	T11_003("T11-003", HttpStatus.FORBIDDEN, "삭제 권한 없음 (고정 카테고리 또는 타인 소유)"),
	T11_004("T11-004", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// T12 - PATCH /categories/{categoryId} (카테고리 수정)
	T12_001("T12-001", HttpStatus.NOT_FOUND, "카테고리를 찾을 수 없음"),
	T12_002("T12-002", HttpStatus.UNAUTHORIZED, "인증되지 않은 요청"),
	T12_003("T12-003", HttpStatus.UNPROCESSABLE_ENTITY, "입력값 유효성 검사 실패 (이름 누락 등)"),
	T12_004("T12-004", HttpStatus.CONFLICT, "중복된 카테고리 이름");

	private final String code;
	private final HttpStatus httpStatus;
	private final String defaultMessage;
}
