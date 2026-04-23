package com.doitdo.domain.user.api.dto.req;

import jakarta.validation.constraints.Size;

/**
 * 회원탈퇴 요청 바디.
 *
 * <p>일반 계정은 {@code currentPassword} 를 반드시 보내야 한다.
 * OAuth 전용 계정은 access token 인증으로 충분하므로 해당 필드를 null 또는 생략 가능.
 * 서비스 단에서 계정 유형(password==null 여부) 을 보고 판단한다.
 */
public record WithdrawReq(

		@Size(max = 255)
		String currentPassword
) {
}
