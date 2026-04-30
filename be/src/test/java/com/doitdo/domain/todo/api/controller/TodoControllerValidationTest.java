package com.doitdo.domain.todo.api.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.doitdo.domain.todo.application.TodoService;
import com.doitdo.global.exception.GlobalExceptionHandler;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Map;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

/**
 * Todo 입력 길이 검증 테스트 — JIRA S14P31D107-466
 * <p>
 * title: 최대 20자 / content: 최대 100자
 * 위반 시 {@code GlobalExceptionHandler} 가 422 Unprocessable Entity 로 응답한다.
 */
@ExtendWith(MockitoExtension.class)
class TodoControllerValidationTest {

    @Mock
    private TodoService todoService;

    private MockMvc mockMvc;
    private ObjectMapper objectMapper;

    @BeforeEach
    void setUp() {
        TodoController controller = new TodoController(todoService);
        mockMvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
        objectMapper = new ObjectMapper();
        objectMapper.findAndRegisterModules(); // LocalDate 직렬화 지원
    }

    // ─────────────────────────────────────────────────
    // POST /api/todos — title 경계값
    // ─────────────────────────────────────────────────

    @Test
    @DisplayName("POST /api/todos — title 20자 정상 허용")
    void createTitle20Ok() throws Exception {
        String body = objectMapper.writeValueAsString(Map.of(
                "title", "a".repeat(20),
                "type", "NORMAL"
        ));
        // 서비스 호출까지 가면 200-range. 테스트 범위는 Controller 검증 레이어만.
        // 실제 service Mock 없이 create 는 NPE 가능하므로 2xx 혹은 5xx 모두 비-422 임을 확인.
        mockMvc.perform(post("/api/todos")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(result -> {
                    int status = result.getResponse().getStatus();
                    // 422 가 아니어야 한다 — 검증 통과
                    assert status != 422 : "20자 title 은 검증을 통과해야 합니다";
                });
    }

    @Test
    @DisplayName("POST /api/todos — title 21자 초과 시 422")
    void createTitle21Returns422() throws Exception {
        String body = objectMapper.writeValueAsString(Map.of(
                "title", "a".repeat(21),
                "type", "NORMAL"
        ));
        mockMvc.perform(post("/api/todos")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isUnprocessableEntity());
    }

    @Test
    @DisplayName("POST /api/todos — title 공백 시 422 (@NotBlank)")
    void createTitleBlankReturns422() throws Exception {
        String body = objectMapper.writeValueAsString(Map.of(
                "title", "",
                "type", "NORMAL"
        ));
        mockMvc.perform(post("/api/todos")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isUnprocessableEntity());
    }

    @Test
    @DisplayName("POST /api/todos — content 100자 정상 허용")
    void createContent100Ok() throws Exception {
        String body = objectMapper.writeValueAsString(Map.of(
                "title", "정상 제목",
                "content", "a".repeat(100),
                "type", "NORMAL"
        ));
        mockMvc.perform(post("/api/todos")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(result -> {
                    int status = result.getResponse().getStatus();
                    assert status != 422 : "100자 content 는 검증을 통과해야 합니다";
                });
    }

    @Test
    @DisplayName("POST /api/todos — content 101자 초과 시 422")
    void createContent101Returns422() throws Exception {
        String body = objectMapper.writeValueAsString(Map.of(
                "title", "정상 제목",
                "content", "a".repeat(101),
                "type", "NORMAL"
        ));
        mockMvc.perform(post("/api/todos")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isUnprocessableEntity());
    }

    @Test
    @DisplayName("POST /api/todos — content null(미입력) 허용")
    void createContentNullOk() throws Exception {
        // content 키를 아예 제외하면 null → @Size 미적용, 정상 통과
        String body = "{\"title\":\"정상 제목\",\"type\":\"NORMAL\"}";
        mockMvc.perform(post("/api/todos")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(result -> {
                    int status = result.getResponse().getStatus();
                    assert status != 422 : "content null 은 검증을 통과해야 합니다";
                });
    }

    // ─────────────────────────────────────────────────
    // PATCH /api/todos/{todoId} — UpdateReq 경계값
    // ─────────────────────────────────────────────────

    @Test
    @DisplayName("PATCH /api/todos/{todoId} — title 21자 초과 시 422")
    void updateTitle21Returns422() throws Exception {
        String body = objectMapper.writeValueAsString(Map.of(
                "title", "a".repeat(21)
        ));
        mockMvc.perform(patch("/api/todos/1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isUnprocessableEntity());
    }

    @Test
    @DisplayName("PATCH /api/todos/{todoId} — content 101자 초과 시 422")
    void updateContent101Returns422() throws Exception {
        String body = objectMapper.writeValueAsString(Map.of(
                "title", "정상 제목",
                "content", "a".repeat(101)
        ));
        mockMvc.perform(patch("/api/todos/1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isUnprocessableEntity());
    }

    @Test
    @DisplayName("PATCH /api/todos/{todoId} — title 없이도 통과 (부분 수정, @NotBlank 없음)")
    void updateTitleOmittedOk() throws Exception {
        String body = "{\"content\":\"메모내용\"}";
        mockMvc.perform(patch("/api/todos/1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(result -> {
                    int status = result.getResponse().getStatus();
                    assert status != 422 : "title 생략(null)은 검증을 통과해야 합니다";
                });
    }
}
