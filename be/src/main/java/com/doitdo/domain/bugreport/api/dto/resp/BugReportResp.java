package com.doitdo.domain.bugreport.api.dto.resp;

import com.doitdo.domain.bugreport.entity.BugReport;
import java.time.LocalDateTime;

public record BugReportResp(
		Long bugReportId,
		LocalDateTime createdAt
) {

	public static BugReportResp from(BugReport bugReport) {
		return new BugReportResp(
				bugReport.getBugReportId(),
				bugReport.getCreatedAt()
		);
	}
}
