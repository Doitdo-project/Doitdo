import 'package:doitdo/domain/entities/auth_tokens.dart';
import 'package:doitdo/domain/entities/user.dart';

/// 인증 플로우 추상화. presentation 레이어(ViewModel)는 이 인터페이스에만 의존한다.
///
/// 실제 Google/Kakao/Apple SDK 호출, 서버 API 통신, 토큰 저장은
/// data 레이어의 `AuthRepositoryImpl` 이 담당.
abstract class AuthRepository {
  // ── 이메일 계정 ───────────────────────────────────────────────

  /// 이메일(실제로는 username) + 비밀번호 로그인.
  /// 성공 시 토큰은 secure storage 에 저장됨.
  Future<(User, AuthTokens)> signInWithEmail({
    required String username,
    required String password,
  });

  /// 회원가입. 스펙상 **토큰은 발급되지 않으므로** 성공 후 [signInWithEmail] 을
  /// 명시적으로 호출해야 세션이 생긴다.
  Future<User> signUp({
    required String email,
    required String password,
    required String username,
  });

  // ── 소셜 로그인 ───────────────────────────────────────────────

  /// Google OAuth 전체 플로우.
  /// 반환값의 boolean 은 `isNewUser` (서버 응답). 처음 가입한 계정인지 여부.
  Future<(User, AuthTokens, bool isNewUser)> signInWithGoogle();

  /// Kakao OAuth 전체 플로우. 반환 규약은 [signInWithGoogle] 과 동일.
  Future<(User, AuthTokens, bool isNewUser)> signInWithKakao();

  /// Apple Sign-In 전체 플로우. 반환 규약은 [signInWithGoogle] 과 동일.
  ///
  /// 내부에서 Apple `identityToken` 과 함께 1회용 `authorizationCode` 도 서버로 전송한다.
  /// 서버는 코드를 Apple `/auth/token` 에 교환해 refresh_token 을 저장 → 회원탈퇴 시
  /// Apple `/auth/revoke` 호출에 사용한다 (App Store 5.1.1(v) 정책 준수).
  Future<(User, AuthTokens, bool isNewUser)> signInWithApple();

  // ── 세션 관리 ─────────────────────────────────────────────────

  /// 앱 기동 시 호출. 저장된 토큰이 있고 유효하면 User 를, 없으면 null.
  Future<User?> restoreSession();

  /// 만료된 access token 을 refresh token 으로 재발급.
  /// 성공 시 새 토큰 쌍을 secure storage 에 저장하고 반환.
  Future<AuthTokens> refreshTokens();

  /// 로그아웃: 서버 세션 종료(DELETE /api/auth/logout) + 로컬 토큰 삭제 +
  /// 각 소셜 SDK 세션 해제.
  /// [skipServerLogout] 이 true 면 서버 호출 없이 로컬/SDK 정리만 수행.
  /// 회원탈퇴처럼 서버가 이미 토큰을 무효화한 경우에 사용한다.
  Future<void> signOut({bool skipServerLogout = false});

  // ── 비밀번호 재설정 (비로그인 상태에서 호출하는 3단계 플로우) ──────────

  /// 1단계 — 입력한 이메일로 인증번호(OTP) 발송 요청.
  Future<void> requestPasswordResetCode(String email);

  /// 2단계 — 인증번호 검증. 성공 시 3단계에서 쓸 1회용 `resetToken` 반환.
  Future<String> verifyPasswordResetCode({
    required String email,
    required String code,
  });

  /// 3단계 — `resetToken` 으로 새 비밀번호 설정.
  /// 성공해도 세션은 만들지 않는다 — 호출측이 로그인 화면으로 보내야 한다.
  Future<void> confirmPasswordReset({
    required String resetToken,
    required String newPassword,
  });

  // 이메일/닉네임 중복체크는 `/api/users/*` 경로라 UserRepository 쪽에 둔다
  // (URL prefix 와 일치). AuthRepository 에서 제공하지 않음.
}
