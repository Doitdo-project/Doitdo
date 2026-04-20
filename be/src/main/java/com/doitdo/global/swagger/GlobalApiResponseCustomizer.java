package com.doitdo.global.swagger;

import java.util.Map;

import org.springdoc.core.customizers.GlobalOperationCustomizer;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.web.method.HandlerMethod;

import com.doitdo.global.exception.CommonErrorCode;
import com.doitdo.global.exception.ErrorCode;

import io.swagger.v3.oas.models.Operation;
import io.swagger.v3.oas.models.examples.Example;
import io.swagger.v3.oas.models.media.Content;
import io.swagger.v3.oas.models.media.MediaType;
import io.swagger.v3.oas.models.responses.ApiResponse;
import io.swagger.v3.oas.models.responses.ApiResponses;

/**
 * 모든 Operation에 500 Internal Server Error(G99-999) 응답을 자동으로 부착한다.
 */
@Component
@Profile({"dev", "local"})
public class GlobalApiResponseCustomizer implements GlobalOperationCustomizer {

    private static final ErrorCode INTERNAL_ERROR = CommonErrorCode.INTERNAL_SERVER_ERROR;
    private static final String STATUS_KEY = "500";
    private static final String DESCRIPTION = "500 Internal Server Error";

    @Override
    public Operation customize(Operation operation, HandlerMethod handlerMethod) {
        ApiResponses responses = operation.getResponses();
        if (responses == null) {
            responses = new ApiResponses();
            operation.setResponses(responses);
        }

        Example example = new Example()
            .summary(INTERNAL_ERROR.getCode() + " — " + INTERNAL_ERROR.getDefaultMessage())
            .value(Map.of(
                "status", 500,
                "code", INTERNAL_ERROR.getCode(),
                "message", INTERNAL_ERROR.getDefaultMessage()
            ));

        ApiResponse apiResponse = new ApiResponse()
            .description(DESCRIPTION)
            .content(new Content().addMediaType(
                "application/json",
                new MediaType().addExamples(INTERNAL_ERROR.getCode(), example)
            ));

        responses.addApiResponse(STATUS_KEY, apiResponse);

        return operation;
    }
}
