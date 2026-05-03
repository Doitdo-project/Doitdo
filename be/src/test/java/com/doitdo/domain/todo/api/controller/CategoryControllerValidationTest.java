package com.doitdo.domain.todo.api.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.doitdo.domain.todo.application.CategoryService;
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

@ExtendWith(MockitoExtension.class)
class CategoryControllerValidationTest {

	@Mock
	private CategoryService categoryService;

	private MockMvc mockMvc;
	private ObjectMapper objectMapper;

	@BeforeEach
	void setUp() {
		CategoryController controller = new CategoryController(categoryService);
		mockMvc = MockMvcBuilders.standaloneSetup(controller)
				.setControllerAdvice(new GlobalExceptionHandler())
				.build();
		objectMapper = new ObjectMapper();
	}

	@Test
	@DisplayName("POST /api/categories — name 10자 정상 허용")
	void createName10Ok() throws Exception {
		String body = objectMapper.writeValueAsString(Map.of(
				"name", "a".repeat(10),
				"colorId", 1
		));

		mockMvc.perform(post("/api/categories")
						.contentType(MediaType.APPLICATION_JSON)
						.content(body))
				.andExpect(result -> {
					int status = result.getResponse().getStatus();
					assert status != 422 : "10자 name 은 검증을 통과해야 합니다";
				});
	}

	@Test
	@DisplayName("POST /api/categories — name 11자 초과 시 422")
	void createName11Returns422() throws Exception {
		String body = objectMapper.writeValueAsString(Map.of(
				"name", "a".repeat(11),
				"colorId", 1
		));

		mockMvc.perform(post("/api/categories")
						.contentType(MediaType.APPLICATION_JSON)
						.content(body))
				.andExpect(status().isUnprocessableEntity());
	}

	@Test
	@DisplayName("PATCH /api/categories/{categoryId} — name 10자 정상 허용")
	void updateName10Ok() throws Exception {
		String body = objectMapper.writeValueAsString(Map.of(
				"name", "a".repeat(10)
		));

		mockMvc.perform(patch("/api/categories/1")
						.contentType(MediaType.APPLICATION_JSON)
						.content(body))
				.andExpect(result -> {
					int status = result.getResponse().getStatus();
					assert status != 422 : "10자 name 은 검증을 통과해야 합니다";
				});
	}

	@Test
	@DisplayName("PATCH /api/categories/{categoryId} — name 11자 초과 시 422")
	void updateName11Returns422() throws Exception {
		String body = objectMapper.writeValueAsString(Map.of(
				"name", "a".repeat(11)
		));

		mockMvc.perform(patch("/api/categories/1")
						.contentType(MediaType.APPLICATION_JSON)
						.content(body))
				.andExpect(status().isUnprocessableEntity());
	}
}
