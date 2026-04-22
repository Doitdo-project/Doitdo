package com.doitdo.domain.todo.repository;

import com.doitdo.domain.todo.entity.Todo;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

public interface TodoRepository extends JpaRepository<Todo, Long>, JpaSpecificationExecutor<Todo> {

	Optional<Todo> findByTodoIdAndIsDeletedFalse(Long todoId);
}
