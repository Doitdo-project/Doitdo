import 'package:doitdo/domain/entities/auth_tokens.dart';
import 'package:doitdo/domain/entities/user.dart';

/// 인증 플로우 추상화. presentation 레이어(ViewModel)는 이 인터페이스에만 의존한다.
///
/// 실제 Google/Kakao/Apple SDK 호출, 서버 API 통신, 토큰 저장은
/// data 레이어의 [AuthRepositoryImpl] 이 담당.
///
/// Apple 메서드는 Mac 빌드 환경 준비 및 백엔드 엔드포인트 확정 후 추가 예정.
abstract class AuthRepository {
  /// Google OAuth 전체 플로우.
  /// 성공 시 발급된 토큰은 secure storage 에 저장되어 있다.
  /// 사용자가 취소했거나 실패 시 예외 throw.
  Future<(User, AuthTokens)> signInWithGoogle();

  /// Kakao OAuth 전체 플로우.
  /// 카카오톡 앱 설치 여부에 따라 네이티브 / 웹 로그인으로 분기하며,
  /// 성공 시 발급된 토큰은 secure storage 에 저장된다.
  /// 사용자가 취소한 경우 AuthCanceledException, 그 외 실패는 AuthException.
  Future<(User, AuthTokens)> signInWithKakao();

  /// 앱 기동 시 호출. 저장된 토큰이 있고 유효하면 User 를, 없으면 null.
  Future<User?> restoreSession();

  /// 로그아웃: 서버 세션 종료 + 로컬 토큰 삭제 + 각 소셜 세션 해제.
  Future<void> signOut();
}
