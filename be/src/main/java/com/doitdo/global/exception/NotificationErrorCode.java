package com.doitdo.global.exception;

import org.springframework.http.HttpStatus;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum NotificationErrorCode implements ErrorCode {

	// N00 - 알림 목록 조회
	N00_001("N00-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	N00_002("N00-002", HttpStatus.NOT_FOUND, "사용자를 찾을 수 없음"),
	N00_003("N00-003", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// N01 - 알림 읽음 처리
	N01_001("N01-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	N01_002("N01-002", HttpStatus.NOT_FOUND, "해당 알림을 찾을 수 없음"),
	N01_003("N01-003", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// N02 - 알림 전체 읽음 처리
	N02_001("N02-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	N02_002("N02-002", HttpStatus.NOT_FOUND, "사용자를 찾을 수 없음"),
	N02_003("N02-003", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// N03 - 알림 삭제
	N03_001("N03-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	N03_002("N03-002", HttpStatus.NOT_FOUND, "해당 알림을 찾을 수 없음"),
	N03_003("N03-003", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류");

	private final String code;
	private final HttpStatus httpStatus;
	private final String defaultMessage;
}
