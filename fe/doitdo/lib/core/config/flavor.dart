/// 빌드 타임에 결정되는 환경 식별자.
///
/// `--dart-define=FLAVOR=dev|prod` 로 주입된다.
/// 실행 시점이 아니라 **컴파일 시점**에 박히는 값이라 release 빌드에서도
/// 변하지 않으며, 분기 코드는 tree-shaking 으로 제거된다.
enum Flavor {
  dev,
  prod;

  /// 외부에 노출되는 표시용 이름 ("DEV" 배지, 로그 prefix 등).
  String get label => switch (this) {
        Flavor.dev => 'DEV',
        Flavor.prod => 'PROD',
      };

  bool get isDev => this == Flavor.dev;
  bool get isProd => this == Flavor.prod;

  static Flavor fromString(String raw) => switch (raw.toLowerCase()) {
        'prod' || 'production' || 'release' => Flavor.prod,
        _ => Flavor.dev,
      };
}
