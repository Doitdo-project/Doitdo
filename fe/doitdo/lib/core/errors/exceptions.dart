class NetworkException implements Exception {
  const NetworkException(this.message);
  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

/// 요청/수신 타임아웃. [NetworkException] 과 구분해서 재시도 UX 에 활용할 수 있게 둔다.
class RequestTimeoutException implements Exception {
  const RequestTimeoutException(this.message);
  final String message;

  @override
  String toString() => 'RequestTimeoutException: $message';
}

class ServerException implements Exception {
  const ServerException(this.message, {this.statusCode, this.code});
  final String message;
  final int? statusCode;

  /// 서버 정의 비즈니스 에러 코드(예: "A04-006") — envelope `code` 필드에서 옮겨온다.
  /// 동일 statusCode 안에서 도메인별 분기에 쓰인다. (예: 409 + A04-006 → 소셜 가입자)
  final String? code;

  @override
  String toString() =>
      'ServerException($statusCode${code != null ? '/$code' : ''}): $message';
}

/// HTTP 401. 세션 만료/미인증 시 글로벌로 로그인 화면으로 튕기기 위해 분리.
class UnauthorizedException implements Exception {
  const UnauthorizedException(this.message);
  final String message;

  @override
  String toString() => 'UnauthorizedException: $message';
}

/// 매핑되지 않은 모든 예외를 감싸는 최종 폴백.
class UnknownException implements Exception {
  const UnknownException(this.message);
  final String message;

  @override
  String toString() => 'UnknownException: $message';
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
