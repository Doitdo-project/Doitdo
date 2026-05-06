package com.doitdo.domain.user.application.impl;

import com.doitdo.domain.auth.entity.OAuthProvider;
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
import com.doitdo.domain.user.repository.UserRepository;
import com.doitdo.domain.user.repository.UserWalletRepository;
import com.doitdo.global.client.AppleOAuthClient;
import java.util.Objects;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * 미성년자 hard delete 를 별도 트랜잭션(REQUIRES_NEW)으로 처리하는 서비스.
 *
 * <p>UserServiceImpl 이 self-invocation 으로 @Transactional(REQUIRES_NEW) 를 호출하면
 * Spring AOP 프록시를 우회하여 트랜잭션이 분리되지 않는다.
 * 이 클래스를 별도 빈으로 추출함으로써 프록시를 통해 메서드가 호출되어
 * REQUIRES_NEW 가 올바르게 동작한다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class UserHardDeleteService {

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
    private final AppleOAuthClient appleOAuthClient;

    /**
     * 만 14세 미만 사용자 hard delete (독립 트랜잭션 커밋).
     *
     * <p>REQUIRES_NEW 로 호출 측 트랜잭션과 독립되어 실행된다.
     * 호출 측에서 U00_006 예외를 던지더라도 delete 는 롤백되지 않는다.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void hardDeleteUser(Long userId) {
        revokeAppleTokensIfPresent(userId);
        refreshTokenRepository.deleteByUserId(userId);
        autoProviderRepository.deleteAllByUserId(userId);
        deviceTokenRepository.deleteAllByUserId(userId);

        purchaseLogRepository.deleteAllByUserId(userId);
        snoozeHistoryRepository.deleteAllByUserId(userId);

        todoRepository.hardDeleteAllByUserId(userId);
        notificationRepository.hardDeleteAllByUserId(userId);
        userCharacterRepository.hardDeleteAllByUserId(userId);

        categoryRepository.deleteAllByUserId(userId);
        userItemRepository.deleteAllByUserId(userId);
        userWalletRepository.deleteByUserId(userId);
        userSettingRepository.deleteByUserId(userId);
        characterUnlockRepository.deleteAllByUserId(userId);

        userRepository.deleteById(userId);
    }

    private void revokeAppleTokensIfPresent(Long userId) {
        autoProviderRepository.findAllByUserIdAndProvider(userId, OAuthProvider.APPLE.name())
                .stream()
                .map(ap -> ap.getAppleRefreshToken())
                .filter(Objects::nonNull)
                .filter(token -> !token.isBlank())
                .forEach(token -> {
                    try {
                        appleOAuthClient.revokeRefreshToken(token);
                        log.info("Apple revoke 성공: userId={}", userId);
                    } catch (Exception e) {
                        log.warn("Apple revoke 실패 — hard delete 는 계속 진행: userId={}, reason={}",
                                userId, e.getMessage());
                    }
                });
    }
}
