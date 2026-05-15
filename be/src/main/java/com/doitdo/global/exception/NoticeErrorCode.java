package com.doitdo.global.exception;

import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;

@Getter
@RequiredArgsConstructor
public enum NoticeErrorCode implements ErrorCode {

	// O00 - 공지사항 조회
	O00_001("O00-001", HttpStatus.NOT_FOUND, "공지사항을 찾을 수 없습니다.");

	private final String code;
	private final HttpStatus httpStatus;
	private final String defaultMessage;
}
