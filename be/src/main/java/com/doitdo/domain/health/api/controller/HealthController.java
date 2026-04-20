package com.doitdo.domain.health.api.controller;

import java.util.Map;

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
	public Map<String, Object> hello() {
		String[] activeProfiles = environment.getActiveProfiles();
		String profile = activeProfiles.length > 0 ? activeProfiles[0] : "default";

		return Map.of(
			"status", "UP",
			"service", "doitdo",
			"profile", profile
		);
	}

	@GetMapping("/db-check")
	public Map<String, Object> dbCheck() {
		Integer result = jdbcTemplate.queryForObject("SELECT 1", Integer.class);

		return Map.of(
			"status", "UP",
			"database", "CONNECTED",
			"result", result
		);
	}
}
