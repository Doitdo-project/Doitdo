package com.doitdo.domain.bugreport.application;

import com.doitdo.domain.bugreport.api.dto.req.CreateBugReportReq;
import com.doitdo.domain.bugreport.api.dto.resp.BugReportResp;

public interface BugReportService {

	BugReportResp create(Long userId, CreateBugReportReq req);
}
