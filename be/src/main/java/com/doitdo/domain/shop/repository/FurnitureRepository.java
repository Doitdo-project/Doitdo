package com.doitdo.domain.shop.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.doitdo.domain.shop.entity.Furniture;

public interface FurnitureRepository extends JpaRepository<Furniture, Long> {

	List<Furniture> findAllByIsDeletedFalseOrderByFurnitureIdAsc();

	List<Furniture> findAllByCategoryAndIsDeletedFalseOrderByFurnitureIdAsc(String category);

	@Query("""
		select f
		from Furniture f
		where f.themeCode = :themeCode
		  and f.isDeleted = false
		order by f.zIndex asc, f.furnitureId asc
		""")
	List<Furniture> findAllByThemeCodeAndIsDeletedFalseOrderByZIndexAscFurnitureIdAsc(
		@Param("themeCode") String themeCode);

	long countByThemeCodeAndIsDeletedFalse(String themeCode);

	Optional<Furniture> findByFurnitureIdAndIsDeletedFalse(Long furnitureId);

	Optional<Furniture> findByCodeAndIsDeletedFalse(String code);
}
