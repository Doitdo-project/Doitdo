package com.doitdo.domain.inventory.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.doitdo.domain.inventory.entity.Item;

public interface ItemRepository extends JpaRepository<Item, Long> {
}
