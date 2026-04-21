package com.doitdo.global.health;

import com.doitdo.domain.health.api.dto.resp.DbCheckResp;
import com.doitdo.domain.health.api.dto.resp.HelloResp;
import com.doitdo.global.api.response.GlobalApiResponse;
import com.doitdo.global.swagger.ApiErrorCodes;
import com.doitdo.global.swagger.PublicApi;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.core.env.Environment;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "global", description = "헬스체크")
@PublicApi
@RestController
public class HealthController {

	private final Environment environment;
	private final JdbcTemplate jdbcTemplate;

	public HealthController(Environment environment, JdbcTemplate jdbcTemplate) {
		this.environment = environment;
		this.jdbcTemplate = jdbcTemplate;
	}

	@Operation(summary = "hello", description = "서비스 이름과 활성 프로파일 반환")
	@GetMapping("/hello")
	public GlobalApiResponse<HelloResp> hello() {
		String[] activeProfiles = environment.getActiveProfiles();
		String profile = activeProfiles.length > 0 ? activeProfiles[0] : "default";

		return GlobalApiResponse.ok(new HelloResp("doitdo", profile));
	}

	@Operation(summary = "db-check", description = "DB 연결 확인")
	@ApiErrorCodes({"G00-004"})
	@GetMapping("/db-check")
	public GlobalApiResponse<DbCheckResp> dbCheck() {
		Integer result = jdbcTemplate.queryForObject("SELECT 1", Integer.class);

		return GlobalApiResponse.ok(new DbCheckResp("CONNECTED", result));
	}
}
