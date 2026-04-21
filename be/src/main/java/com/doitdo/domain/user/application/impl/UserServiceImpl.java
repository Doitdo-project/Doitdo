package com.doitdo.domain.user.application.impl;

import com.doitdo.domain.user.api.dto.resp.CheckDuplicateResp;
import com.doitdo.domain.user.application.UserService;
import com.doitdo.domain.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {

	private final UserRepository userRepository;

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
}
