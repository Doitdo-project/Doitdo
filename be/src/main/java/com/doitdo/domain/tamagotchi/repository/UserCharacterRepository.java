package com.doitdo.domain.tamagotchi.repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.doitdo.domain.tamagotchi.entity.UserCharacter;

public interface UserCharacterRepository extends JpaRepository<UserCharacter, Long> {

	Optional<UserCharacter> findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(Long userId);

	@Query("""
		select uc from UserCharacter uc
		where uc.farewellAvailableAt is not null
			and uc.farewellAvailableAt <= :now
			and uc.farewellNotified = false
			and uc.isActive = true
			and uc.isDeleted = false
	""")
	List<UserCharacter> findFarewellAvailableTargets(@Param("now") LocalDateTime now);

	@Query("""
		SELECT COUNT(uc)
		FROM UserCharacter uc
		JOIN Character c ON uc.characterId = c.characterId
		WHERE uc.userId = :userId
			AND uc.isDeleted = false
			AND c.species = :species
			AND c.stage = com.doitdo.domain.tamagotchi.entity.Character.Stage.ADULT
	""")
	Long countByUserIdAndSpecies(@Param("userId") Long userId, @Param("species") String species);

	@Modifying(clearAutomatically = true, flushAutomatically = true)
	@Query("UPDATE UserCharacter uc SET uc.isDeleted = true WHERE uc.userId = :userId AND uc.isDeleted = false")
	int softDeleteAllByUserId(@Param("userId") Long userId);

	@Modifying(clearAutomatically = true, flushAutomatically = true)
	@Query("DELETE FROM UserCharacter uc WHERE uc.userId = :userId")
	int hardDeleteAllByUserId(@Param("userId") Long userId);
}
