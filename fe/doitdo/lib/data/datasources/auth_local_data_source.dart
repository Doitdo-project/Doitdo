import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:doitdo/domain/entities/auth_tokens.dart';

/// 토큰 전용 로컬 저장소.
///
/// - iOS: Keychain
/// - Android: EncryptedSharedPreferences (API 23+)
///
/// SharedPreferences 에는 절대 토큰 저장하지 말 것 — 루팅/탈옥 기기에서 평문 유출.
class AuthLocalDataSource {
  AuthLocalDataSource(this._storage);

  final FlutterSecureStorage _storage;

  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';

  Future<void> save(AuthTokens tokens) async {
    await _storage.write(key: _kAccess, value: tokens.accessToken);
    await _storage.write(key: _kRefresh, value: tokens.refreshToken);
  }

  Future<AuthTokens?> read() async {
    final access = await _storage.read(key: _kAccess);
    final refresh = await _storage.read(key: _kRefresh);
    if (access == null || refresh == null) return null;
    return AuthTokens(accessToken: access, refreshToken: refresh);
  }

  Future<String?> readAccessToken() => _storage.read(key: _kAccess);

  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }
}
