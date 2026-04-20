package com.doitdo.global.exception;

import java.util.stream.Collectors;

import org.springframework.http.ResponseEntity;
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
	public ResponseEntity<GlobalApiResponse<Void>> handleCustomException(CustomException e) {
		log.warn("CustomException: {}", e.getMessage());
		ErrorCode errorCode = e.getErrorCode();
		return ResponseEntity
			.status(errorCode.getHttpStatus())
			.body(GlobalApiResponse.fail(errorCode, e.getMessage()));
	}

	@ExceptionHandler(MethodArgumentNotValidException.class)
	public ResponseEntity<GlobalApiResponse<Void>> handleValidation(MethodArgumentNotValidException e) {
		String message = e.getBindingResult().getFieldErrors().stream()
			.map(fe -> fe.getField() + ": " + fe.getDefaultMessage())
			.collect(Collectors.joining(", "));
		return ResponseEntity
			.status(CommonErrorCode.VALIDATION_FAILED.getHttpStatus())
			.body(GlobalApiResponse.fail(CommonErrorCode.VALIDATION_FAILED, message));
	}

	@ExceptionHandler({NoResourceFoundException.class, NoHandlerFoundException.class})
	public ResponseEntity<GlobalApiResponse<Void>> handleNotFound(Exception e) {
		return ResponseEntity
			.status(CommonErrorCode.NOT_FOUND.getHttpStatus())
			.body(GlobalApiResponse.fail(CommonErrorCode.NOT_FOUND));
	}

	@ExceptionHandler(IllegalArgumentException.class)
	public ResponseEntity<GlobalApiResponse<Void>> handleIllegalArgument(IllegalArgumentException e) {
		return ResponseEntity
			.status(CommonErrorCode.BAD_REQUEST.getHttpStatus())
			.body(GlobalApiResponse.fail(CommonErrorCode.BAD_REQUEST, e.getMessage()));
	}

	@ExceptionHandler(Exception.class)
	public ResponseEntity<GlobalApiResponse<Void>> handleException(Exception e) {
		log.error("Server Exception: ", e);
		return ResponseEntity
			.status(CommonErrorCode.INTERNAL_SERVER_ERROR.getHttpStatus())
			.body(GlobalApiResponse.fail(CommonErrorCode.INTERNAL_SERVER_ERROR));
	}
}
