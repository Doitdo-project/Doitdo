package com.doitdo.global.swagger;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;

import com.doitdo.global.exception.ErrorCode;

import io.swagger.v3.oas.models.examples.Example;
import io.swagger.v3.oas.models.media.Content;
import io.swagger.v3.oas.models.media.MediaType;
import io.swagger.v3.oas.models.responses.ApiResponse;
import io.swagger.v3.oas.models.responses.ApiResponses;

/**
 * Swagger ApiResponses 에 에러 응답을 병합 추가하는 유틸리티.
 * 같은 status 에 이미 example 이 있으면 유지(덮어쓰지 않음) — 명시 어노테이션 우선 원칙.
 */
public final class SwaggerResponseUtils {

    private SwaggerResponseUtils() {}

    /**
     * codes 를 HTTP status 별로 그룹핑하여 ApiResponses 에 병합한다.
     *
     * @param responses 대상 ApiResponses (null 이면 안 됨)
     * @param codes     부착할 ErrorCode 목록
     */
    public static void putOrMergeErrorResponse(ApiResponses responses, Iterable<ErrorCode> codes) {
        // status별 그룹핑
        Map<HttpStatus, List<ErrorCode>> byStatus = new LinkedHashMap<>();
        for (ErrorCode errorCode : codes) {
            byStatus.computeIfAbsent(errorCode.getHttpStatus(), k -> new java.util.ArrayList<>())
                .add(errorCode);
        }

        for (Map.Entry<HttpStatus, List<ErrorCode>> entry : byStatus.entrySet()) {
            HttpStatus status = entry.getKey();
            String statusKey = String.valueOf(status.value());
            String description = status.value() + " " + status.getReasonPhrase();

            // 기존 ApiResponse 가져오거나 새로 생성
            ApiResponse apiResponse = responses.get(statusKey);
            if (apiResponse == null) {
                apiResponse = new ApiResponse().description(description);
                responses.addApiResponse(statusKey, apiResponse);
            }

            // content > application/json 확보
            if (apiResponse.getContent() == null) {
                apiResponse.setContent(new Content());
            }
            Content content = apiResponse.getContent();

            MediaType mediaType = content.get("application/json");
            if (mediaType == null) {
                mediaType = new MediaType();
                content.addMediaType("application/json", mediaType);
            }

            if (mediaType.getExamples() == null) {
                mediaType.setExamples(new LinkedHashMap<>());
            }

            // example 추가 — 같은 키가 이미 있으면 유지(명시 어노테이션 우선)
            for (ErrorCode errorCode : entry.getValue()) {
                if (!mediaType.getExamples().containsKey(errorCode.getCode())) {
                    Example example = new Example()
                        .summary(errorCode.getCode() + " — " + errorCode.getDefaultMessage())
                        .value(Map.of(
                            "status", status.value(),
                            "code", errorCode.getCode(),
                            "message", errorCode.getDefaultMessage()
                        ));
                    mediaType.getExamples().put(errorCode.getCode(), example);
                }
            }
        }
    }
}
