package com.doitdo.domain.auth.api.dto.resp;

import com.doitdo.domain.user.api.dto.resp.UserInfoResp;

public record LoginResp(

		String accessToken,
		String refreshToken,
		UserInfoResp user
) {
}
