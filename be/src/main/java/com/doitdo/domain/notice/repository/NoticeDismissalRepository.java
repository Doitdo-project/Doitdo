package com.doitdo.domain.notice.repository;

import com.doitdo.domain.notice.entity.NoticeDismissal;
import org.springframework.data.jpa.repository.JpaRepository;

public interface NoticeDismissalRepository extends JpaRepository<NoticeDismissal, Long> {

	boolean existsByUserIdAndNoticeId(Long userId, Long noticeId);
}
