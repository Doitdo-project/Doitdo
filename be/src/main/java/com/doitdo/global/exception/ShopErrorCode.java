package com.doitdo.global.exception;

import org.springframework.http.HttpStatus;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum ShopErrorCode implements ErrorCode {

	// S prefix - 상점
	FURNITURE_NOT_FOUND("S00-001", HttpStatus.NOT_FOUND, "가구를 찾을 수 없습니다."),
	FURNITURE_ALREADY_OWNED("S00-002", HttpStatus.CONFLICT, "이미 보유한 가구입니다."),
	INSUFFICIENT_BALANCE("S00-003", HttpStatus.CONFLICT, "잔액이 부족합니다."),
	FURNITURE_NOT_ON_SALE("S00-004", HttpStatus.CONFLICT, "판매 중인 가구가 아닙니다."),
	WALLET_NOT_FOUND("S00-005", HttpStatus.NOT_FOUND, "월렛을 찾을 수 없습니다."),
	USER_FURNITURE_NOT_FOUND("S01-001", HttpStatus.NOT_FOUND, "보유 가구를 찾을 수 없습니다."),
	PLACEMENT_NOT_FOUND("S02-001", HttpStatus.NOT_FOUND, "배치 정보를 찾을 수 없습니다."),
	THEME_NOT_FOUND("S03-001", HttpStatus.NOT_FOUND, "테마를 찾을 수 없습니다."),
	THEME_CATEGORY_DUPLICATED("S03-002", HttpStatus.CONFLICT, "테마에 같은 카테고리 가구가 중복되어 있습니다."),
	THEME_EMPTY("S03-003", HttpStatus.UNPROCESSABLE_ENTITY, "테마에 구매할 가구가 없습니다."),
	THEME_ALREADY_OWNED("S03-010", HttpStatus.CONFLICT, "이미 테마 풀세트를 보유하고 있습니다.")
	;

	private final String code;
	private final HttpStatus httpStatus;
	private final String defaultMessage;
}
