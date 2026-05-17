import 'package:freezed_annotation/freezed_annotation.dart';

part 'notice_dto.freezed.dart';
part 'notice_dto.g.dart';

/// 공지사항 단일 항목 DTO.
///
/// BE 스웨거 기준 필드: noticeId, title, content, startedAt, endedAt, createdAt.
/// 시간은 ISO-8601 문자열로 내려와서 FE 에서 [DateTime.parse] 로 변환한다.
/// (DateTime 직접 매핑은 timezone 처리 미스 가능성 있어 String 으로 받는다)
@freezed
class NoticeResp with _$NoticeResp {
  const factory NoticeResp({
    required int noticeId,
    required String title,
    required String content,
    String? startedAt,
    String? endedAt,
    String? createdAt,
  }) = _NoticeResp;

  factory NoticeResp.fromJson(Map<String, dynamic> json) =>
      _$NoticeRespFromJson(json);
}

/// `GET /api/notices` 응답 — 활성 공지사항 목록(최신순).
@freezed
class NoticeListResp with _$NoticeListResp {
  const factory NoticeListResp({
    required List<NoticeResp> items,
  }) = _NoticeListResp;

  factory NoticeListResp.fromJson(Map<String, dynamic> json) =>
      _$NoticeListRespFromJson(json);
}

/// `GET /api/notices/latest-popup` 응답.
///
/// 초기 진입 시 표시할 공지가 있고, 현재 사용자가 "다시 안보기" 설정을 안 했으면
/// [show] = true 와 [notice] 를 함께 반환한다. 둘 다 없으면 모달을 띄우지 않는다.
@freezed
class LatestPopupResp with _$LatestPopupResp {
  const factory LatestPopupResp({
    required bool show,
    NoticeResp? notice,
  }) = _LatestPopupResp;

  factory LatestPopupResp.fromJson(Map<String, dynamic> json) =>
      _$LatestPopupRespFromJson(json);
}
