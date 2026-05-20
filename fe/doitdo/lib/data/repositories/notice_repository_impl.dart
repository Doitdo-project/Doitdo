import 'package:doitdo/core/network/base_repository.dart';
import 'package:doitdo/data/datasources/notice_api.dart';
import 'package:doitdo/data/models/notice_dto.dart';
import 'package:doitdo/domain/repositories/notice_repository.dart';

class NoticeRepositoryImpl extends BaseRepository implements NoticeRepository {
  NoticeRepositoryImpl(this._api);

  final NoticeApi _api;

  @override
  Future<List<NoticeResp>> getNotices() =>
      safeApiCall(() => _api.getNotices()).then((resp) => resp.items);

  @override
  Future<NoticeResp> getNotice(int noticeId) =>
      safeApiCall(() => _api.getNotice(noticeId));

  @override
  Future<LatestPopupResp> getLatestPopup() =>
      safeApiCall(() => _api.getLatestPopup());

  @override
  Future<void> dismissNotice(int noticeId) =>
      safeApiCallVoid(() => _api.dismissNotice(noticeId));
}
