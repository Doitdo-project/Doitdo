import 'package:doitdo/core/config/flavor.dart';

/// 빌드 타임에 결정되는 환경 설정의 단일 진입점.
///
/// 모든 값은 `--dart-define` (혹은 `--dart-define-from-file`) 로 주입된다.
/// `String.fromEnvironment` 는 컴파일 타임 상수라 release 빌드에서도
/// 분기/문자열이 그대로 박힌다 → 런타임 조건부 fetch 보다 빠르고 안전.
///
/// IDE 실행: `dart_defines/dev.json` (기본) / `dart_defines/prod.json`.
/// CLI: `flutter run --dart-define-from-file=dart_defines/dev.json`
///
/// **시크릿(Kakao 키, Google Server Client ID) 은 여전히 `.env`** 에 둔다.
/// dart-define 으로 들어온 값은 빌드 산출물에 평문으로 박혀 누구나 strings 로
/// 추출 가능하므로, 진짜 비밀은 .env (gitignored) → 향후 백엔드 발급 흐름으로 옮긴다.
class AppConfig {
  AppConfig._();

  static const String _flavorRaw = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );

  /// 현재 빌드의 Flavor.
  static final Flavor flavor = Flavor.fromString(_flavorRaw);

  /// REST API base URL. 끝에 슬래시를 붙이지 않는다 (Retrofit path 와 합쳐질 때 중복 방지).
  ///
  /// 기본값은 dev 서버 — JSON 파일을 빠뜨리고 실행해도 dev 로 떨어지게.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://dev-api.doitdo.site',
  );

  /// 디버그 로깅/배지 표시 여부. prod 빌드에서는 꺼지도록 dev 기본값.
  static bool get isDebugBadgeVisible => flavor.isDev;
}
