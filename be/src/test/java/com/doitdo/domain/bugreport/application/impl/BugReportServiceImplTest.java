package com.doitdo.domain.bugreport.application.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;

import com.doitdo.domain.bugreport.api.dto.req.CreateBugReportReq;
import com.doitdo.domain.bugreport.api.dto.resp.BugReportResp;
import com.doitdo.domain.bugreport.entity.BugReport;
import com.doitdo.domain.bugreport.entity.BugReport.BugReportStatus;
import com.doitdo.domain.bugreport.repository.BugReportRepository;
import java.time.LocalDateTime;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class BugReportServiceImplTest {

	@Mock
	private BugReportRepository bugReportRepository;

	@Test
	@DisplayName("버그 신고 접수 시 저장된 bugReportId와 createdAt 을 반환한다")
	void createReturnsSavedBugReport() {
		BugReportServiceImpl service = new BugReportServiceImpl(bugReportRepository);

		Long userId = 1L;
		CreateBugReportReq req = new CreateBugReportReq("제목", "내용");

		BugReport saved = BugReport.create(userId, req.title(), req.content());
		ReflectionTestUtils.setField(saved, "bugReportId", 7L);
		ReflectionTestUtils.setField(saved, "createdAt", LocalDateTime.of(2026, 4, 30, 14, 23, 10));

		given(bugReportRepository.save(any(BugReport.class))).willReturn(saved);

		BugReportResp resp = service.create(userId, req);

		assertThat(resp.bugReportId()).isEqualTo(7L);
		assertThat(resp.createdAt()).isEqualTo(LocalDateTime.of(2026, 4, 30, 14, 23, 10));
	}

	@Test
	@DisplayName("버그 신고 엔티티는 isDeleted=false, status=NEW 기본값으로 생성된다")
	void createBugReportHasDefaultValues() {
		BugReport bugReport = BugReport.create(1L, "제목", "내용");

		assertThat(bugReport.getIsDeleted()).isFalse();
		assertThat(bugReport.getStatus()).isEqualTo(BugReportStatus.NEW);
		assertThat(bugReport.getUserId()).isEqualTo(1L);
		assertThat(bugReport.getTitle()).isEqualTo("제목");
		assertThat(bugReport.getContent()).isEqualTo("내용");
	}
}
