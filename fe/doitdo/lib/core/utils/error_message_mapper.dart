import 'package:doitdo/core/errors/exceptions.dart';

/// 타입드 예외 → 사용자에게 보여줄 메시지 매핑.
///
/// DEVELOPMENT_GUIDE §12.6 — `AsyncValue.error` 에 실린 예외를 UI 에서
/// 그대로 text 로 변환하는 공용 헬퍼. 화면마다 switch 문을 반복하지 않도록
/// 여기서 한 번만 정의한다.
///
/// [AuthCanceledException] 은 "사용자가 직접 취소" 라서 별도 UI 필요 없음.
/// 호출측에서 미리 걸러내는 게 일반적이지만, 여기선 일관된 기본 메시지로 매핑.
String mapErrorMessage(Object error) {
  return switch (error) {
    UnauthorizedException _ => '다시 로그인해 주세요.',
    NetworkException _ => '네트워크 연결을 확인해 주세요.',
    RequestTimeoutException _ => '응답이 지연되고 있어요. 잠시 후 다시 시도해 주세요.',
    ServerException e => e.message,
    AuthException e => e.message,
    AuthCanceledException _ => '로그인이 취소되었어요.',
    _ => '알 수 없는 오류가 발생했어요.',
  };
}
