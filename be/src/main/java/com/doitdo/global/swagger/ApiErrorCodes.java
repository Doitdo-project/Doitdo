package com.doitdo.global.swagger;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * 메서드에 적용하면 Swagger 문서에 해당 에러 코드들이 자동으로 추가된다.
 * value에는 ErrorCode.getCode() 가 반환하는 문자열 코드를 사용한다 (예: "A00-001").
 */
@Target({ElementType.METHOD})
@Retention(RetentionPolicy.RUNTIME)
public @interface ApiErrorCodes {

    /** ErrorCode.getCode() 가 반환하는 문자열 코드 (예: "A00-001") */
    String[] value();
}
