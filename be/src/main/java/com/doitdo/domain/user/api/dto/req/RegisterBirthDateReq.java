package com.doitdo.domain.user.api.dto.req;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Past;
import java.time.LocalDate;

public record RegisterBirthDateReq(

		@NotNull
		@Past
		LocalDate birthDate
) {
}
