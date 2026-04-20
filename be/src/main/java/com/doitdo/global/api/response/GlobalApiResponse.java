package com.doitdo.global.api.response;

import org.springframework.http.HttpStatus;

import com.doitdo.global.exception.ErrorCode;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonPropertyOrder;

import lombok.Getter;

@Getter
@JsonPropertyOrder({"status", "code", "message", "data"})
public class GlobalApiResponse<T> {

	private final int status;

	@JsonInclude(JsonInclude.Include.NON_NULL)
	private final String code;

	private final String message;
	private final T data;

	private GlobalApiResponse(int status, String code, String message, T data) {
		this.status = status;
		this.code = code;
		this.message = message;
		this.data = data;
	}

	// ── 성공 팩토리 ──────────────────────────────────────────────────

	public static <T> GlobalApiResponse<T> of(HttpStatus httpStatus, String message, T data) {
		return new GlobalApiResponse<>(httpStatus.value(), null, message, data);
	}

	public static <T> GlobalApiResponse<T> ok(T data) {
		return of(HttpStatus.OK, "OK", data);
	}

	public static <T> GlobalApiResponse<T> ok(String message, T data) {
		return of(HttpStatus.OK, message, data);
	}

	public static <T> GlobalApiResponse<T> created(String message, T data) {
		return of(HttpStatus.CREATED, message, data);
	}

	public static GlobalApiResponse<Void> noContent(String message) {
		return of(HttpStatus.NO_CONTENT, message, null);
	}

	// ── 실패 팩토리 ──────────────────────────────────────────────────

	/** 기존 호환 유지 — code 없이 status + message 만 */
	public static GlobalApiResponse<Void> fail(HttpStatus httpStatus, String message) {
		return new GlobalApiResponse<>(httpStatus.value(), null, message, null);
	}

	public static GlobalApiResponse<Void> fail(HttpStatus httpStatus, String code, String message) {
		return new GlobalApiResponse<>(httpStatus.value(), code, message, null);
	}

	public static GlobalApiResponse<Void> fail(ErrorCode errorCode) {
		return new GlobalApiResponse<>(
			errorCode.getHttpStatus().value(),
			errorCode.getCode(),
			errorCode.getDefaultMessage(),
			null
		);
	}

	public static GlobalApiResponse<Void> fail(ErrorCode errorCode, String overrideMessage) {
		return new GlobalApiResponse<>(
			errorCode.getHttpStatus().value(),
			errorCode.getCode(),
			overrideMessage,
			null
		);
	}
}
