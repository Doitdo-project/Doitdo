package com.doitdo.global.exception;

import org.springframework.http.HttpStatus;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum TamagotchiErrorCode implements ErrorCode {

	// M00 - independence approval
	M00_001("M00-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	M00_002("M00-002", HttpStatus.UNPROCESSABLE_ENTITY, "성체 상태가 아닌 캐릭터는 독립 불가"),
	M00_003("M00-003", HttpStatus.CONFLICT, "이미 독립 처리된 캐릭터"),
	M00_004("M00-004", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// M01 - character name
	M01_001("M01-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	M01_002("M01-002", HttpStatus.NOT_FOUND, "다마고치를 찾을 수 없음"),
	M01_003("M01-003", HttpStatus.UNPROCESSABLE_ENTITY, "캐릭터 이름은 1자 이상 20자 이하여야 함"),
	M01_004("M01-004", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// M02 - hatch
	M02_001("M02-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	M02_002("M02-002", HttpStatus.NOT_FOUND, "다마고치를 찾을 수 없음"),
	M02_003("M02-003", HttpStatus.UNPROCESSABLE_ENTITY, "알 상태의 캐릭터만 부화할 수 있음"),
	M02_004("M02-004", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// M03 - encyclopedia
	M03_001("M03-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	M03_002("M03-002", HttpStatus.NOT_FOUND, "다마고치를 찾을 수 없음"),
	M03_003("M03-003", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// M04 - current character
	M04_001("M04-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	M04_002("M04-002", HttpStatus.NOT_FOUND, "다마고치를 찾을 수 없음"),
	M04_003("M04-003", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// M05 - evolution
	M05_001("M05-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	M05_002("M05-002", HttpStatus.NOT_FOUND, "다마고치를 찾을 수 없음"),
	M05_003("M05-003", HttpStatus.UNPROCESSABLE_ENTITY, "상태가 진화 조건에 맞지 않음"),
	M05_004("M05-004", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),
	M05_005("M05-005", HttpStatus.CONFLICT, "이미 진화했거나 추가 진화가 불가함"),

	// M06 - history
	M06_001("M06-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	M06_002("M06-002", HttpStatus.NOT_FOUND, "다마고치를 찾을 수 없음"),
	M06_003("M06-003", HttpStatus.FORBIDDEN, "다른 사용자의 히스토리 조회 불가"),
	M06_004("M06-004", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// M07 - rename
	M07_001("M07-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	M07_002("M07-002", HttpStatus.NOT_FOUND, "다마고치를 찾을 수 없음"),
	M07_003("M07-003", HttpStatus.FORBIDDEN, "다른 사용자의 다마고치 이름 변경 불가"),
	M07_004("M07-004", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// M08 - inventory
	M08_001("M08-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	M08_002("M08-002", HttpStatus.NOT_FOUND, "다마고치를 찾을 수 없음"),
	M08_003("M08-003", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류");

	private final String code;
	private final HttpStatus httpStatus;
	private final String defaultMessage;
}
