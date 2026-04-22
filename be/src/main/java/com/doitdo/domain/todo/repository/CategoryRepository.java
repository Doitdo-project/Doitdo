package com.doitdo.domain.todo.repository;

import com.doitdo.domain.todo.entity.Category;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CategoryRepository extends JpaRepository<Category, Long> {

	Optional<Category> findByCategoryNameAndUserId(String categoryName, Long userId);
}
