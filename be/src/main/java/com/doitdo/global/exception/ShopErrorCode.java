package com.doitdo.global.exception;

import org.springframework.http.HttpStatus;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum ShopErrorCode implements ErrorCode {

	// S prefix - 상점 (no API specifications defined yet)
	;

	private final String code;
	private final HttpStatus httpStatus;
	private final String defaultMessage;
}
