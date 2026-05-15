package com.doitdo.domain.notice.api.dto.resp;

import com.doitdo.domain.notice.entity.Notice;
import java.util.List;

public record NoticeListResp(
		List<NoticeResp> items
) {

	public static NoticeListResp from(List<Notice> notices) {
		return new NoticeListResp(
				notices.stream()
						.map(NoticeResp::from)
						.toList()
		);
	}
}
