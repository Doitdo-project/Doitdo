package com.doitdo.global.swagger;

import java.util.List;

import org.springdoc.core.customizers.GlobalOperationCustomizer;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.web.method.HandlerMethod;

import com.doitdo.global.exception.CommonErrorCode;

import io.swagger.v3.oas.models.Operation;
import io.swagger.v3.oas.models.responses.ApiResponses;

/**
 * {@link PublicApi} 마커가 없는 모든 Operation 에
 * 401 Unauthorized(G00-002), 403 Forbidden(G00-003) 응답을 자동으로 부착한다.
 * 메서드 또는 컨트롤러 클래스에 {@link PublicApi} 가 있으면 skip.
 */
@Component
@Profile({"dev", "local"})
public class AuthRequiredAutoCustomizer implements GlobalOperationCustomizer {

    @Override
    public Operation customize(Operation operation, HandlerMethod handlerMethod) {
        // 메서드 레벨 확인
        if (handlerMethod.hasMethodAnnotation(PublicApi.class)) {
            return operation;
        }
        // 클래스 레벨 확인
        if (handlerMethod.getBeanType().isAnnotationPresent(PublicApi.class)) {
            return operation;
        }

        ApiResponses responses = operation.getResponses();
        if (responses == null) {
            responses = new ApiResponses();
            operation.setResponses(responses);
        }

        SwaggerResponseUtils.putOrMergeErrorResponse(
            responses,
            List.of(CommonErrorCode.UNAUTHORIZED, CommonErrorCode.FORBIDDEN)
        );

        return operation;
    }
}
