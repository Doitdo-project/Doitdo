package com.doitdo.domain.health.api.controller;

import com.doitdo.domain.health.api.dto.resp.DbCheckResp;
import com.doitdo.domain.health.api.dto.resp.HelloResp;
import com.doitdo.global.api.response.GlobalApiResponse;
import org.springframework.core.env.Environment;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {

	private final Environment environment;
	private final JdbcTemplate jdbcTemplate;

	public HealthController(Environment environment, JdbcTemplate jdbcTemplate) {
		this.environment = environment;
		this.jdbcTemplate = jdbcTemplate;
	}

	@GetMapping("/hello")
	public GlobalApiResponse<HelloResp> hello() {
		String[] activeProfiles = environment.getActiveProfiles();
		String profile = activeProfiles.length > 0 ? activeProfiles[0] : "default";

		return GlobalApiResponse.ok(new HelloResp("doitdo", profile));
	}

	@GetMapping("/db-check")
	public GlobalApiResponse<DbCheckResp> dbCheck() {
		Integer result = jdbcTemplate.queryForObject("SELECT 1", Integer.class);

		return GlobalApiResponse.ok(new DbCheckResp("CONNECTED", result));
	}
}
