package com.doitdo.domain.todo.repository;

import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
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

	@Query("""
			select count(t) from Todo t
			where t.userId = :userId
			  and t.status <> com.doitdo.domain.todo.entity.Todo.TodoStatus.DONE
			  and t.isDeleted = false
			""")
	long countPendingByUserId(@Param("userId") Long userId);
}
