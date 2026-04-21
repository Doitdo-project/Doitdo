package com.doitdo.global.health;

import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.doitdo.global.exception.GlobalExceptionHandler;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.core.env.Environment;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

@ExtendWith(MockitoExtension.class)
class HealthControllerWebMvcTest {

	@Mock
	private Environment environment;

	@Mock
	private JdbcTemplate jdbcTemplate;

	private MockMvc mockMvc;

	@BeforeEach
	void setUp() {
		HealthController healthController = new HealthController(environment, jdbcTemplate);
		mockMvc = MockMvcBuilders.standaloneSetup(healthController)
			.setControllerAdvice(new GlobalExceptionHandler())
			.build();
	}

	@Test
	void helloReturnsGlobalApiResponse() throws Exception {
		given(environment.getActiveProfiles()).willReturn(new String[] {"dev"});

		mockMvc.perform(get("/hello"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.status").value(200))
			.andExpect(jsonPath("$.message").value("OK"))
			.andExpect(jsonPath("$.data.service").value("doitdo"))
			.andExpect(jsonPath("$.data.profile").value("dev"))
			.andExpect(jsonPath("$.data.status").value("UP"))
			.andExpect(jsonPath("$.data.startedAt").isNotEmpty());
	}

	@Test
	void dbCheckReturnsGlobalApiResponse() throws Exception {
		given(jdbcTemplate.queryForObject("SELECT 1", Integer.class)).willReturn(1);

		mockMvc.perform(get("/db-check"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.status").value(200))
			.andExpect(jsonPath("$.message").value("OK"))
			.andExpect(jsonPath("$.data.database").value("CONNECTED"))
			.andExpect(jsonPath("$.data.result").value(1));
	}
}
