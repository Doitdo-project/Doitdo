package com.doitdo.domain.user.entity;

import com.doitdo.global.entity.BaseTimeEntity;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.ShopErrorCode;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@Table(name = "user_wallets")
@Builder
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class UserWallet extends BaseTimeEntity {

	private static final int INITIAL_SIGNUP_CREDIT = 1000;

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "wallet_id")
	private Long walletId;

	@Column(name = "user_id", nullable = false)
	private Long userId;

	@Column(nullable = false)
	private Integer balance;

	public static UserWallet create(Long userId) {
		return UserWallet.builder()
				.userId(userId)
				.balance(INITIAL_SIGNUP_CREDIT)
				.build();
	}

	public static UserWallet createEmpty(Long userId) {
		return UserWallet.builder()
				.userId(userId)
				.balance(0)
				.build();
	}

	public void addBalance(Integer amount) {
		this.balance += amount;
	}

	public void spend(Integer amount) {
		if (this.balance < amount) {
			throw new CustomException(ShopErrorCode.INSUFFICIENT_BALANCE);
		}
		this.balance -= amount;
	}
}
