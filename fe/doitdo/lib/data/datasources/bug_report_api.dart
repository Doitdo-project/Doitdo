import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:doitdo/core/network/api_response.dart';
import 'package:doitdo/data/models/bug_report_dto.dart';

part 'bug_report_api.g.dart';

@RestApi()
abstract class BugReportApi {
  factory BugReportApi(Dio dio, {String baseUrl}) = _BugReportApi;

  @POST('/api/bug-reports')
  Future<ApiResponse<BugReportResp>> createBugReport(
    @Body() Map<String, dynamic> body,
  );
}
