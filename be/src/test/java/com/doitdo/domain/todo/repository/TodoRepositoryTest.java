package com.doitdo.domain.todo.repository;

import static org.assertj.core.api.Assertions.assertThat;

import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.entity.Todo.TodoStatus;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import com.doitdo.global.config.JpaAuditingConfig;
import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.context.annotation.Import;

@DataJpaTest
@Import(JpaAuditingConfig.class)
class TodoRepositoryTest {

	private static final Long USER_ID = 1L;
	private static final Long MASTER_TODO_ID = 100L;
	private static final LocalDate OCCURRENCE_DATE = LocalDate.parse("2026-05-01");

	@Autowired
	private TodoRepository todoRepository;

	@Test
	void findMaterializedInstancesByMasterTodoIdInFromDateExcludesDoneInstances() {
		Todo done = saveMaterialized("done", TodoStatus.DONE, LocalDate.parse("2026-05-03"), false);
		Todo pending = saveMaterialized("pending", TodoStatus.TODO, LocalDate.parse("2026-05-04"), false);
		saveMaterialized("before", TodoStatus.TODO, LocalDate.parse("2026-04-30"), false);
		saveMaterialized("deleted", TodoStatus.TODO, LocalDate.parse("2026-05-05"), true);

		List<Todo> result = todoRepository.findMaterializedInstancesByMasterTodoIdInFromDate(
				USER_ID,
				List.of(MASTER_TODO_ID),
				OCCURRENCE_DATE);

		assertThat(result)
				.extracting(Todo::getTodoId)
				.containsExactly(pending.getTodoId());
		assertThat(done.getIsDeleted()).isFalse();
	}

	private Todo saveMaterialized(String title, TodoStatus status, LocalDate startDate, boolean isDeleted) {
		return todoRepository.saveAndFlush(Todo.builder()
				.userId(USER_ID)
				.title(title)
				.type(TodoType.NORMAL)
				.status(status)
				.priority(1)
				.startDate(startDate)
				.masterTodoId(MASTER_TODO_ID)
				.isDeleted(isDeleted)
				.expGranted(false)
				.build());
	}
}
