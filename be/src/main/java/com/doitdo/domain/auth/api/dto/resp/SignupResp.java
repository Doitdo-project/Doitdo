package com.doitdo.domain.auth.api.dto.resp;

public record SignupResp(

		Long userId,
		String email,
		String username,
		boolean birthDateRegistered,
		boolean agreementsAccepted
) {
}
