package com.doitdo.domain.todo.repository;

import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface TodoRepository extends JpaRepository<Todo, Long>, JpaSpecificationExecutor<Todo> {

	Optional<Todo> findByTodoIdAndIsDeletedFalse(Long todoId);

	Optional<Todo> findByUserIdAndTitleAndStartDateAndIsDeletedFalse(Long userId, String title, LocalDate startDate);

	Optional<Todo> findByUserIdAndTitleAndStartDateAndTypeAndIsDeletedFalse(
			Long userId,
			String title,
			LocalDate startDate,
			TodoType type);

	List<Todo> findAllByUserIdAndTitleAndTypeAndIsDeletedFalse(Long userId, String title, TodoType type);

	@Modifying(clearAutomatically = true, flushAutomatically = true)
	@Query("UPDATE Todo t SET t.isDeleted = true WHERE t.userId = :userId AND t.isDeleted = false")
	int softDeleteAllByUserId(@Param("userId") Long userId);
}
