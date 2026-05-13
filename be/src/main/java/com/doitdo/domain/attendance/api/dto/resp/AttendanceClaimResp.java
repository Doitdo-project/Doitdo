package com.doitdo.domain.attendance.api.dto.resp;

import java.time.LocalDate;

public record AttendanceClaimResp(
		int earnedAmount,
		long balance,
		LocalDate attendanceDate
) {
}
