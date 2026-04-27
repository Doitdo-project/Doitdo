package com.doitdo.domain.user.api.controller;

import com.doitdo.domain.auth.application.CustomUserDetails;
import com.doitdo.domain.user.api.dto.req.PasswordChangeReq;
import com.doitdo.domain.user.api.dto.req.RegisterAgreementsReq;
import com.doitdo.domain.user.api.dto.req.RegisterBirthDateReq;
import com.doitdo.domain.user.api.dto.req.WithdrawReq;
import com.doitdo.domain.user.api.dto.resp.CheckDuplicateResp;
import com.doitdo.domain.user.api.dto.resp.UserInfoResp;
import com.doitdo.domain.user.application.UserService;
import com.doitdo.global.api.response.GlobalApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "user", description = "사용자 관련 API")
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

	private final UserService userService;

	@Operation(summary = "이메일 중복 확인", description = "회원가입 시 이메일 사용 가능 여부를 확인")
	@GetMapping("/check-email")
	public GlobalApiResponse<CheckDuplicateResp> checkEmail(@RequestParam String email) {
		return GlobalApiResponse.ok(userService.checkEmailDuplicate(email));
	}

	@Operation(summary = "닉네임 중복 확인", description = "회원가입 시 닉네임 사용 가능 여부를 확인")
	@GetMapping("/check-username")
	public GlobalApiResponse<CheckDuplicateResp> checkUsername(@RequestParam String username) {
		return GlobalApiResponse.ok(userService.checkUsernameDuplicate(username));
	}

	@Operation(summary = "내 정보 조회", description = "로그인한 사용자 본인의 정보를 조회")
	@GetMapping("/me")
	public GlobalApiResponse<UserInfoResp> getMyInfo(
			@AuthenticationPrincipal CustomUserDetails userDetails) {
		return GlobalApiResponse.ok(userService.getMyInfo(userDetails.getUserId()));
	}

	@Operation(summary = "비밀번호 변경", description = "현재 비밀번호 확인 후 새 비밀번호로 변경. 소셜 계정은 불가. 변경 시 기존 refresh token 무효화")
	@PostMapping("/me/password")
	@ResponseStatus(HttpStatus.NO_CONTENT)
	public GlobalApiResponse<Void> changePassword(
			@AuthenticationPrincipal CustomUserDetails userDetails,
			@Valid @RequestBody PasswordChangeReq req) {
		userService.changePassword(userDetails.getUserId(), req);
		return GlobalApiResponse.noContent("비밀번호 변경 완료");
	}

	@Operation(summary = "회원탈퇴",
			description = "소프트 삭제(isDeleted=true) + email/username 익명화 + 연관 리소스 정리. "
					+ "일반 계정은 currentPassword 재입력 필수, OAuth 계정은 생략 가능.")
	@DeleteMapping("/me")
	@ResponseStatus(HttpStatus.NO_CONTENT)
	public GlobalApiResponse<Void> withdraw(
			@AuthenticationPrincipal CustomUserDetails userDetails,
			@Valid @RequestBody(required = false) WithdrawReq req) {
		userService.withdraw(userDetails.getUserId(), req);
		return GlobalApiResponse.noContent("회원탈퇴 완료");
	}

	@Operation(summary = "생년월일 등록 (온보딩 1단계)",
			description = "만 14세 미만이면 계정 hard delete 후 403 반환. 이상이면 birthDate 저장.")
	@PostMapping("/me/birth-date")
	public GlobalApiResponse<UserInfoResp> registerBirthDate(
			@AuthenticationPrincipal CustomUserDetails userDetails,
			@Valid @RequestBody RegisterBirthDateReq req) {
		UserInfoResp resp = userService.registerBirthDate(userDetails.getUserId(), req);
		return GlobalApiResponse.ok("생년월일 등록 완료", resp);
	}

	@Operation(summary = "약관 동의 등록 (온보딩 2단계)",
			description = "이용약관/개인정보처리방침 동의는 필수(true). 마케팅 동의는 선택.")
	@PostMapping("/me/agreements")
	public GlobalApiResponse<UserInfoResp> registerAgreements(
			@AuthenticationPrincipal CustomUserDetails userDetails,
			@Valid @RequestBody RegisterAgreementsReq req) {
		UserInfoResp resp = userService.registerAgreements(userDetails.getUserId(), req);
		return GlobalApiResponse.ok("약관 동의 등록 완료", resp);
	}
}
