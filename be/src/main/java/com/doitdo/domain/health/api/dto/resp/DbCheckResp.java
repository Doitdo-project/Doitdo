package com.doitdo.domain.health.api.dto.resp;

public class DbCheckResp {

	private final String database;
	private final Integer result;

	public DbCheckResp(String database, Integer result) {
		this.database = database;
		this.result = result;
	}

	public String getDatabase() {
		return database;
	}

	public Integer getResult() {
		return result;
	}
}
