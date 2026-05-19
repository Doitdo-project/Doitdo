package com.doitdo.domain.user.repository;

import com.doitdo.domain.user.entity.WalletEarnLog;
import com.doitdo.domain.user.entity.WalletEarnSource;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface WalletEarnLogRepository extends JpaRepository<WalletEarnLog, Long> {

	boolean existsByUserIdAndSourceAndRefId(Long userId, WalletEarnSource source, Long refId);

	@Query("SELECT COALESCE(SUM(w.amount), 0) FROM WalletEarnLog w WHERE w.userId = :userId AND w.source = :source AND w.earnedAt >= :startOfDay AND w.earnedAt < :endOfDay")
	int sumAmountByUserIdAndSourceAndDate(
			@Param("userId") Long userId,
			@Param("source") WalletEarnSource source,
			@Param("startOfDay") LocalDateTime startOfDay,
			@Param("endOfDay") LocalDateTime endOfDay
	);

	@Query("SELECT COALESCE(SUM(w.amount), 0) FROM WalletEarnLog w WHERE w.userId = :userId AND w.source IN :sources AND w.earnedAt >= :startOfDay AND w.earnedAt < :endOfDay")
	int sumAmountByUserIdAndSourcesAndDate(
			@Param("userId") Long userId,
			@Param("sources") List<WalletEarnSource> sources,
			@Param("startOfDay") LocalDateTime startOfDay,
			@Param("endOfDay") LocalDateTime endOfDay
	);
}
