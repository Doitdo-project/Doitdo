import 'package:dio/dio.dart';

import 'package:doitdo/core/errors/exceptions.dart';

/// [DioException] 을 프로젝트의 타입드 예외로 매핑한다.
///
/// [BaseRepository.safeApiCall] 내부에서만 쓰이며, 이 덕분에 ViewModel 은 Dio
/// 자체를 import 하지 않고도 네트워크 실패를 일관된 타입으로 다룰 수 있다.
///
/// HTTP 상태코드별 분기는 [DioExceptionType.badResponse] 안에서 처리한다.
/// - 401 → [UnauthorizedException] (세션 만료 → 로그인 화면으로 튕김 처리 용이)
/// - 그 외 4xx/5xx → [ServerException]
Exception mapDioException(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const RequestTimeoutException('요청 시간이 초과되었습니다.');

    case DioExceptionType.connectionError:
      return const NetworkException('네트워크에 연결할 수 없습니다.');

    case DioExceptionType.badResponse:
      final statusCode = error.response?.statusCode ?? -1;
      final message = _extractServerMessage(error.response?.data) ??
          error.message ??
          '서버 오류가 발생했습니다.';
      if (statusCode == 401) {
        return UnauthorizedException(message);
      }
      return ServerException(message, statusCode: statusCode);

    case DioExceptionType.cancel:
      return const UnknownException('요청이 취소되었습니다.');

    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      return UnknownException(error.message ?? '알 수 없는 오류가 발생했습니다.');
  }
}

/// envelope 응답(`{status, message, data}`)이 에러 시에도 그대로 내려올 때
/// `message` 필드를 뽑아 사용자에게 보여주기 좋은 문구로 변환한다.
String? _extractServerMessage(Object? responseData) {
  if (responseData is Map<String, dynamic>) {
    final value = responseData['message'];
    if (value is String && value.isNotEmpty) return value;
  }
  return null;
}