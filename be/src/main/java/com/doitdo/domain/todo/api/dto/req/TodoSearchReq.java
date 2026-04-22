package com.doitdo.domain.todo.api.dto.req;

import jakarta.validation.constraints.NotBlank;

public record TodoSearchReq(
		@NotBlank String q,
		String sort,
		Integer page,
		Integer size
) {}
