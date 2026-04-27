package com.doitdo.domain.notification.repository;

import com.doitdo.domain.notification.entity.Notification;
import java.time.LocalDateTime;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface NotificationRepository extends JpaRepository<Notification, Long> {

	Optional<Notification> findByNotificationIdAndIsDeletedFalse(Long notificationId);

	Page<Notification> findAllByUserIdAndIsDeletedFalse(Long userId, Pageable pageable);

	Page<Notification> findAllByUserIdAndIsDeletedFalseAndIsRead(Long userId, Boolean isRead, Pageable pageable);

	@Modifying(clearAutomatically = true, flushAutomatically = true)
	@Query("""
			update Notification n
			   set n.isRead = true,
			       n.readAt = :readAt
			 where n.userId = :userId
			   and n.isDeleted = false
			   and n.isRead = false
			""")
	int updateAllRead(@Param("userId") Long userId, @Param("readAt") LocalDateTime readAt);

	@Modifying(clearAutomatically = true, flushAutomatically = true)
	@Query("update Notification n set n.isDeleted = true where n.userId = :userId and n.isDeleted = false")
	int softDeleteAllByUserId(@Param("userId") Long userId);

	@Modifying(clearAutomatically = true, flushAutomatically = true)
	@Query("delete from Notification n where n.userId = :userId")
	int hardDeleteAllByUserId(@Param("userId") Long userId);
}
