package com.doitdo.domain.health.api.controller;

import java.util.Map;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {

	private final JdbcTemplate jdbcTemplate;

	public HealthController(JdbcTemplate jdbcTemplate) {
		this.jdbcTemplate = jdbcTemplate;
	}

	@GetMapping("/hello")
	public Map<String, String> hello() {
		return Map.of(
			"status", "UP",
			"service", "doitdo"
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
