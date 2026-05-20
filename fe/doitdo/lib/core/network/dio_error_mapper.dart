import 'package:dio/dio.dart';
import 'package:doitdo/core/errors/exceptions.dart';

/// [DioException] 을 프로젝트의 타입드 예외로 매핑한다.
Exception mapDioException(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const RequestTimeoutException('응답이 조금 늦어지고 있어요. 잠시 후 다시 시도해 주세요.');

    case DioExceptionType.connectionError:
      return const NetworkException('연결 상태가 좋지 않아요. 확인 후 다시 시도해 주세요.');

    case DioExceptionType.badResponse:
      final statusCode = error.response?.statusCode ?? -1;
      final body = error.response?.data;
      final message =
          _extractServerMessage(body) ?? _defaultMessageFor(statusCode);
      final code = _extractServerCode(body);

      if (statusCode == 401) {
        return UnauthorizedException(message);
      }
      return ServerException(message, statusCode: statusCode, code: code);

    case DioExceptionType.cancel:
      return const UnknownException('요청이 취소되었어요.');

    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      return const UnknownException('일시적인 오류가 발생했어요. 잠시 후 다시 시도해 주세요.');
  }
}

String? _extractServerMessage(Object? responseData) {
  if (responseData is Map<String, dynamic>) {
    final value = responseData['message'];
    if (value is String && value.isNotEmpty) return value;
  }
  return null;
}

String? _extractServerCode(Object? responseData) {
  if (responseData is Map<String, dynamic>) {
    final value = responseData['code'];
    if (value is String && value.isNotEmpty) return value;
  }
  return null;
}

/// 기술 용어를 일상어로 순화한 폴백 메시지.
String _defaultMessageFor(int statusCode) {
  if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
    return '연결이 일시적으로 원활하지 않아요. 잠시 후 다시 시도해 주세요.';
  }
  if (statusCode >= 500) {
    return '잠시 문제가 생겼어요. 금방 고쳐놓을게요. 잠시 후 다시 시도해 주세요.';
  }
  if (statusCode == 404) {
    return '항목을 찾을 수 없어요. 이미 삭제되었을 수 있어요.';
  }
  if (statusCode == 403) {
    return '접근할 수 없는 항목이에요.';
  }
  if (statusCode == 409) {
    return '이미 처리된 내용이에요.';
  }
  if (statusCode == 422) {
    return '입력하신 내용을 다시 확인해 주세요.';
  }
  if (statusCode >= 400) {
    return '요청한 내용을 처리할 수 없어요. 내용을 확인해 주세요.';
  }
  return '일시적인 오류가 발생했어요. 잠시 후 다시 시도해 주세요.';
}
