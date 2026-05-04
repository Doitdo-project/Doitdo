package com.doitdo.domain.shop.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.doitdo.domain.shop.entity.FurniturePurchaseLog;

public interface FurniturePurchaseLogRepository extends JpaRepository<FurniturePurchaseLog, Long> {

	void deleteAllByUserId(Long userId);
}
