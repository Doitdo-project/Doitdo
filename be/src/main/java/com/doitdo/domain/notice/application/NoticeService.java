package com.doitdo.domain.notice.application;

import com.doitdo.domain.notice.api.dto.resp.NoticeListResp;
import com.doitdo.domain.notice.api.dto.resp.NoticePopupResp;
import com.doitdo.domain.notice.api.dto.resp.NoticeResp;

public interface NoticeService {

	NoticePopupResp getLatestPopup(Long userId);

	NoticeListResp getNotices();

	NoticeResp getNotice(Long noticeId);

	void dismiss(Long userId, Long noticeId);
}
