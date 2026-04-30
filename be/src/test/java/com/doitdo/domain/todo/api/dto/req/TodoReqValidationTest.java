package com.doitdo.domain.todo.api.dto.req;

import static org.assertj.core.api.Assertions.assertThat;

import com.doitdo.domain.todo.entity.Todo.TodoType;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import java.time.LocalDate;
import java.util.Set;
import org.junit.jupiter.api.Test;

class TodoReqValidationTest {

	private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

	@Test
	void createReqRejectsLongTitleAndContent() {
		TodoCreateReq req = new TodoCreateReq(
				"a".repeat(21),
				"b".repeat(101),
				null,
				TodoType.NORMAL,
				LocalDate.now(),
				null,
				Set.of(),
				1,
				null
		);

		assertThat(validator.validate(req))
				.extracting(violation -> violation.getPropertyPath().toString())
				.contains("title", "content");
	}

	@Test
	void updateReqRejectsLongTitleAndContent() {
		TodoUpdateReq req = new TodoUpdateReq(
				"a".repeat(21),
				"b".repeat(101),
				null,
				null,
				null,
				null,
				null,
				null,
				null
		);

		assertThat(validator.validate(req))
				.extracting(violation -> violation.getPropertyPath().toString())
				.contains("title", "content");
	}
}
