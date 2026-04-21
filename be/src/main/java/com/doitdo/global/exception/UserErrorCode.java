package com.doitdo.global.exception;

import org.springframework.http.HttpStatus;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum UserErrorCode implements ErrorCode {

	// U00 - 회원가입
	U00_001("U00-001", HttpStatus.CONFLICT, "이미 사용 중인 이메일"),
	U00_002("U00-002", HttpStatus.UNPROCESSABLE_ENTITY, "필수 파라미터 누락 또는 형식 오류"),
	U00_003("U00-003", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),
	U00_004("U00-004", HttpStatus.CONFLICT, "이미 사용 중인 닉네임"),

	// U01 - 내 정보 조회
	U01_001("U01-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	U01_002("U01-002", HttpStatus.NOT_FOUND, "사용자를 찾을 수 없음"),
	U01_003("U01-003", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// U02 - 내 정보 수정
	U02_001("U02-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	U02_002("U02-002", HttpStatus.NOT_FOUND, "사용자를 찾을 수 없음"),
	U02_003("U02-003", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// U03 - 비밀번호 변경
	U03_001("U03-001", HttpStatus.UNAUTHORIZED, "현재 비밀번호가 일치하지 않음"),
	U03_002("U03-002", HttpStatus.UNPROCESSABLE_ENTITY, "새 비밀번호 형식 오류"),
	U03_003("U03-003", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// U04 - 회원 탈퇴
	U04_001("U04-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	U04_002("U04-002", HttpStatus.NOT_FOUND, "사용자를 찾을 수 없음"),
	U04_003("U04-003", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류");

	private final String code;
	private final HttpStatus httpStatus;
	private final String defaultMessage;
}
