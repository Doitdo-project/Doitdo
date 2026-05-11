package com.doitdo.domain.shop.entity;

import java.time.LocalDateTime;

import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@Table(
	name = "furniture_purchase_logs",
	indexes = {
		@Index(name = "idx_furniture_purchase_logs_user_id", columnList = "user_id"),
		@Index(name = "idx_furniture_purchase_logs_furniture_id", columnList = "furniture_id")
	}
)
@EntityListeners(AuditingEntityListener.class)
@Builder
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class FurniturePurchaseLog {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "purchase_id")
	private Long purchaseId;

	@Column(name = "user_id", nullable = false)
	private Long userId;

	@Column(name = "user_furniture_id", nullable = false)
	private Long userFurnitureId;

	@Column(name = "furniture_id", nullable = false)
	private Long furnitureId;

	@Column(nullable = false)
	private Integer price;

	@Column(name = "balance_after_purchase", nullable = false)
	private Integer balanceAfterPurchase;

	@CreatedDate
	@Column(name = "purchased_at", nullable = false, updatable = false)
	private LocalDateTime purchasedAt;

	public static FurniturePurchaseLog create(Long userId, Long userFurnitureId, Long furnitureId, Integer price,
		Integer balanceAfterPurchase) {
		return FurniturePurchaseLog.builder()
			.userId(userId)
			.userFurnitureId(userFurnitureId)
			.furnitureId(furnitureId)
			.price(price)
			.balanceAfterPurchase(balanceAfterPurchase)
			.build();
	}
}
