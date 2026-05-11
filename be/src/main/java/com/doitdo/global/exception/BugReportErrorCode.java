package com.doitdo.global.exception;

import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;

@Getter
@RequiredArgsConstructor
public enum BugReportErrorCode implements ErrorCode {

	// B00 - 버그 신고 접수
	B00_001("B00-001", HttpStatus.INTERNAL_SERVER_ERROR, "버그 신고 처리 중 서버 오류가 발생했습니다.");

	private final String code;
	private final HttpStatus httpStatus;
	private final String defaultMessage;
}
