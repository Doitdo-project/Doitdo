package com.doitdo.domain.notice.repository;

import com.doitdo.domain.notice.entity.Notice;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface NoticeRepository extends JpaRepository<Notice, Long> {

	default Optional<Notice> findLatestActive(LocalDateTime now) {
		return findActivePage(now, PageRequest.of(0, 1)).stream().findFirst();
	}

	@Query("""
			SELECT n
			FROM Notice n
			WHERE n.isActive = true
			  AND (n.startedAt IS NULL OR n.startedAt <= :now)
			  AND (n.endedAt IS NULL OR n.endedAt >= :now)
			ORDER BY n.createdAt DESC, n.noticeId DESC
			""")
	List<Notice> findAllActive(@Param("now") LocalDateTime now);

	@Query("""
			SELECT n
			FROM Notice n
			WHERE n.isActive = true
			  AND (n.startedAt IS NULL OR n.startedAt <= :now)
			  AND (n.endedAt IS NULL OR n.endedAt >= :now)
			ORDER BY n.createdAt DESC, n.noticeId DESC
			""")
	List<Notice> findActivePage(@Param("now") LocalDateTime now, Pageable pageable);

	@Query("""
			SELECT n
			FROM Notice n
			WHERE n.noticeId = :noticeId
			  AND n.isActive = true
			  AND (n.startedAt IS NULL OR n.startedAt <= :now)
			  AND (n.endedAt IS NULL OR n.endedAt >= :now)
			""")
	Optional<Notice> findActiveById(
			@Param("noticeId") Long noticeId,
			@Param("now") LocalDateTime now);
}
