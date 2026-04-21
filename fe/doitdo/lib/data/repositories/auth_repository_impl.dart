import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart';
// Kakao SDK 의 `User` 모델은 우리 도메인의 [User] 엔티티와 이름이 겹치므로 hide.
// 실제로 우리가 Kakao SDK 에서 사용하는 건 UserApi / OAuthToken / isKakaoTalkInstalled 뿐.
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' hide User;

import 'package:doitdo/core/errors/exceptions.dart';
import 'package:doitdo/data/datasources/auth_local_data_source.dart';
import 'package:doitdo/data/datasources/auth_remote_data_source.dart';
import 'package:doitdo/domain/entities/auth_tokens.dart';
import 'package:doitdo/domain/entities/user.dart';
import 'package:doitdo/domain/repositories/auth_repository.dart';

/// [AuthRepository] 구현체.
///
/// presentation 레이어(ViewModel)에서는 [AuthRepository] 인터페이스에만 의존하고,
/// 이 구현체는 DI (app_data_providers.dart) 에서 주입된다.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this.remote,
    required this.local,
    required this.googleSignIn,
  });

  final AuthRemoteDataSource remote;
  final AuthLocalDataSource local;
  final GoogleSignIn googleSignIn;

  @override
  Future<(User, AuthTokens)> signInWithGoogle() async {
    // 1. Google 네이티브 로그인 시트 호출
    final account = await googleSignIn.signIn();
    if (account == null) {
      // 사용자가 취소한 케이스 — ViewModel 에서 에러 메시지 없이 조용히 return 처리용.
      throw const AuthCanceledException();
    }

    final auth = await account.authentication;
    // 백엔드 스펙상 accessToken 을 사용한다 (Kakao 와 통일).
    // 서버가 이 토큰으로 Google userinfo API 를 호출해서 유저 정보를 조회함.
    final accessToken = auth.accessToken;
    if (accessToken == null) {
      throw const AuthException('Google Access Token 을 받지 못했습니다.');
    }

    // 2. 서버에 access token 전달 → 우리 서비스 세션 발급
    final dto = await remote.loginWithGoogle(accessToken: accessToken);

    // 3. 토큰 로컬 저장
    await local.save(dto.tokens);

    return (dto.user.toEntity(), dto.tokens);
  }

  @override
  Future<(User, AuthTokens)> signInWithKakao() async {
    // 1. Kakao 네이티브 로그인.
    //    카카오톡 앱이 설치돼 있으면 앱-투-앱으로 먼저 시도하고,
    //    디바이스 권한 화면에서 사용자가 취소했거나 연결된 카카오계정이 없으면
    //    카카오계정 웹 로그인으로 폴백하는 게 Kakao 공식 권장 플로우.
    OAuthToken token;
    try {
      if (await isKakaoTalkInstalled()) {
        try {
          token = await UserApi.instance.loginWithKakaoTalk();
        } on PlatformException catch (e) {
          // 'CANCELED' 는 사용자가 명시적으로 취소 버튼을 누른 경우 — 폴백 없이 중단.
          if (e.code == 'CANCELED') {
            throw const AuthCanceledException();
          }
          // 그 외 (카카오톡에 연결된 계정 없음 등) → 카카오계정 웹 로그인 폴백.
          token = await UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
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
    final dto = await remote.loginWithKakao(accessToken: token.accessToken);

    // 3. 토큰 로컬 저장
    await local.save(dto.tokens);

    return (dto.user.toEntity(), dto.tokens);
  }

  @override
  Future<User?> restoreSession() async {
    final tokens = await local.read();
    if (tokens == null) return null;
    // TODO: 백엔드에 `GET /api/auth/me` 엔드포인트가 생기면 그걸로 토큰 유효성 + 유저 정보 확인.
    //       현재는 토큰이 있으면 "일단 유효" 로 간주하고 null 반환 (= 재로그인 요구).
    //       스펙 확정 후 활성화.
    return null;
  }

  @override
  Future<void> signOut() async {
    // 서버 세션 종료는 실패해도 로컬은 반드시 정리한다.
    try {
      await remote.logout();
    } catch (_) {
      // no-op
    }
    await local.clear();
    // 어느 provider 로 로그인했는지 추적하지 않으므로 두 SDK 모두 안전하게 로그아웃 시도.
    // 각 SDK 는 "세션 없음" 을 예외로 던질 수 있어 try 로 감싼다.
    try {
      await googleSignIn.signOut();
    } catch (_) {
      // Google 로그아웃 실패해도 앱 로그아웃 자체엔 영향 없음.
    }
    try {
      await UserApi.instance.logout();
    } catch (_) {
      // Kakao 세션이 없거나 만료돼도 무시.
    }
  }
}
