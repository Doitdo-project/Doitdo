package com.doitdo.domain.user.api.dto.resp;

import com.doitdo.domain.user.entity.User;

public record UserInfoResp(

		Long userId,
		String username,
		String email
) {

	public static UserInfoResp from(User user) {
		return new UserInfoResp(user.getUserId(), user.getUsername(), user.getEmail());
	}
}
