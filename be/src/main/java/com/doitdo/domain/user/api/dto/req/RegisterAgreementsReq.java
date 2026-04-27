package com.doitdo.domain.user.api.dto.req;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotNull;

public record RegisterAgreementsReq(

		@NotNull
		@AssertTrue(message = "이용약관에 동의해야 합니다.")
		Boolean termsAgreed,

		@NotNull
		@AssertTrue(message = "개인정보처리방침에 동의해야 합니다.")
		Boolean privacyAgreed,

		@NotNull
		Boolean marketingAgreed
) {
}
