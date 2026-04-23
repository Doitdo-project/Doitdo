package com.doitdo.global.exception;

import org.springframework.http.HttpStatus;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum AuthErrorCode implements ErrorCode {

	// A00 - 로그인
	A00_001("A00-001", HttpStatus.UNAUTHORIZED, "아이디 또는 비밀번호가 올바르지 않습니다."),
	A00_002("A00-002", HttpStatus.LOCKED, "잠긴 계정입니다."),
	A00_003("A00-003", HttpStatus.UNPROCESSABLE_ENTITY, "필수 파라미터 누락 (email 또는 password)"),
	A00_004("A00-004", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// A01 - 토큰 재발급
	A01_001("A01-001", HttpStatus.UNAUTHORIZED, "리프레시 토큰이 없거나 유효하지 않음"),
	A01_002("A01-002", HttpStatus.UNAUTHORIZED, "만료된 리프레시 토큰"),
	A01_003("A01-003", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// A02 - 로그아웃
	A02_001("A02-001", HttpStatus.UNAUTHORIZED, "액세스 토큰이 없거나 유효하지 않음"),
	A02_002("A02-002", HttpStatus.UNAUTHORIZED, "만료된 액세스 토큰"),
	A02_003("A02-003", HttpStatus.UNAUTHORIZED, "리프레시 토큰이 없거나 유효하지 않음"),
	A02_004("A02-004", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// A03 - 소셜 로그인
	A03_001("A03-001", HttpStatus.UNAUTHORIZED, "소셜 액세스 토큰이 유효하지 않음"),
	A03_002("A03-002", HttpStatus.UNPROCESSABLE_ENTITY, "필수 파라미터 누락 (provider 또는 accessToken)"),
	A03_003("A03-003", HttpStatus.CONFLICT, "이미 가입된 소셜 계정"),
	A03_004("A03-004", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),
	A03_005("A03-005", HttpStatus.UNAUTHORIZED, "소셜 계정의 이메일이 검증되지 않았습니다."),
	A03_006("A03-006", HttpStatus.CONFLICT, "이미 일반 계정으로 가입된 이메일입니다. 아이디/비밀번호로 로그인해주세요.");

	private final String code;
	private final HttpStatus httpStatus;
	private final String defaultMessage;
}
