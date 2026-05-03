import 'package:doitdo/core/network/base_repository.dart';
import 'package:doitdo/data/datasources/bug_report_api.dart';
import 'package:doitdo/domain/repositories/bug_report_repository.dart';

class BugReportRepositoryImpl extends BaseRepository
    implements BugReportRepository {
  BugReportRepositoryImpl(this._api);

  final BugReportApi _api;

  @override
  Future<void> submit({required String title, required String content}) =>
      safeApiCall(() => _api.createBugReport({'title': title, 'content': content}));
}
