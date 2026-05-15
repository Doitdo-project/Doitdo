package com.doitdo.domain.auth.api.controller;

import com.doitdo.domain.auth.api.dto.req.LoginReq;
import com.doitdo.domain.auth.api.dto.req.OAuthLoginReq;
import com.doitdo.domain.auth.api.dto.req.PasswordResetReq;
import com.doitdo.domain.auth.api.dto.req.PasswordResetRequestReq;
import com.doitdo.domain.auth.api.dto.req.PasswordResetVerifyCodeReq;
import com.doitdo.domain.auth.api.dto.req.RefreshTokenReq;
import com.doitdo.domain.auth.api.dto.req.SignupReq;
import com.doitdo.domain.auth.api.dto.resp.LoginResp;
import com.doitdo.domain.auth.api.dto.resp.OAuthLoginResp;
import com.doitdo.domain.auth.api.dto.resp.PasswordResetVerifyCodeResp;
import com.doitdo.domain.auth.api.dto.resp.SignupResp;
import com.doitdo.domain.auth.api.dto.resp.TokenResp;
import com.doitdo.domain.auth.application.AuthService;
import com.doitdo.domain.auth.application.CustomUserDetails;
import com.doitdo.domain.auth.application.OAuthService;
import com.doitdo.domain.auth.entity.OAuthProvider;
import com.doitdo.global.api.response.GlobalApiResponse;
import com.doitdo.global.swagger.ApiErrorCodes;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "auth", description = "인증 관련 API")
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

	private final AuthService authService;
	private final OAuthService oauthService;

	@Operation(summary = "회원가입", description = "이메일·비밀번호·닉네임으로 회원가입")
	@PostMapping("/signup")
	@ResponseStatus(HttpStatus.CREATED)
	public GlobalApiResponse<SignupResp> signup(@Valid @RequestBody SignupReq req) {
		return GlobalApiResponse.created("회원가입 성공", authService.signup(req));
	}

	@Operation(summary = "로그인", description = "아이디·비밀번호로 로그인하여 토큰 및 사용자 정보 반환")
	@PostMapping("/login")
	public GlobalApiResponse<LoginResp> login(@Valid @RequestBody LoginReq req) {
		return GlobalApiResponse.ok("로그인 성공", authService.login(req));
	}

	@Operation(summary = "토큰 재발급", description = "리프레시 토큰으로 액세스·리프레시 토큰 재발급")
	@PostMapping("/refresh")
	public GlobalApiResponse<TokenResp> refresh(@Valid @RequestBody RefreshTokenReq req) {
		return GlobalApiResponse.ok("토큰 재발급 성공", authService.refresh(req));
	}

	@Operation(summary = "로그아웃", description = "리프레시 토큰을 삭제하여 로그아웃")
	@DeleteMapping("/logout")
	public GlobalApiResponse<Void> logout(@AuthenticationPrincipal CustomUserDetails userDetails) {
		authService.logout(userDetails.getUserId());
		return GlobalApiResponse.ok("로그아웃 성공", null);
	}

	@Operation(summary = "소셜 로그인", description = "카카오/구글/애플 소셜 SDK 토큰을 검증하여 서비스 JWT 발급")
	@PostMapping("/social/{provider}")
	public GlobalApiResponse<OAuthLoginResp> oauthLogin(
			@PathVariable OAuthProvider provider,
			@Valid @RequestBody OAuthLoginReq req) {
		return GlobalApiResponse.ok("소셜 로그인 성공", oauthService.login(provider, req));
	}

	@Operation(
			summary = "비밀번호 재설정 요청",
			description = "이메일로 6자리 인증번호(OTP)를 발송. 미가입자는 200 OK(정보 노출 방지), 소셜 가입자는 409 A04-006."
	)
	@ApiErrorCodes({"A04-006"})
	@PostMapping("/password/reset-request")
	public GlobalApiResponse<Void> requestPasswordReset(@Valid @RequestBody PasswordResetRequestReq req) {
		authService.requestPasswordReset(req);
		return GlobalApiResponse.ok("비밀번호 재설정 인증번호를 발송했습니다.", null);
	}

	@Operation(
			summary = "비밀번호 재설정 코드 검증",
			description = "이메일·6자리 OTP 검증. 성공 시 새 비밀번호 설정에 사용할 짧은 reset 토큰을 반환."
	)
	@ApiErrorCodes({"A04-001", "A04-004", "A04-005"})
	@PostMapping("/password/reset/verify-code")
	public GlobalApiResponse<PasswordResetVerifyCodeResp> verifyPasswordResetCode(
			@Valid @RequestBody PasswordResetVerifyCodeReq req) {
		return GlobalApiResponse.ok("인증번호가 확인되었습니다.", authService.verifyCode(req));
	}

	@Operation(
			summary = "비밀번호 재설정",
			description = "verify-code 에서 발급받은 resetToken 으로 새 비밀번호로 변경. 성공 시 기존 모든 기기 로그아웃."
	)
	@ApiErrorCodes({"A04-001"})
	@PostMapping("/password/reset")
	public GlobalApiResponse<Void> resetPassword(@Valid @RequestBody PasswordResetReq req) {
		authService.resetPassword(req);
		return GlobalApiResponse.ok("비밀번호가 변경되었습니다.", null);
	}
}
