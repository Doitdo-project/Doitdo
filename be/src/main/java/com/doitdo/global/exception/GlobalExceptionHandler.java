package com.doitdo.global.exception;

import java.util.stream.Collectors;

import jakarta.servlet.http.HttpServletRequest;

import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.NoHandlerFoundException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import com.doitdo.global.api.response.GlobalApiResponse;

import lombok.extern.slf4j.Slf4j;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

	@ExceptionHandler(CustomException.class)
	public ResponseEntity<GlobalApiResponse<Void>> handleCustomException(CustomException e, HttpServletRequest request) {
		ErrorCode errorCode = e.getErrorCode();
		if (errorCode.getHttpStatus().is5xxServerError()) {
			log.warn("CustomException uri=\"{} {}\" code={} status={} message=\"{}\"",
				request.getMethod(), request.getRequestURI(), errorCode.getCode(), errorCode.getHttpStatus().value(),
				e.getMessage(), e);
		} else {
			log.warn("CustomException uri=\"{} {}\" code={} status={} message=\"{}\"",
				request.getMethod(), request.getRequestURI(), errorCode.getCode(), errorCode.getHttpStatus().value(),
				e.getMessage());
		}
		return ResponseEntity
			.status(errorCode.getHttpStatus())
			.body(GlobalApiResponse.fail(errorCode, e.getMessage()));
	}

	@ExceptionHandler(MethodArgumentNotValidException.class)
	public ResponseEntity<GlobalApiResponse<Void>> handleValidation(
			MethodArgumentNotValidException e, HttpServletRequest request) {
		String message = e.getBindingResult().getFieldErrors().stream()
			.map(fe -> fe.getField() + ": " + fe.getDefaultMessage())
			.collect(Collectors.joining(", "));
		log.warn("Validation Exception uri=\"{} {}\" message=\"{}\"",
			request.getMethod(), request.getRequestURI(), message);
		return ResponseEntity
			.status(CommonErrorCode.VALIDATION_FAILED.getHttpStatus())
			.body(GlobalApiResponse.fail(CommonErrorCode.VALIDATION_FAILED, message));
	}

	@ExceptionHandler(HttpMessageNotReadableException.class)
	public ResponseEntity<GlobalApiResponse<Void>> handleHttpMessageNotReadable(
			HttpMessageNotReadableException e, HttpServletRequest request) {
		String causeMessage = e.getMostSpecificCause().getMessage();
		log.warn("HttpMessageNotReadable Exception uri=\"{} {}\" message=\"{}\"",
			request.getMethod(), request.getRequestURI(), causeMessage);
		return ResponseEntity
			.status(CommonErrorCode.VALIDATION_FAILED.getHttpStatus())
			.body(GlobalApiResponse.fail(CommonErrorCode.VALIDATION_FAILED,
				"요청 본문 형식이 올바르지 않습니다: " + causeMessage));
	}

	@ExceptionHandler({NoResourceFoundException.class, NoHandlerFoundException.class})
	public ResponseEntity<GlobalApiResponse<Void>> handleNotFound(Exception e, HttpServletRequest request) {
		log.info("NotFound Exception uri=\"{} {}\" message=\"{}\"",
			request.getMethod(), request.getRequestURI(), e.getMessage());
		return ResponseEntity
			.status(CommonErrorCode.NOT_FOUND.getHttpStatus())
			.body(GlobalApiResponse.fail(CommonErrorCode.NOT_FOUND));
	}

	@ExceptionHandler(IllegalArgumentException.class)
	public ResponseEntity<GlobalApiResponse<Void>> handleIllegalArgument(
			IllegalArgumentException e, HttpServletRequest request) {
		log.warn("IllegalArgument Exception uri=\"{} {}\" message=\"{}\"",
			request.getMethod(), request.getRequestURI(), e.getMessage());
		return ResponseEntity
			.status(CommonErrorCode.BAD_REQUEST.getHttpStatus())
			.body(GlobalApiResponse.fail(CommonErrorCode.BAD_REQUEST, e.getMessage()));
	}

	@ExceptionHandler(Exception.class)
	public ResponseEntity<GlobalApiResponse<Void>> handleException(Exception e, HttpServletRequest request) {
		log.error("Unhandled Exception uri=\"{} {}\"", request.getMethod(), request.getRequestURI(), e);
		return ResponseEntity
			.status(CommonErrorCode.INTERNAL_SERVER_ERROR.getHttpStatus())
			.body(GlobalApiResponse.fail(CommonErrorCode.INTERNAL_SERVER_ERROR));
	}
}
