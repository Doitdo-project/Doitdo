package com.doitdo.domain.todo.repository;

import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

public interface TodoRepository extends JpaRepository<Todo, Long>, JpaSpecificationExecutor<Todo> {

	Optional<Todo> findByTodoIdAndIsDeletedFalse(Long todoId);

	Optional<Todo> findByUserIdAndTitleAndStartDateAndIsDeletedFalse(Long userId, String title, LocalDate startDate);

	List<Todo> findAllByUserIdAndTitleAndTypeAndIsDeletedFalse(Long userId, String title, TodoType type);
}
