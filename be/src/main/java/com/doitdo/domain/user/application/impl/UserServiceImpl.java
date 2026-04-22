package com.doitdo.domain.user.application.impl;

import com.doitdo.domain.auth.repository.RefreshTokenRepository;
import com.doitdo.domain.user.api.dto.req.PasswordChangeReq;
import com.doitdo.domain.user.api.dto.resp.CheckDuplicateResp;
import com.doitdo.domain.user.api.dto.resp.UserInfoResp;
import com.doitdo.domain.user.application.UserService;
import com.doitdo.domain.user.entity.User;
import com.doitdo.domain.user.repository.UserRepository;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.UserErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {

	private final UserRepository userRepository;
	private final RefreshTokenRepository refreshTokenRepository;
	private final PasswordEncoder passwordEncoder;

	@Override
	@Transactional(readOnly = true)
	public CheckDuplicateResp checkEmailDuplicate(String email) {
		boolean exists = userRepository.existsByEmail(email);
		return new CheckDuplicateResp(!exists);
	}

	@Override
	@Transactional(readOnly = true)
	public CheckDuplicateResp checkUsernameDuplicate(String username) {
		boolean exists = userRepository.existsByUsername(username);
		return new CheckDuplicateResp(!exists);
	}

	@Override
	@Transactional(readOnly = true)
	public UserInfoResp getMyInfo(Long userId) {
		User user = userRepository.findById(userId)
				.orElseThrow(() -> new CustomException(UserErrorCode.U01_002));
		return UserInfoResp.from(user);
	}

	@Override
	@Transactional
	public void changePassword(Long userId, PasswordChangeReq req) {
		User user = userRepository.findById(userId)
				.orElseThrow(() -> new CustomException(UserErrorCode.U02_002));

		// OAuth 전용 계정은 비밀번호가 없음
		if (user.getPassword() == null) {
			throw new CustomException(UserErrorCode.U03_001,
					"소셜 계정은 비밀번호 변경을 지원하지 않습니다.");
		}

		if (!passwordEncoder.matches(req.currentPassword(), user.getPassword())) {
			throw new CustomException(UserErrorCode.U03_001);
		}

		user.updatePassword(passwordEncoder.encode(req.newPassword()));

		// 보안: 기존 refresh token 전부 무효화 → 재로그인 강제
		refreshTokenRepository.deleteByUserId(userId);
	}
}
