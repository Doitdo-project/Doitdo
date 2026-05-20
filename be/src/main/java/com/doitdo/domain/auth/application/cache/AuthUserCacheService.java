package com.doitdo.domain.auth.application.cache;

import com.doitdo.domain.user.entity.User;
import com.doitdo.domain.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthUserCacheService {

	private final UserRepository userRepository;
	private final AuthUserCacheProvider cacheProvider;

	public AuthUserSnapshot loadById(Long userId) {
		return cacheProvider.get(userId, () -> loadSnapshot(userId));
	}

	public void evict(Long userId) {
		cacheProvider.evict(userId);
	}

	private AuthUserSnapshot loadSnapshot(Long userId) {
		User user = userRepository.findById(userId)
				.orElseThrow(() -> new UsernameNotFoundException("사용자를 찾을 수 없습니다. userId=" + userId));
		return AuthUserSnapshot.from(user);
	}
}
