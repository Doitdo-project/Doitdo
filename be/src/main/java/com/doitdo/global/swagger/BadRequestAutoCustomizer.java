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
 * 모든 Operation 에 400 Bad Request(G00-001) 응답을 자동으로 부착한다.
 */
@Component
@Profile({"dev", "local"})
public class BadRequestAutoCustomizer implements GlobalOperationCustomizer {

    @Override
    public Operation customize(Operation operation, HandlerMethod handlerMethod) {
        ApiResponses responses = operation.getResponses();
        if (responses == null) {
            responses = new ApiResponses();
            operation.setResponses(responses);
        }

        SwaggerResponseUtils.putOrMergeErrorResponse(responses, List.of(CommonErrorCode.BAD_REQUEST));

        return operation;
    }
}
