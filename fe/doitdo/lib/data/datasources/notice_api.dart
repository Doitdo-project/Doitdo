import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:doitdo/core/network/api_response.dart';
import 'package:doitdo/data/models/notice_dto.dart';

part 'notice_api.g.dart';

@RestApi()
abstract class NoticeApi {
  factory NoticeApi(Dio dio, {String baseUrl}) = _NoticeApi;

  /// 활성 공지사항 목록(최신순). 페이지네이션 없음 (현재 BE 스펙).
  @GET('/api/notices')
  Future<ApiResponse<NoticeListResp>> getNotices();

  /// 공지사항 ID 로 활성 공지 상세 조회.
  @GET('/api/notices/{noticeId}')
  Future<ApiResponse<NoticeResp>> getNotice(
    @Path('noticeId') int noticeId,
  );

  /// 초기 진입 공지 팝업 조회.
  /// 사용자가 "다시 안보기" 안 한 최신 활성 공지 1개 + show 플래그.
  @GET('/api/notices/latest-popup')
  Future<ApiResponse<LatestPopupResp>> getLatestPopup();

  /// 현재 로그인 사용자에 대해 해당 공지를 다시 보지 않도록 저장 (204 No Content).
  @POST('/api/notices/{noticeId}/dismiss')
  Future<void> dismissNotice(
    @Path('noticeId') int noticeId,
  );
}
