package com.doitdo.domain.user.application.impl;

import com.doitdo.domain.auth.repository.AutoProviderRepository;
import com.doitdo.domain.auth.repository.RefreshTokenRepository;
import com.doitdo.domain.inventory.repository.UserItemRepository;
import com.doitdo.domain.notification.repository.DeviceTokenRepository;
import com.doitdo.domain.notification.repository.NotificationRepository;
import com.doitdo.domain.setting.repository.UserSettingRepository;
import com.doitdo.domain.shop.repository.PurchaseLogRepository;
import com.doitdo.domain.tamagotchi.repository.CharacterUnlockRepository;
import com.doitdo.domain.tamagotchi.repository.UserCharacterRepository;
import com.doitdo.domain.todo.repository.CategoryRepository;
import com.doitdo.domain.todo.repository.SnoozeHistoryRepository;
import com.doitdo.domain.todo.repository.TodoRepository;
import com.doitdo.domain.user.api.dto.req.PasswordChangeReq;
import com.doitdo.domain.user.api.dto.req.WithdrawReq;
import com.doitdo.domain.user.api.dto.resp.CheckDuplicateResp;
import com.doitdo.domain.user.api.dto.resp.UserInfoResp;
import com.doitdo.domain.user.application.UserService;
import com.doitdo.domain.user.entity.User;
import com.doitdo.domain.user.repository.UserRepository;
import com.doitdo.domain.user.repository.UserWalletRepository;
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
	private final AutoProviderRepository autoProviderRepository;
	private final DeviceTokenRepository deviceTokenRepository;
	private final PurchaseLogRepository purchaseLogRepository;
	private final SnoozeHistoryRepository snoozeHistoryRepository;
	private final TodoRepository todoRepository;
	private final NotificationRepository notificationRepository;
	private final UserCharacterRepository userCharacterRepository;
	private final CategoryRepository categoryRepository;
	private final UserItemRepository userItemRepository;
	private final UserWalletRepository userWalletRepository;
	private final UserSettingRepository userSettingRepository;
	private final CharacterUnlockRepository characterUnlockRepository;
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

	@Override
	@Transactional
	public void withdraw(Long userId, WithdrawReq req) {
		User user = userRepository.findById(userId)
				.orElseThrow(() -> new CustomException(UserErrorCode.U04_002));

		if (Boolean.TRUE.equals(user.getIsDeleted())) {
			throw new CustomException(UserErrorCode.U04_005);
		}

		// 1. 인증 재확인 (일반 계정만). OAuth 계정은 access token 인증으로 충분.
		if (user.getPassword() != null) {
			String currentPassword = req == null ? null : req.currentPassword();
			if (currentPassword == null
					|| !passwordEncoder.matches(currentPassword, user.getPassword())) {
				throw new CustomException(UserErrorCode.U04_004);
			}
		}

		// 2. 세션/자격 자료 정리 (hard delete)
		refreshTokenRepository.deleteByUserId(userId);
		autoProviderRepository.deleteAllByUserId(userId);
		deviceTokenRepository.deleteAllByUserId(userId);

		// 3. 거래/이력 (hard delete)
		purchaseLogRepository.deleteAllByUserId(userId);
		snoozeHistoryRepository.deleteAllByUserId(userId);

		// 4. 컨텐츠 (soft delete — 기존 isDeleted 필드 활용)
		todoRepository.softDeleteAllByUserId(userId);
		notificationRepository.softDeleteAllByUserId(userId);
		userCharacterRepository.softDeleteAllByUserId(userId);

		// 5. 개인 설정/인벤토리 (hard delete)
		categoryRepository.deleteAllByUserId(userId);
		userItemRepository.deleteAllByUserId(userId);
		userWalletRepository.deleteByUserId(userId);
		userSettingRepository.deleteByUserId(userId);
		characterUnlockRepository.deleteAllByUserId(userId);

		// 6. User 익명화 + isDeleted=true
		// NOTE: todoRepository / notificationRepository / userCharacterRepository 의 bulk op 가
		//       모두 @Modifying(clearAutomatically = true) 를 선언하고 있어 EntityManager L1 캐시가
		//       clear 되면서 user 엔티티가 detached 상태가 된다.
		//       dirty-checking 만으로는 변경이 flush 되지 않으므로 saveAndFlush 로 merge + 즉시 flush.
		user.withdraw();
		userRepository.saveAndFlush(user);
	}
}
