package com.doitdo.domain.shop.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.doitdo.domain.shop.entity.Furniture;

public interface FurnitureRepository extends JpaRepository<Furniture, Long> {

	List<Furniture> findAllByIsDeletedFalseOrderByFurnitureIdAsc();

	List<Furniture> findAllByCategoryAndIsDeletedFalseOrderByFurnitureIdAsc(String category);

	Optional<Furniture> findByFurnitureIdAndIsDeletedFalse(Long furnitureId);
}
