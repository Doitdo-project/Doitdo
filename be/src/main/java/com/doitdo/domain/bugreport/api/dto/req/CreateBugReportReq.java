package com.doitdo.domain.bugreport.api.dto.req;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateBugReportReq(

		@NotBlank
		@Size(max = 100)
		String title,

		@NotBlank
		@Size(max = 500)
		String content
) {
}
