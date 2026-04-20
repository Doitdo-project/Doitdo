package com.doitdo.domain.health.api.dto.resp;

public class HelloResp {

	private final String service;
	private final String profile;

	public HelloResp(String service, String profile) {
		this.service = service;
		this.profile = profile;
	}

	public String getService() {
		return service;
	}

	public String getProfile() {
		return profile;
	}
}
