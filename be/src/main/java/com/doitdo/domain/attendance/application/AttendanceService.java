package com.doitdo.domain.attendance.application;

import com.doitdo.domain.attendance.api.dto.resp.AttendanceClaimResp;

public interface AttendanceService {

	AttendanceClaimResp claim(Long userId);
}
