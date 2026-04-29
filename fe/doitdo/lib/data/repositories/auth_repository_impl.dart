import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart';
// Kakao SDK 는 우리 프로젝트의 `User` / `UserApi` 와 이름이 모두 겹치므로 별칭(kakao)으로 분리.
// 도메인 User 엔티티, 우리 UserApi 클래스는 아래 package:doitdo/... import 를 통해 사용.
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:doitdo/core/errors/exceptions.dart';
import 'package:doitdo/core/network/base_repository.dart';
import 'package:doitdo/core/widget_sync/widget_sync_service.dart';
import 'package:doitdo/data/datasources/auth_api.dart';
import 'package:doitdo/data/datasources/auth_local_data_source.dart';
import 'package:doitdo/data/models/login_request_dto.dart';
import 'package:doitdo/data/models/refresh_request_dto.dart';
import 'package:doitdo/data/models/signup_request_dto.dart';
import 'package:doitdo/data/models/social_login_request_dto.dart';
import 'package:doitdo/domain/entities/auth_tokens.dart';
import 'package:doitdo/domain/entities/user.dart';
import 'package:doitdo/domain/repositories/auth_repository.dart';

/// [AuthRepository] 구현체.
///
/// presentation 레이어(ViewModel)에서는 [AuthRepository] 인터페이스에만 의존하고,
/// 이 구현체는 DI (app_data_providers.dart) 에서 주입된다.
///
/// 이 레이어에서는 **try/catch 금지** — [safeApiCall] 이 DioException 을 NetworkException /
/// ServerException / UnauthorizedException 등 타입드 예외로 이미 변환한다.
/// 단, OAuth SDK 단계는 예외 — 사용자 취소를 [AuthCanceledException] 으로 변환하기
/// 위해 플랫폼 채널 예외를 별도로 처리한다.
class AuthRepositoryImpl extends BaseRepository implements AuthRepository {
  AuthRepositoryImpl({
    required this.authApi,
    required this.local,
    required this.googleSignIn,
    required this.widgetSync,
    required this.apiBaseUrl,
  });

  final AuthApi authApi;
  final AuthLocalDataSource local;
  final GoogleSignIn googleSignIn;

  /// 홈스크린 위젯 (iOS/Android) 으로 토큰 변경을 전파.
  /// 위젯의 백그라운드 AppIntent/Provider 가 PATCH 호출에 사용한다.
  final WidgetSyncService widgetSync;

  /// 위젯이 PATCH 호출할 때 prefix 로 사용할 베이스 URL — 토큰과 함께 같이 저장.
  /// 환경별 (dev/prod) 다르므로 빌드 타임 주입 (`AppConfig.apiBaseUrl` ← --dart-define).
  final String apiBaseUrl;

  // ── 이메일 계정 ───────────────────────────────────────────────

  @override
  Future<(User, AuthTokens)> signInWithEmail({
    required String username,
    required String password,
  }) async {
    final dto = await safeApiCall(
      () => authApi.login(
        LoginRequestDto(username: username, password: password),
      ),
    );
    await local.save(dto.tokens);
    await _syncTokensToWidget(dto.tokens);
    return (dto.user.toEntity(), dto.tokens);
  }

