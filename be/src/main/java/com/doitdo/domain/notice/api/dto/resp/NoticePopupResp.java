package com.doitdo.domain.notice.api.dto.resp;

public record NoticePopupResp(
		boolean show,
		NoticeResp notice
) {

	public static NoticePopupResp show(NoticeResp notice) {
		return new NoticePopupResp(true, notice);
	}

	public static NoticePopupResp hide() {
		return new NoticePopupResp(false, null);
	}
}
