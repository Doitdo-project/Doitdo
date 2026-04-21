package com.doitdo.domain.user.repository;

import com.doitdo.domain.user.entity.UserWallet;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserWalletRepository extends JpaRepository<UserWallet, Long> {
}
