import 'package:doitdo/data/models/notice_dto.dart';

/// 공지사항 도메인 계층.
///
/// - 목록·상세 조회는 일반 GET.
/// - "초기 진입 팝업" 은 별도 엔드포인트로 최신 1개 + 다시 안보기 여부를 함께 받음.
/// - "다시 안보기" 는 모달 닫을 때 토글이 켜져 있으면 POST dismiss 호출.
abstract class NoticeRepository {
  Future<List<NoticeResp>> getNotices();

  Future<NoticeResp> getNotice(int noticeId);

  Future<LatestPopupResp> getLatestPopup();

  Future<void> dismissNotice(int noticeId);
}
