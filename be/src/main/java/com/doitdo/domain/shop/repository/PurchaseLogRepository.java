package com.doitdo.domain.shop.repository;

import com.doitdo.domain.shop.entity.PurchaseLog;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PurchaseLogRepository extends JpaRepository<PurchaseLog, Long> {

	void deleteAllByUserId(Long userId);
}
