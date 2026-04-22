class NetworkException implements Exception {
  NetworkException(this.message);
  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

class ServerException implements Exception {
  ServerException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'ServerException($statusCode): $message';
}

class CacheException implements Exception {
  CacheException(this.message);
  final String message;

  @override
  String toString() => 'CacheException: $message';
}

/// 인증 플로우 일반 오류.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => 'AuthException: $message';
}

/// 사용자가 OAuth 시트에서 취소 버튼을 눌렀을 때 발생.
/// 에러로 간주하지 않고 조용히 처리 (스낵바 등 띄우지 않음).
class AuthCanceledException implements Exception {
  const AuthCanceledException();

  @override
  String toString() => 'AuthCanceledException';
}
