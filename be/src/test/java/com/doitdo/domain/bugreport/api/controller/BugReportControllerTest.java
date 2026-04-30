package com.doitdo.domain.bugreport.api.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.doitdo.domain.auth.application.CustomUserDetails;
import com.doitdo.domain.bugreport.api.dto.req.CreateBugReportReq;
import com.doitdo.domain.bugreport.api.dto.resp.BugReportResp;
import com.doitdo.domain.bugreport.application.BugReportService;
import com.doitdo.domain.user.entity.User;
import com.doitdo.global.api.response.GlobalApiResponse;
import com.doitdo.global.exception.GlobalExceptionHandler;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.LocalDateTime;
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
class BugReportControllerTest {

	@Mock
	private BugReportService bugReportService;

	private MockMvc mockMvc;
	private ObjectMapper objectMapper;
	private CustomUserDetails userDetails;

	@BeforeEach
	void setUp() {
		BugReportController controller = new BugReportController(bugReportService);
		mockMvc = MockMvcBuilders.standaloneSetup(controller)
				.setControllerAdvice(new GlobalExceptionHandler())
				.build();
		objectMapper = new ObjectMapper();

		User user = User.builder()
				.userId(1L)
				.email("test@example.com")
				.username("testuser")
				.password("password")
				.isDeleted(false)
				.build();
		userDetails = new CustomUserDetails(user);
	}

	@Test
	@DisplayName("정상 요청 시 201 Created 와 bugReportId, createdAt 을 반환한다")
	void createReturns201WithBugReportId() {
		LocalDateTime createdAt = LocalDateTime.of(2026, 4, 30, 14, 23, 10);
		BugReportResp resp = new BugReportResp(7L, createdAt);

		given(bugReportService.create(eq(1L), any(CreateBugReportReq.class))).willReturn(resp);

		BugReportController controller = new BugReportController(bugReportService);
		CreateBugReportReq req = new CreateBugReportReq("할 일 완료 버튼 버그", "버튼 클릭 시 화면이 멈춥니다.");

		GlobalApiResponse<BugReportResp> response = controller.create(userDetails, req);

		assertThat(response.getStatus()).isEqualTo(201);
		assertThat(response.getMessage()).isEqualTo("버그 신고가 접수되었습니다.");
		assertThat(response.getData().bugReportId()).isEqualTo(7L);
		assertThat(response.getData().createdAt()).isEqualTo(createdAt);
	}

	@Test
	@DisplayName("title 이 비어있으면 422 Unprocessable Entity 를 반환한다")
	void createReturns422WhenTitleBlank() throws Exception {
		String requestBody = """
				{
				  "title": "",
				  "content": "내용입니다."
				}
				""";

		mockMvc.perform(post("/api/bug-reports")
						.contentType(MediaType.APPLICATION_JSON)
						.content(requestBody))
				.andExpect(status().isUnprocessableEntity());
	}

	@Test
	@DisplayName("content 가 500자를 초과하면 422 Unprocessable Entity 를 반환한다")
	void createReturns422WhenContentTooLong() throws Exception {
		String longContent = "a".repeat(501);
		String requestBody = objectMapper.writeValueAsString(
				new CreateBugReportReq("정상 제목", longContent)
		);

		mockMvc.perform(post("/api/bug-reports")
						.contentType(MediaType.APPLICATION_JSON)
						.content(requestBody))
				.andExpect(status().isUnprocessableEntity());
	}
}
