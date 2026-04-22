package com.doitdo.domain.inventory.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.doitdo.domain.inventory.entity.UserItem;

public interface UserItemRepository extends JpaRepository<UserItem, Long> {

	List<UserItem> findAllByUserId(Long userId);

	Optional<UserItem> findByUserIdAndUserItemId(Long userId, Long userItemId);
}
