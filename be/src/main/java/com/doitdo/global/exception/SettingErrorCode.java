package com.doitdo.global.exception;

import org.springframework.http.HttpStatus;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum SettingErrorCode implements ErrorCode {

	// C00 - 설정 조회
	C00_001("C00-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	C00_002("C00-002", HttpStatus.NOT_FOUND, "설정 데이터를 찾을 수 없음"),
	C00_003("C00-003", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// C01 - 위젯 테마 설정
	C01_001("C01-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	C01_002("C01-002", HttpStatus.UNPROCESSABLE_ENTITY, "유효하지 않은 variant 값 (LIGHT|DARK 외)"),
	C01_003("C01-003", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// C02 - 테마 설정 조회
	C02_001("C02-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	C02_002("C02-002", HttpStatus.NOT_FOUND, "테마 설정 데이터를 찾을 수 없음"),
	C02_003("C02-003", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// C03 - 위젯 설정 조회
	C03_001("C03-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	C03_002("C03-002", HttpStatus.NOT_FOUND, "위젯 설정 데이터를 찾을 수 없음"),
	C03_003("C03-003", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// C04 - 화면 모드 설정
	C04_001("C04-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	C04_002("C04-002", HttpStatus.UNPROCESSABLE_ENTITY, "유효하지 않은 화면 모드 값 (HOME|CALENDAR 외)"),
	C04_003("C04-003", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// C05 - 알림 설정
	C05_001("C05-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	C05_002("C05-002", HttpStatus.NOT_FOUND, "알림 설정 데이터를 찾을 수 없음"),
	C05_003("C05-003", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류");

	private final String code;
	private final HttpStatus httpStatus;
	private final String defaultMessage;
}
