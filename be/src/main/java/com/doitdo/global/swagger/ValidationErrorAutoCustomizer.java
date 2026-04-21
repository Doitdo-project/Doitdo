package com.doitdo.global.swagger;

import java.util.List;

import org.springdoc.core.customizers.GlobalOperationCustomizer;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.method.HandlerMethod;

import com.doitdo.global.exception.CommonErrorCode;

import io.swagger.v3.oas.models.Operation;
import io.swagger.v3.oas.models.responses.ApiResponses;
import jakarta.validation.Valid;

/**
 * 메서드 파라미터 중 {@link Valid} 또는 {@link Validated} 어노테이션이 하나라도 있으면
 * 422 Unprocessable Entity(G00-006) 응답을 자동으로 부착한다.
 */
@Component
@Profile({"dev", "local"})
public class ValidationErrorAutoCustomizer implements GlobalOperationCustomizer {

    @Override
    public Operation customize(Operation operation, HandlerMethod handlerMethod) {
        boolean hasValidation = false;
        for (org.springframework.core.MethodParameter param : handlerMethod.getMethodParameters()) {
            if (param.hasParameterAnnotation(Valid.class)
                || param.hasParameterAnnotation(Validated.class)) {
                hasValidation = true;
                break;
            }
        }

        if (!hasValidation) {
            return operation;
        }

        ApiResponses responses = operation.getResponses();
        if (responses == null) {
            responses = new ApiResponses();
            operation.setResponses(responses);
        }

        SwaggerResponseUtils.putOrMergeErrorResponse(responses, List.of(CommonErrorCode.VALIDATION_FAILED));

        return operation;
    }
}
