import 'package:doitdo/core/errors/exceptions.dart';

/// 타입드 예외 → 사용자에게 보여줄 메시지 매핑.
///
/// 지침: 3인칭 화법 금지, 기술 용어 배제, 부드러운 종결 어미 사용.
String mapErrorMessage(Object error) {
  return switch (error) {
    UnauthorizedException _ =>
    '로그인 정보가 만료되었어요. 다시 로그인해 주세요.',

    NetworkException _ =>
    '연결 상태가 좋지 않아요. 확인 후 다시 시도해 주세요.',

    RequestTimeoutException _ =>
    '응답이 조금 늦어지고 있어요. 잠시 후 다시 시도해 주세요.',

    ServerException e => _mapServerException(e),

    AuthException _ =>
    '로그인을 완료하지 못했어요. 잠시 후 다시 시도해 주세요.',

    AuthCanceledException _ =>
    '로그인이 취소되었어요.',

    _ =>
    '일시적인 오류가 발생했어요. 잠시 후 다시 시도해 주세요.',
  };
}

/// HTTP 상태코드 기반 친절한 문구 분기.
String _mapServerException(ServerException e) {
  // 1. 서버가 보내준 한국어 메시지가 있으면 그대로 노출.
  //    ex) "이미 일반 계정으로 가입된 이메일입니다. 아이디/비밀번호로 로그인해주세요."
  // 2. 영문이거나 개발용 문구(5xx)는 아래 공용 문구로 대체.
  final isKorean = RegExp(r'[가-힣]').hasMatch(e.message);
  if (e.message.isNotEmpty &&
      e.statusCode != null &&
      e.statusCode! < 500 &&
      isKorean) {
    return e.message;
  }

  return switch (e.statusCode) {
    400 => '요청한 내용을 처리할 수 없어요. 다시 한번 확인해 주세요.',
    403 => '접근할 수 없는 항목이에요.',
    404 => '항목을 찾을 수 없어요. 이미 삭제되었을 수 있어요.',
    409 => '이미 처리된 내용이에요.',
    422 => '입력하신 내용을 다시 확인해 주세요.',
    426 => '앱을 최신 버전으로 업데이트해 주세요.',
    500 => '잠시 문제가 생겼어요. 금방 고쳐놓을게요. 잠시 후 다시 시도해 주세요.',
    502 || 503 || 504 => '연결이 일시적으로 원활하지 않아요. 잠시 후 다시 시도해 주세요.',
    _ => '일시적인 오류가 발생했어요. 잠시 후 다시 시도해 주세요.',
  };
}