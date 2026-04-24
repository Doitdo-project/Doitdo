# Character Species Background Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a separate master table that stores one birth-background row per character species.

**Architecture:** Keep the source of truth in a new `character_species_backgrounds` table keyed by `species`. Map it with a small JPA entity and repository so later services can join by species without duplicating the text across `characters`.

**Tech Stack:** Spring Boot, JPA, MariaDB, Flyway-style SQL migration

---

### Task 1: Add the database table

**Files:**
- Create: `docs/ops/migrations/2026-04-character-species-background.sql`

**Step 1: Write the migration**

```sql
CREATE TABLE character_species_backgrounds (
  species VARCHAR(20) NOT NULL,
  birth_background TEXT NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  PRIMARY KEY (species)
);
```

**Step 2: Verify the SQL matches existing naming conventions**

Expected: table uses plural master-data style and species is unique.

### Task 2: Add entity and repository

**Files:**
- Create: `src/main/java/com/doitdo/domain/tamagotchi/entity/CharacterSpeciesBackground.java`
- Create: `src/main/java/com/doitdo/domain/tamagotchi/repository/CharacterSpeciesBackgroundRepository.java`

**Step 1: Write the entity and repository**

```java
// entity keyed by species, with birthBackground plus BaseTimeEntity fields
```

**Step 2: Compile main sources**

Run: `./gradlew compileJava`
Expected: PASS

### Task 3: Sanity check

**Files:**
- None

**Step 1: Verify repository is wired**

Run: `./gradlew test --tests "*CharacterSpeciesBackground*"`
Expected: PASS if any focused tests are added later, otherwise compile-only verification is sufficient.

