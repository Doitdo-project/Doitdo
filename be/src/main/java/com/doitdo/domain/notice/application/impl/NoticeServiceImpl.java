package com.doitdo.domain.notice.application.impl;

import com.doitdo.domain.notice.api.dto.resp.NoticeListResp;
import com.doitdo.domain.notice.api.dto.resp.NoticePopupResp;
import com.doitdo.domain.notice.api.dto.resp.NoticeResp;
import com.doitdo.domain.notice.application.NoticeService;
import com.doitdo.domain.notice.entity.Notice;
import com.doitdo.domain.notice.entity.NoticeDismissal;
import com.doitdo.domain.notice.repository.NoticeDismissalRepository;
import com.doitdo.domain.notice.repository.NoticeRepository;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.NoticeErrorCode;
import java.time.LocalDateTime;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class NoticeServiceImpl implements NoticeService {

	private final NoticeRepository noticeRepository;
	private final NoticeDismissalRepository noticeDismissalRepository;

	@Override
	@Transactional(readOnly = true)
	public NoticePopupResp getLatestPopup(Long userId) {
		return noticeRepository.findLatestActive(LocalDateTime.now())
				.filter(notice -> !noticeDismissalRepository.existsByUserIdAndNoticeId(userId, notice.getNoticeId()))
				.map(notice -> NoticePopupResp.show(NoticeResp.from(notice)))
				.orElseGet(NoticePopupResp::hide);
	}

	@Override
	@Transactional(readOnly = true)
	public NoticeListResp getNotices() {
		return NoticeListResp.from(noticeRepository.findAllActive(LocalDateTime.now()));
	}

	@Override
	@Transactional(readOnly = true)
	public NoticeResp getNotice(Long noticeId) {
		return NoticeResp.from(findActiveNotice(noticeId));
	}

	@Override
	@Transactional
	public void dismiss(Long userId, Long noticeId) {
		Notice notice = findActiveNotice(noticeId);
		if (noticeDismissalRepository.existsByUserIdAndNoticeId(userId, notice.getNoticeId())) {
			return;
		}
		noticeDismissalRepository.save(NoticeDismissal.create(userId, notice.getNoticeId()));
	}

	private Notice findActiveNotice(Long noticeId) {
		return noticeRepository.findActiveById(noticeId, LocalDateTime.now())
				.orElseThrow(() -> new CustomException(NoticeErrorCode.O00_001));
	}
}
