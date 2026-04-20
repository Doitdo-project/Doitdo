package com.doitdo.global.swagger;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springdoc.core.customizers.GlobalOperationCustomizer;
import org.springframework.context.annotation.Profile;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.method.HandlerMethod;

import com.doitdo.global.exception.ErrorCode;
import com.doitdo.global.exception.ErrorCodeRegistry;

import io.swagger.v3.oas.models.Operation;
import io.swagger.v3.oas.models.examples.Example;
import io.swagger.v3.oas.models.media.Content;
import io.swagger.v3.oas.models.media.MediaType;
import io.swagger.v3.oas.models.responses.ApiResponse;
import io.swagger.v3.oas.models.responses.ApiResponses;

/**
 * @ApiErrorCodes 어노테이션이 붙은 메서드에 Swagger 에러 응답 예시를 자동으로 주입한다.
 */
@Component
@Profile({"dev", "local"})
public class ApiErrorCodesCustomizer implements GlobalOperationCustomizer {

    @Override
    public Operation customize(Operation operation, HandlerMethod handlerMethod) {
        ApiErrorCodes annotation = handlerMethod.getMethodAnnotation(ApiErrorCodes.class);
        if (annotation == null || annotation.value().length == 0) {
            return operation;
        }

        // 코드 문자열 → ErrorCode 해석 및 HTTP status별 그룹핑
        Map<HttpStatus, List<ErrorCode>> byStatus = new LinkedHashMap<>();
        for (String code : annotation.value()) {
            ErrorCode errorCode = ErrorCodeRegistry.find(code)
                .orElseThrow(() -> new IllegalArgumentException(
                    "Unknown error code in @ApiErrorCodes on " + handlerMethod + ": " + code
                ));
            byStatus.computeIfAbsent(errorCode.getHttpStatus(), k -> new java.util.ArrayList<>())
                .add(errorCode);
        }

        ApiResponses responses = operation.getResponses();
        if (responses == null) {
            responses = new ApiResponses();
            operation.setResponses(responses);
        }

        for (Map.Entry<HttpStatus, List<ErrorCode>> entry : byStatus.entrySet()) {
            HttpStatus status = entry.getKey();
            String statusKey = String.valueOf(status.value());
            String description = status.value() + " " + status.getReasonPhrase();

            Map<String, Example> examples = new LinkedHashMap<>();
            for (ErrorCode errorCode : entry.getValue()) {
                Example example = new Example()
                    .summary(errorCode.getCode() + " — " + errorCode.getDefaultMessage())
                    .value(Map.of(
                        "status", status.value(),
                        "code", errorCode.getCode(),
                        "message", errorCode.getDefaultMessage()
                    ));
                examples.put(errorCode.getCode(), example);
            }

            ApiResponse apiResponse = new ApiResponse()
                .description(description)
                .content(new Content().addMediaType(
                    "application/json",
                    new MediaType().examples(examples)
                ));

            responses.addApiResponse(statusKey, apiResponse);
        }

        return operation;
    }
}
