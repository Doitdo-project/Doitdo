package com.doitdo.domain.shop.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.doitdo.domain.shop.entity.FurnitureTheme;

public interface FurnitureThemeRepository extends JpaRepository<FurnitureTheme, String> {

	List<FurnitureTheme> findAllByIsActiveTrueOrderByDisplayOrderAscThemeCodeAsc();

	Optional<FurnitureTheme> findByThemeCodeAndIsActiveTrue(String themeCode);
}
