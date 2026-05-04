package com.doitdo.domain.user.repository;

import com.doitdo.domain.user.entity.UserWallet;
import jakarta.persistence.LockModeType;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserWalletRepository extends JpaRepository<UserWallet, Long> {

	Optional<UserWallet> findByUserId(Long userId);

	@Lock(LockModeType.PESSIMISTIC_WRITE)
	@Query("select uw from UserWallet uw where uw.userId = :userId")
	Optional<UserWallet> findByUserIdForUpdate(@Param("userId") Long userId);

	void deleteByUserId(Long userId);
}
