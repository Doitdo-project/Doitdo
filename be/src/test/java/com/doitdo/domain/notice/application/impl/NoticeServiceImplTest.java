package com.doitdo.domain.notice.application.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.then;

import com.doitdo.domain.notice.api.dto.resp.NoticeListResp;
import com.doitdo.domain.notice.api.dto.resp.NoticePopupResp;
import com.doitdo.domain.notice.api.dto.resp.NoticeResp;
import com.doitdo.domain.notice.entity.Notice;
import com.doitdo.domain.notice.entity.NoticeDismissal;
import com.doitdo.domain.notice.repository.NoticeDismissalRepository;
import com.doitdo.domain.notice.repository.NoticeRepository;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.NoticeErrorCode;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class NoticeServiceImplTest {

	@Mock
	private NoticeRepository noticeRepository;

	@Mock
	private NoticeDismissalRepository noticeDismissalRepository;

	@Test
	void getLatestPopupReturnsShowTrueWhenLatestNoticeIsNotDismissed() {
		NoticeServiceImpl service = new NoticeServiceImpl(noticeRepository, noticeDismissalRepository);
		Notice notice = notice(1L, "점검 안내", "오늘 23시에 점검합니다.",
				LocalDateTime.of(2026, 5, 15, 10, 0));
		given(noticeRepository.findLatestActive(any(LocalDateTime.class))).willReturn(Optional.of(notice));
		given(noticeDismissalRepository.existsByUserIdAndNoticeId(10L, 1L)).willReturn(false);

		NoticePopupResp resp = service.getLatestPopup(10L);

		assertThat(resp.show()).isTrue();
		assertThat(resp.notice()).isNotNull();
		assertThat(resp.notice().noticeId()).isEqualTo(1L);
		assertThat(resp.notice().title()).isEqualTo("점검 안내");
	}

	@Test
	void getLatestPopupReturnsShowFalseWhenLatestNoticeIsDismissed() {
		NoticeServiceImpl service = new NoticeServiceImpl(noticeRepository, noticeDismissalRepository);
		Notice notice = notice(1L, "점검 안내", "오늘 23시에 점검합니다.",
				LocalDateTime.of(2026, 5, 15, 10, 0));
		given(noticeRepository.findLatestActive(any(LocalDateTime.class))).willReturn(Optional.of(notice));
		given(noticeDismissalRepository.existsByUserIdAndNoticeId(10L, 1L)).willReturn(true);

		NoticePopupResp resp = service.getLatestPopup(10L);

		assertThat(resp.show()).isFalse();
		assertThat(resp.notice()).isNull();
	}

	@Test
	void getNoticesReturnsActiveNoticeList() {
		NoticeServiceImpl service = new NoticeServiceImpl(noticeRepository, noticeDismissalRepository);
		Notice first = notice(2L, "최신 공지", "내용2", LocalDateTime.of(2026, 5, 15, 11, 0));
		Notice second = notice(1L, "이전 공지", "내용1", LocalDateTime.of(2026, 5, 14, 11, 0));
		given(noticeRepository.findAllActive(any(LocalDateTime.class))).willReturn(List.of(first, second));

		NoticeListResp resp = service.getNotices();

		assertThat(resp.items()).extracting(NoticeResp::noticeId).containsExactly(2L, 1L);
	}

	@Test
	void getNoticeReturnsActiveNoticeDetail() {
		NoticeServiceImpl service = new NoticeServiceImpl(noticeRepository, noticeDismissalRepository);
		Notice notice = notice(1L, "상세 공지", "상세 내용", LocalDateTime.of(2026, 5, 15, 10, 0));
		given(noticeRepository.findActiveById(any(Long.class), any(LocalDateTime.class))).willReturn(Optional.of(notice));

		NoticeResp resp = service.getNotice(1L);

		assertThat(resp.noticeId()).isEqualTo(1L);
		assertThat(resp.content()).isEqualTo("상세 내용");
	}

	@Test
	void getNoticeThrowsWhenNoticeDoesNotExist() {
		NoticeServiceImpl service = new NoticeServiceImpl(noticeRepository, noticeDismissalRepository);
		given(noticeRepository.findActiveById(any(Long.class), any(LocalDateTime.class))).willReturn(Optional.empty());

		assertThatThrownBy(() -> service.getNotice(404L))
				.isInstanceOf(CustomException.class)
				.extracting("errorCode")
				.isEqualTo(NoticeErrorCode.O00_001);
	}

	@Test
	void dismissDoesNotSaveAgainWhenAlreadyDismissed() {
		NoticeServiceImpl service = new NoticeServiceImpl(noticeRepository, noticeDismissalRepository);
		Notice notice = notice(1L, "점검 안내", "내용", LocalDateTime.of(2026, 5, 15, 10, 0));
		given(noticeRepository.findActiveById(any(Long.class), any(LocalDateTime.class))).willReturn(Optional.of(notice));
		given(noticeDismissalRepository.existsByUserIdAndNoticeId(10L, 1L)).willReturn(true);

		service.dismiss(10L, 1L);

		then(noticeDismissalRepository).shouldHaveNoMoreInteractions();
	}

	@Test
	void dismissSavesWhenNotDismissedYet() {
		NoticeServiceImpl service = new NoticeServiceImpl(noticeRepository, noticeDismissalRepository);
		Notice notice = notice(1L, "점검 안내", "내용", LocalDateTime.of(2026, 5, 15, 10, 0));
		given(noticeRepository.findActiveById(any(Long.class), any(LocalDateTime.class))).willReturn(Optional.of(notice));
		given(noticeDismissalRepository.existsByUserIdAndNoticeId(10L, 1L)).willReturn(false);

		service.dismiss(10L, 1L);

		ArgumentCaptor<NoticeDismissal> captor = ArgumentCaptor.forClass(NoticeDismissal.class);
		then(noticeDismissalRepository).should().save(captor.capture());
		assertThat(captor.getValue().getUserId()).isEqualTo(10L);
		assertThat(captor.getValue().getNoticeId()).isEqualTo(1L);
	}

	private Notice notice(Long noticeId, String title, String content, LocalDateTime createdAt) {
		Notice notice = Notice.create(title, content, true, null, null);
		ReflectionTestUtils.setField(notice, "noticeId", noticeId);
		ReflectionTestUtils.setField(notice, "createdAt", createdAt);
		return notice;
	}
}
