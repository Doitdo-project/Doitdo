package com.doitdo.domain.health.api.dto.resp;

public class HelloResp {

	private final String service;
	private final String profile;
	private final String status;
	private final String startedAt;

	public HelloResp(String service, String profile, String status, String startedAt) {
		this.service = service;
		this.profile = profile;
		this.status = status;
		this.startedAt = startedAt;
	}

	public String getService() {
		return service;
	}

	public String getProfile() {
		return profile;
	}

	public String getStatus() {
		return status;
	}

	public String getStartedAt() {
		return startedAt;
	}
}
