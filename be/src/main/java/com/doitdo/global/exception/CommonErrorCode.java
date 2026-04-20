package com.doitdo.global.exception;

import org.springframework.http.HttpStatus;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum CommonErrorCode implements ErrorCode {

	BAD_REQUEST("G00-001", HttpStatus.BAD_REQUEST, "잘못된 요청입니다."),
	UNAUTHORIZED("G00-002", HttpStatus.UNAUTHORIZED, "인증이 필요합니다."),
	FORBIDDEN("G00-003", HttpStatus.FORBIDDEN, "접근 권한이 없습니다."),
	NOT_FOUND("G00-004", HttpStatus.NOT_FOUND, "대상을 찾을 수 없습니다."),
	CONFLICT("G00-005", HttpStatus.CONFLICT, "요청이 현재 상태와 충돌합니다."),
	VALIDATION_FAILED("G00-006", HttpStatus.UNPROCESSABLE_ENTITY, "유효성 검증에 실패했습니다."),
	INTERNAL_SERVER_ERROR("G99-999", HttpStatus.INTERNAL_SERVER_ERROR, "서버 오류가 발생했습니다.");

	private final String code;
	private final HttpStatus httpStatus;
	private final String defaultMessage;
}