  @override
  Future<User> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    // 회원가입은 토큰을 발급하지 않음 — 성공 시 도메인 User 만 반환하고,
    // 호출측 ViewModel 이 이어서 signInWithEmail 을 호출해 세션을 얻게 한다.
    final dto = await safeApiCall(
      () => authApi.signUp(
        SignUpRequestDto(
          email: email,
          password: password,
          username: username,
        ),
      ),
    );
    return dto.toEntity();
  }

  // ── 소셜 로그인 ───────────────────────────────────────────────

  @override
  Future<(User, AuthTokens, bool isNewUser)> signInWithGoogle() async {
    // 1. Google 네이티브 로그인 시트.
    //
    // SDK 의 PlatformException 을 그대로 흘려보내면 UI 의 mapErrorMessage 에서
    // '알 수 없는 오류' 로 떨어져 SHA-1 미등록(DEVELOPER_ERROR/10) / network_error /
    // serverClientId 오설정 같은 진단 단서가 묻힌다. Kakao 분기처럼 code+message 를
    // AuthException 으로 변환해 스낵바에 그대로 보이게 한다.
    final String idToken;
    try {
      final account = await googleSignIn.signIn();
      if (account == null) {
        // 사용자가 계정 선택 시트에서 뒤로가기로 취소한 케이스.
        throw const AuthCanceledException();
      }
      final auth = await account.authentication;
      // ⚠️ 백엔드는 Google **ID Token**(JWT) 을 넘겨받아 aud 검증을 한다.
      //   access_token 이 아니라 id_token 을 보내야 함. 스펙상 body 필드명은
      //   카카오와 통일을 위해 `accessToken` 이지만 담는 값은 ID Token.
      //   (id_token 을 받기 위해 GoogleSignIn 생성자에 serverClientId 지정 필수)
      final token = auth.idToken;
      if (token == null) {
        throw const AuthException(
          'Google ID Token 을 받지 못했습니다. serverClientId 설정을 확인하세요.',
        );
      }
      idToken = token;
    } on AuthCanceledException {
      rethrow;
    } on AuthException {
      rethrow;
    } on PlatformException catch (e) {
      // google_sign_in 의 취소 코드는 'sign_in_canceled' 가 표준이지만 플랫폼/버전에
      // 따라 'canceled' 단독으로 오는 케이스도 있어 둘 다 매칭.
      final code = e.code.toLowerCase();
      if (code.contains('cancel')) {
        throw const AuthCanceledException();
      }
      throw AuthException(
        'Google 로그인 실패: ${e.code}${e.message != null ? ' / ${e.message}' : ''}',
      );
    } catch (e) {
      throw AuthException('Google 로그인 실패: $e');
    }

    // 2. 서버에 ID Token 전달 → 우리 서비스 세션 발급
    return _completeSocialLogin(provider: 'GOOGLE', providerToken: idToken);
  }

  @override
  Future<(User, AuthTokens, bool isNewUser)> signInWithKakao() async {
    // 1. Kakao 네이티브 로그인 (앱/계정 폴백).
    kakao.OAuthToken token;
    try {
      if (await kakao.isKakaoTalkInstalled()) {
        try {
          token = await kakao.UserApi.instance.loginWithKakaoTalk();
        } on PlatformException catch (e) {
          if (e.code == 'CANCELED') {
            throw const AuthCanceledException();
          }
          // 카카오톡에 연결된 계정 없음 등 → 계정 웹 로그인 폴백.
          token = await kakao.UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        token = await kakao.UserApi.instance.loginWithKakaoAccount();
      }
    } on AuthCanceledException {
      rethrow;
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED') {
        throw const AuthCanceledException();
      }
      throw AuthException('Kakao 로그인 실패: ${e.message ?? e.code}');
    } catch (e) {
      throw AuthException('Kakao 로그인 실패: $e');
    }

    // 2. 서버에 access token 전달 → 우리 서비스 세션 발급
    return _completeSocialLogin(
      provider: 'KAKAO',
      providerToken: token.accessToken,
    );
  }

  @override
  Future<(User, AuthTokens, bool isNewUser)> signInWithApple() async {
    // 1. Apple 네이티브 로그인 시트.
    //    scopes 는 첫 로그인 시점에만 의미가 있다 — Apple 은 동일 사용자의 두 번째 이후
    //    로그인부터 email/이름을 내려주지 않는다. 백엔드는 첫 로그인의 email 만으로
    //    가입 처리를 끝내므로 별도 캐싱 불필요.
    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthCanceledException();
      }
      throw AuthException('Apple 로그인 실패: ${e.message}');
    }

    final identityToken = credential.identityToken;
    final authorizationCode = credential.authorizationCode;
    // identityToken 은 서버 검증용, authorizationCode 는 서버측 refresh_token 교환용.
    // 둘 중 하나라도 없으면 서버 호출 자체가 무의미 — 백엔드가 거절(A03-001/002)하기 전에
    // 클라이언트 단에서 명확한 메시지로 실패시킨다.
    if (identityToken == null) {
      throw const AuthException(
        'Apple 로그인 응답에 identityToken 이 없습니다. 잠시 후 다시 시도해주세요.',
      );
    }
    if (authorizationCode.isEmpty) {
      throw const AuthException(
        'Apple 로그인 응답에 authorizationCode 가 없습니다. 잠시 후 다시 시도해주세요.',
      );
    }

    // 2. 서버에 identityToken + authorizationCode 전달 → 우리 서비스 세션 발급.
    return _completeSocialLogin(
      provider: 'APPLE',
      providerToken: identityToken,
      appleAuthorizationCode: authorizationCode,
    );
  }

  /// Google/Kakao/Apple 공통 마지막 단계 — 서버 교환 + 토큰 저장.
  ///
  /// [appleAuthorizationCode] 는 APPLE 호출 전용. 다른 provider 에선 null.
  Future<(User, AuthTokens, bool isNewUser)> _completeSocialLogin({
    required String provider,
    required String providerToken,
    String? appleAuthorizationCode,
  }) async {
    final dto = await safeApiCall(
      () => authApi.socialLogin(
        provider,
        SocialLoginRequestDto(
          accessToken: providerToken,
          appleAuthorizationCode: appleAuthorizationCode,
        ),
      ),
    );
    await local.save(dto.tokens);
    await _syncTokensToWidget(dto.tokens);
    return (dto.user.toEntity(), dto.tokens, dto.isNewUser ?? false);
  }

  // ── 세션 관리 ─────────────────────────────────────────────────

  @override
  Future<User?> restoreSession() async {
    final tokens = await local.read();
    if (tokens == null) return null;
    // TODO: `GET /api/auth/me` 또는 유사 엔드포인트가 생기면 그걸로 토큰 유효성 + 유저 정보 확인.
    //       현재는 토큰이 있어도 null 반환 → 재로그인 요구. 스펙 확정 후 활성화.
    return null;
  }

  @override
  Future<AuthTokens> refreshTokens() async {
    final stored = await local.read();
    if (stored == null) {
      throw const UnauthorizedException('저장된 리프레시 토큰이 없습니다.');
    }
    final dto = await safeApiCall(
      () => authApi.refresh(
        RefreshRequestDto(refreshToken: stored.refreshToken),
      ),
    );
    final newTokens = dto.toEntity();
    await local.save(newTokens);
    await _syncTokensToWidget(newTokens);
    return newTokens;
  }

  @override
  Future<void> signOut() async {
    // 서버 세션 종료는 실패해도 로컬 정리는 반드시 수행.
    // safeApiCallNoData 는 DioException 을 타입드 예외로 변환하지만, 여기서는
    // 네트워크 실패에도 로컬만 비워주는 게 UX 상 자연스러워 try 로 감싼다.
    try {
      await safeApiCallNoData(() => authApi.logout());
    } catch (_) {
      // no-op — 로컬 정리는 아래에서 계속 진행.
    }
    await local.clear();
    // 홈스크린 위젯에 남은 토큰/TODO 데이터도 비운다 — 디바이스를 다른 사람이 받았을 때
    // 이전 사용자 데이터가 위젯에 남아있는 사고 방지.
    await widgetSync.clearAll();

    // 어느 provider 로 로그인했는지 추적하지 않으므로 두 SDK 모두 안전하게 로그아웃 시도.
    try {
      await googleSignIn.signOut();
    } catch (_) {
      // Google 세션 없음 → 무시.
    }
    try {
      await kakao.UserApi.instance.logout();
    } catch (_) {
      // Kakao 세션 없음/만료 → 무시.
    }
  }

  // 이메일/닉네임 중복체크는 UserRepository 가 담당. AuthRepository 는
  // 순수한 인증/세션 관리에만 집중한다.

  /// 위젯이 백그라운드에서 우리 API 를 직접 호출하도록 토큰 + base URL 을 공유 영역에 저장.
  /// 실패는 무시 — 위젯이 안 떠 있어도 본 인증 흐름은 정상 진행되어야 한다.
  Future<void> _syncTokensToWidget(AuthTokens tokens) async {
    await widgetSync.syncAuthTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      apiBaseUrl: apiBaseUrl,
    );
  }
}
