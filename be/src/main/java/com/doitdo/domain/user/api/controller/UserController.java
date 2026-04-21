package com.doitdo.domain.user.api.controller;

import com.doitdo.domain.user.api.dto.resp.CheckDuplicateResp;
import com.doitdo.domain.user.application.UserService;
import com.doitdo.global.api.response.GlobalApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
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
}
