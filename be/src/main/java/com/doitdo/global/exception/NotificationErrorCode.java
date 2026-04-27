package com.doitdo.global.exception;

import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;

@Getter
@RequiredArgsConstructor
public enum NotificationErrorCode implements ErrorCode {

	// N00 - 알림 설정 변경
	N00_001("N00-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	N00_002("N00-002", HttpStatus.UNPROCESSABLE_ENTITY, "시간 형식이 올바르지 않습니다. HH:mm 형식을 사용하세요."),
	N00_003("N00-003", HttpStatus.INTERNAL_SERVER_ERROR, "알림 설정 변경 중 서버 오류가 발생했습니다."),

	// N01 - 알림 설정 조회
	N01_001("N01-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	N01_002("N01-002", HttpStatus.NOT_FOUND, "알림 설정이 존재하지 않습니다."),
	N01_003("N01-003", HttpStatus.INTERNAL_SERVER_ERROR, "알림 설정 조회 중 서버 오류가 발생했습니다."),

	// N02 - 디바이스 토큰 해제
	N02_001("N02-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	N02_002("N02-002", HttpStatus.NOT_FOUND, "등록되지 않은 FCM 토큰입니다."),
	N02_003("N02-003", HttpStatus.INTERNAL_SERVER_ERROR, "디바이스 토큰 해제 중 서버 오류가 발생했습니다."),

	// N03 - 디바이스 토큰 등록
	N03_001("N03-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	N03_002("N03-002", HttpStatus.UNPROCESSABLE_ENTITY, "필수 파라미터가 누락되었습니다."),
	N03_003("N03-003", HttpStatus.INTERNAL_SERVER_ERROR, "디바이스 토큰 등록 중 서버 오류가 발생했습니다."),

	// N04 - 알림 목록 조회
	N04_001("N04-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	N04_002("N04-002", HttpStatus.INTERNAL_SERVER_ERROR, "알림 목록 조회 중 서버 오류가 발생했습니다."),

	// N05 - 알림 읽음
	N05_001("N05-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	N05_002("N05-002", HttpStatus.FORBIDDEN, "다른 사용자의 알림에는 접근할 수 없습니다."),
	N05_003("N05-003", HttpStatus.NOT_FOUND, "알림이 존재하지 않습니다."),
	N05_004("N05-004", HttpStatus.INTERNAL_SERVER_ERROR, "알림 읽음 처리 중 서버 오류가 발생했습니다."),

	// N06 - 알림 전체 읽음
	N06_001("N06-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	N06_002("N06-002", HttpStatus.INTERNAL_SERVER_ERROR, "전체 읽음 처리 중 서버 오류가 발생했습니다."),

	// N07 - 알림 삭제
	N07_001("N07-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	N07_002("N07-002", HttpStatus.FORBIDDEN, "다른 사용자의 알림은 삭제할 수 없습니다."),
	N07_003("N07-003", HttpStatus.NOT_FOUND, "알림이 존재하지 않습니다."),
	N07_004("N07-004", HttpStatus.INTERNAL_SERVER_ERROR, "알림 삭제 중 서버 오류가 발생했습니다.");

	private final String code;
	private final HttpStatus httpStatus;
	private final String defaultMessage;
}
