package com.doitdo.global.swagger;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Swagger 자동 인증 응답(401/403) 부착에서 제외하는 마커.
 * SecurityConfig 의 PUBLIC_ENDPOINTS 와 정합성 유지 책임은 작성자에게 있음.
 */
@Target({ElementType.TYPE, ElementType.METHOD})
@Retention(RetentionPolicy.RUNTIME)
public @interface PublicApi {
}
