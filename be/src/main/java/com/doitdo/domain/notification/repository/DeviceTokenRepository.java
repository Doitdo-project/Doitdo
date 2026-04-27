package com.doitdo.domain.notification.repository;

import com.doitdo.domain.notification.entity.DeviceToken;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DeviceTokenRepository extends JpaRepository<DeviceToken, Long> {

	Optional<DeviceToken> findByFcmToken(String fcmToken);

	Optional<DeviceToken> findByUserIdAndFcmTokenAndIsActiveTrue(Long userId, String fcmToken);

	List<DeviceToken> findAllByUserIdAndIsActiveTrue(Long userId);

	void deleteAllByUserId(Long userId);
}
