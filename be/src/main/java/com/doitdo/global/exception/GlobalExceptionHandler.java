package com.doitdo.global.exception;

import com.doitdo.global.api.response.GlobalApiResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

@RestControllerAdvice
public class GlobalExceptionHandler {

	private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

	@ExceptionHandler(CustomException.class)
	public ResponseEntity<GlobalApiResponse<Void>> handleCustom(CustomException e) {
		ErrorCode code = e.getErrorCode();
		return ResponseEntity
			.status(code.getStatus())
			.body(GlobalApiResponse.fail(code.getStatus(), e.getMessage()));
	}

	@ExceptionHandler(MethodArgumentTypeMismatchException.class)
	public ResponseEntity<GlobalApiResponse<Void>> handleTypeMismatch(MethodArgumentTypeMismatchException e) {
		return ResponseEntity
			.status(HttpStatus.BAD_REQUEST)
			.body(GlobalApiResponse.fail(HttpStatus.BAD_REQUEST, ErrorCode.TYPE_MISMATCH.getMessage()));
	}

	@ExceptionHandler(IllegalArgumentException.class)
	public ResponseEntity<GlobalApiResponse<Void>> handleIllegalArgument(IllegalArgumentException e) {
		return ResponseEntity
			.status(HttpStatus.BAD_REQUEST)
			.body(GlobalApiResponse.fail(HttpStatus.BAD_REQUEST, e.getMessage()));
	}

	@ExceptionHandler(Exception.class)
	public ResponseEntity<GlobalApiResponse<Void>> handleException(Exception e) {
		log.error("Server Exception", e);
		return ResponseEntity
			.status(HttpStatus.INTERNAL_SERVER_ERROR)
			.body(GlobalApiResponse.fail(HttpStatus.INTERNAL_SERVER_ERROR, ErrorCode.INTERNAL_ERROR.getMessage()));
	}
}
