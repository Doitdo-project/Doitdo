package com.doitdo.domain.todo.repository;

import com.doitdo.domain.todo.entity.SnoozeHistory;
import java.util.Collection;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface SnoozeHistoryRepository extends JpaRepository<SnoozeHistory, Long> {

	long countByTodoId(Long todoId);

	@Query("SELECT sh.todoId AS todoId, COUNT(sh) AS cnt FROM SnoozeHistory sh WHERE sh.todoId IN :ids GROUP BY sh.todoId")
	List<SnoozeCountProjection> countByTodoIdIn(@Param("ids") Collection<Long> ids);

	interface SnoozeCountProjection {
		Long getTodoId();
		Long getCnt();
	}
}
