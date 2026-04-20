package com.doitdo.global.exception;

import org.springframework.http.HttpStatus;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum TodoErrorCode implements ErrorCode {

	// T00 - TODO 생성
	T00_001("T00-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	T00_002("T00-002", HttpStatus.UNPROCESSABLE_ENTITY, "필수 파라미터 누락 또는 형식 오류"),
	T00_003("T00-003", HttpStatus.FORBIDDEN, "다른 사용자의 리소스에 접근 불가"),
	T00_004("T00-004", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// T01 - TODO 목록 조회
	T01_001("T01-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	T01_002("T01-002", HttpStatus.UNPROCESSABLE_ENTITY, "날짜 형식 오류 (YYYY-MM-DD 아닌 경우)"),
	T01_003("T01-003", HttpStatus.FORBIDDEN, "다른 사용자의 리소스에 접근 불가"),
	T01_004("T01-004", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// T02 - TODO 단건 조회
	T02_001("T02-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	T02_002("T02-002", HttpStatus.NOT_FOUND, "해당 TODO를 찾을 수 없음"),
	T02_003("T02-003", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// T03 - TODO 수정
	T03_001("T03-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	T03_002("T03-002", HttpStatus.NOT_FOUND, "해당 TODO를 찾을 수 없음"),
	T03_003("T03-003", HttpStatus.FORBIDDEN, "다른 사용자의 TODO 수정 불가"),
	T03_004("T03-004", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// T04 - TODO 삭제
	T04_001("T04-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	T04_002("T04-002", HttpStatus.NOT_FOUND, "해당 TODO를 찾을 수 없음"),
	T04_003("T04-003", HttpStatus.FORBIDDEN, "다른 사용자의 TODO 삭제 불가"),
	T04_004("T04-004", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// T05 - TODO 완료 처리
	T05_001("T05-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	T05_002("T05-002", HttpStatus.NOT_FOUND, "해당 TODO를 찾을 수 없음"),
	T05_003("T05-003", HttpStatus.FORBIDDEN, "다른 사용자의 TODO 완료 처리 불가"),
	T05_004("T05-004", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// T06 - TODO 반복 설정
	T06_001("T06-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	T06_002("T06-002", HttpStatus.NOT_FOUND, "해당 TODO를 찾을 수 없음"),
	T06_003("T06-003", HttpStatus.FORBIDDEN, "다른 사용자의 TODO 반복 설정 불가"),
	T06_004("T06-004", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// T07 - TODO 순서 변경
	T07_001("T07-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	T07_002("T07-002", HttpStatus.NOT_FOUND, "해당 TODO를 찾을 수 없음"),
	T07_003("T07-003", HttpStatus.FORBIDDEN, "다른 사용자의 TODO 순서 변경 불가"),
	T07_004("T07-004", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// T08 - TODO 카테고리 관리
	T08_001("T08-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	T08_002("T08-002", HttpStatus.NOT_FOUND, "해당 카테고리를 찾을 수 없음"),
	T08_003("T08-003", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// T09 - TODO 검색
	T09_001("T09-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	T09_002("T09-002", HttpStatus.UNPROCESSABLE_ENTITY, "검색 파라미터(q)가 누락되거나 빈 문자열"),
	T09_003("T09-003", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// T10 - TODO 통계 조회
	T10_001("T10-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	T10_002("T10-002", HttpStatus.UNPROCESSABLE_ENTITY, "날짜 범위 형식 오류"),
	T10_003("T10-003", HttpStatus.FORBIDDEN, "다른 사용자의 통계 조회 불가"),
	T10_004("T10-004", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// T11 - TODO 태그 관리
	T11_001("T11-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	T11_002("T11-002", HttpStatus.NOT_FOUND, "해당 태그를 찾을 수 없음"),
	T11_003("T11-003", HttpStatus.CONFLICT, "이미 존재하는 태그 이름"),
	T11_004("T11-004", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),

	// T12 - TODO 공유
	T12_001("T12-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
	T12_002("T12-002", HttpStatus.NOT_FOUND, "해당 TODO를 찾을 수 없음"),
	T12_003("T12-003", HttpStatus.FORBIDDEN, "공유 권한 없음"),
	T12_004("T12-004", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류");

	private final String code;
	private final HttpStatus httpStatus;
	private final String defaultMessage;
}
