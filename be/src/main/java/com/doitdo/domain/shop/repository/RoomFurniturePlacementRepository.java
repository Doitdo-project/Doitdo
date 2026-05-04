package com.doitdo.domain.shop.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import com.doitdo.domain.shop.entity.RoomFurniturePlacement;

public interface RoomFurniturePlacementRepository extends JpaRepository<RoomFurniturePlacement, Long> {

	@Query("""
		select p
		from RoomFurniturePlacement p
		where p.userId = :userId
		order by p.zIndex asc, p.placementId asc
		""")
	List<RoomFurniturePlacement> findAllByUserIdOrderByZIndexAscPlacementIdAsc(Long userId);

	Optional<RoomFurniturePlacement> findByPlacementIdAndUserId(Long placementId, Long userId);

	void deleteAllByUserId(Long userId);
}
