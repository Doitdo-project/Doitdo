package com.doitdo.domain.tamagotchi.repository;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.context.annotation.Import;

import com.doitdo.domain.tamagotchi.entity.Character;
import com.doitdo.domain.tamagotchi.entity.UserCharacter;
import com.doitdo.global.config.JpaAuditingConfig;

import jakarta.persistence.EntityManager;

@DataJpaTest
@Import(JpaAuditingConfig.class)
class UserCharacterRepositoryTest {

	@Autowired
	private UserCharacterRepository userCharacterRepository;

	@Autowired
	private EntityManager entityManager;

	@Test
	void countByUserIdAndSpeciesCountsOnlyAdultCharacters() {
		Long userId = 1L;
		String species = "SLIME";

		Character baby = Character.builder()
			.species(species)
			.name("baby")
			.stage(Character.Stage.BABY)
			.thumbnailUrl("https://cdn.example.com/baby.png")
			.requiredExp(100)
			.build();
		Character teen = Character.builder()
			.species(species)
			.name("teen")
			.stage(Character.Stage.TEEN)
			.thumbnailUrl("https://cdn.example.com/teen.png")
			.requiredExp(200)
			.build();
		Character adult = Character.builder()
			.species(species)
			.name("adult")
			.stage(Character.Stage.ADULT)
			.thumbnailUrl("https://cdn.example.com/adult.png")
			.requiredExp(300)
			.build();

		entityManager.persist(baby);
		entityManager.persist(teen);
		entityManager.persist(adult);
		entityManager.flush();

		entityManager.persist(UserCharacter.builder()
			.userId(userId)
			.characterId(baby.getCharacterId())
			.name("baby")
			.currentExp(0)
			.isActive(true)
			.isDeleted(false)
			.build());
		entityManager.persist(UserCharacter.builder()
			.userId(userId)
			.characterId(teen.getCharacterId())
			.name("teen")
			.currentExp(0)
			.isActive(false)
			.isDeleted(false)
			.build());
		entityManager.persist(UserCharacter.builder()
			.userId(userId)
			.characterId(adult.getCharacterId())
			.name("adult")
			.currentExp(0)
			.isActive(false)
			.isDeleted(false)
			.build());

		entityManager.flush();
		entityManager.clear();

		assertThat(userCharacterRepository.countByUserIdAndSpecies(userId, species)).isEqualTo(1L);
	}
}
