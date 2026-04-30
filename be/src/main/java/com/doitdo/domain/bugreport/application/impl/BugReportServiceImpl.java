package com.doitdo.domain.bugreport.application.impl;

import com.doitdo.domain.bugreport.api.dto.req.CreateBugReportReq;
import com.doitdo.domain.bugreport.api.dto.resp.BugReportResp;
import com.doitdo.domain.bugreport.application.BugReportService;
import com.doitdo.domain.bugreport.entity.BugReport;
import com.doitdo.domain.bugreport.repository.BugReportRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class BugReportServiceImpl implements BugReportService {

	private final BugReportRepository bugReportRepository;

	@Override
	@Transactional
	public BugReportResp create(Long userId, CreateBugReportReq req) {
		BugReport bugReport = BugReport.create(userId, req.title(), req.content());
		BugReport saved = bugReportRepository.save(bugReport);
		return BugReportResp.from(saved);
	}
}
