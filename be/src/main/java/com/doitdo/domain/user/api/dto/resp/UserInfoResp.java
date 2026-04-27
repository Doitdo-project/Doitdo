package com.doitdo.domain.user.api.dto.resp;

import com.doitdo.domain.user.entity.User;

/**
 * 클라이언트에 노출되는 사용자 요약 정보. 로그인 / 소셜 로그인 / GET /me 응답에 동일하게 사용된다.
 *
 * <p>{@code hasPassword} 플래그는 클라이언트가 "비밀번호 변경" UI 노출 여부를 분기하기 위한 것.
 * 소셜 전용 가입자({@code password == null})에게는 비밀번호 변경 진입 자체를 숨겨
 * 시도 → 401 거절로 인한 UX 깨짐을 방지한다. 백엔드 정책 자체는
 * {@code UserServiceImpl.changePassword} 에서 별도 검증.
 *
 * <p>{@code birthDateRegistered} / {@code agreementsAccepted} 는 온보딩 단계 분기용.
 * 클라이언트가 진입 시 어느 온보딩 모달을 띄울지 판정한다.
 */
public record UserInfoResp(

		Long userId,
		String username,
		String email,
		boolean hasPassword,
		boolean birthDateRegistered,
		boolean agreementsAccepted
) {

	public static UserInfoResp from(User user) {
		return new UserInfoResp(
				user.getUserId(),
				user.getUsername(),
				user.getEmail(),
				user.getPassword() != null,
				user.getBirthDate() != null,
				user.getTermsAgreedAt() != null
		);
	}
}
