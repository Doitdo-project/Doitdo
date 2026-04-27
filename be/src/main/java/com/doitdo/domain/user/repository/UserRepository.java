package com.doitdo.domain.user.repository;

import com.doitdo.domain.user.entity.User;
import jakarta.persistence.LockModeType;
import java.util.Optional;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserRepository extends JpaRepository<User, Long> {

	Optional<User> findByEmail(String email);

	Optional<User> findByUsername(String username);

	boolean existsByEmail(String email);

	boolean existsByUsername(String username);

	@Lock(LockModeType.PESSIMISTIC_WRITE)
	@Query("select u from User u where u.userId = :userId")
	Optional<User> findByIdForUpdate(@Param("userId") Long userId);
}
