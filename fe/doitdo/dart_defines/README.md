# dart_defines

빌드 타임에 주입되는 환경별 설정값. `--dart-define-from-file` 로 로드한다.

| 파일 | 환경 | 용도 |
|---|---|---|
| `dev.json` | 개발 (dev 서버) | 로컬 개발 / QA 빌드 기본값 |
| `prod.json` | 운영 (Play Store / App Store) | 스토어 출시 빌드 |

## 사용

```bash
# 개발 실행
flutter run --dart-define-from-file=dart_defines/dev.json

# 운영 빌드 (Android AAB)
flutter build appbundle --release --dart-define-from-file=dart_defines/prod.json

# 운영 빌드 (iOS IPA)
flutter build ipa --release --dart-define-from-file=dart_defines/prod.json
```

## 키 추가하는 법

1. 이 폴더의 `dev.json` / `prod.json` 양쪽에 키 추가 (둘 다 정의해야 누락 사고 방지)
2. `lib/core/config/app_config.dart` 에 `String.fromEnvironment('KEY', defaultValue: ...)` 로 노출
3. 코드에서는 `AppConfig.xxx` 로 접근

## 시크릿은 여기 두지 말 것

dart-define 값은 빌드 산출물(`.apk`/`.ipa`) 에 **평문으로 박힌다.** `strings` 명령으로 추출 가능.
Kakao 네이티브 키, Google Client ID 같은 비공개 자격증명은 계속 `.env` 에 두거나, 더 민감한 건 백엔드에서 발급받는 흐름으로 옮긴다.
