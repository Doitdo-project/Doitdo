package com.doitdo.domain.bugreport.entity;

import com.doitdo.global.entity.BaseTimeEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@Table(name = "bug_reports")
@Builder
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class BugReport extends BaseTimeEntity {

	public enum BugReportStatus {
		NEW,
		REVIEWING,
		COMPLETE
	}

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "bug_report_id")
	private Long bugReportId;

	@Column(name = "user_id", nullable = false)
	private Long userId;

	@Column(nullable = false, length = 100)
	private String title;

	@Column(nullable = false, length = 500)
	private String content;

	@Column(name = "is_deleted", nullable = false)
	private Boolean isDeleted;

	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 30)
	private BugReportStatus status;

	public static BugReport create(Long userId, String title, String content) {
		return BugReport.builder()
				.userId(userId)
				.title(title)
				.content(content)
				.isDeleted(false)
				.status(BugReportStatus.NEW)
				.build();
	}
}
