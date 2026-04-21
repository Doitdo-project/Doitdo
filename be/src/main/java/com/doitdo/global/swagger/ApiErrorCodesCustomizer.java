package com.doitdo.global.swagger;

import java.util.ArrayList;
import java.util.List;

import org.springdoc.core.customizers.GlobalOperationCustomizer;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.web.method.HandlerMethod;

import com.doitdo.global.exception.ErrorCode;
import com.doitdo.global.exception.ErrorCodeRegistry;

import io.swagger.v3.oas.models.Operation;
import io.swagger.v3.oas.models.responses.ApiResponses;

/**
 * @ApiErrorCodes 어노테이션이 붙은 메서드에 Swagger 에러 응답 예시를 자동으로 주입한다.
 * 같은 status 에 이미 응답이 있으면 examples 를 병합한다 (SwaggerResponseUtils 사용).
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

        // 코드 문자열 → ErrorCode 해석
        List<ErrorCode> errorCodes = new ArrayList<>();
        for (String code : annotation.value()) {
            ErrorCode errorCode = ErrorCodeRegistry.find(code)
                .orElseThrow(() -> new IllegalArgumentException(
                    "Unknown error code in @ApiErrorCodes on " + handlerMethod + ": " + code
                ));
            errorCodes.add(errorCode);
        }

        ApiResponses responses = operation.getResponses();
        if (responses == null) {
            responses = new ApiResponses();
            operation.setResponses(responses);
        }

        SwaggerResponseUtils.putOrMergeErrorResponse(responses, errorCodes);

        return operation;
    }
}
