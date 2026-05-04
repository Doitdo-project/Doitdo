package com.doitdo.domain.shop.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.doitdo.domain.shop.entity.UserFurniture;

public interface UserFurnitureRepository extends JpaRepository<UserFurniture, Long> {

	boolean existsByUserIdAndFurnitureId(Long userId, Long furnitureId);

	Optional<UserFurniture> findByUserIdAndUserFurnitureId(Long userId, Long userFurnitureId);

	List<UserFurniture> findAllByUserIdOrderByUserFurnitureIdAsc(Long userId);

	void deleteAllByUserId(Long userId);

	@Query("select uf.furnitureId from UserFurniture uf where uf.userId = :userId")
	List<Long> findFurnitureIdsByUserId(@Param("userId") Long userId);
}
