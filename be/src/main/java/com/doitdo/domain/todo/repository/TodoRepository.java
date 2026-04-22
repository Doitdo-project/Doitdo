package com.doitdo.domain.todo.repository;

import com.doitdo.domain.todo.entity.Todo;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TodoRepository extends JpaRepository<Todo, Long> {

	Optional<Todo> findByTodoIdAndIsDeletedFalse(Long todoId);
}
