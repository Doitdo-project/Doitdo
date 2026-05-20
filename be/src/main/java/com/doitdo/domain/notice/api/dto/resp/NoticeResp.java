package com.doitdo.domain.notice.api.dto.resp;

import com.doitdo.domain.notice.entity.Notice;
import java.time.LocalDateTime;

public record NoticeResp(
		Long noticeId,
		String title,
		String content,
		LocalDateTime startedAt,
		LocalDateTime endedAt,
		LocalDateTime createdAt
) {

	public static NoticeResp from(Notice notice) {
		return new NoticeResp(
				notice.getNoticeId(),
				notice.getTitle(),
				notice.getContent(),
				notice.getStartedAt(),
				notice.getEndedAt(),
				notice.getCreatedAt()
		);
	}
}
