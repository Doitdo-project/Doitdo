package com.doitdo.domain.auth.application;

import com.doitdo.domain.auth.application.cache.AuthUserCacheService;
import com.doitdo.domain.auth.application.cache.AuthUserSnapshot;
import com.doitdo.domain.user.entity.User;
import com.doitdo.domain.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class CustomUserDetailsService implements UserDetailsService {

	private final UserRepository userRepository;
	private final AuthUserCacheService authUserCacheService;

	@Override
	@Transactional(readOnly = true)
	public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
		User user = userRepository.findByUsername(username)
				.orElseThrow(() -> new UsernameNotFoundException("사용자를 찾을 수 없습니다. username=" + username));
		return new CustomUserDetails(user);
	}

	public UserDetails loadUserById(Long userId) {
		AuthUserSnapshot snapshot = authUserCacheService.loadById(userId);
		return new CustomUserDetails(snapshot.toUser());
	}
}
