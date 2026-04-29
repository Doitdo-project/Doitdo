# FE Android + 기타 리뷰 결과

## 검토 요약

- 검토 파일 수: 27개 (이미지 파일 제외)
- HIGH: 3건 / MEDIUM: 4건 / LOW: 4건
- 6축 커버리지:
  | 축 | 검토 여부 | 주요 발견 |
  |---|---|---|
  | Android 위젯 | 완료 | goAsync 타임아웃 초과 위험 (MEDIUM), SharedPreferences 동시성 (MEDIUM) |
  | Manifest/Permissions | 완료 | PendingIntent pre-S mutable (MEDIUM), Kakao scheme 빈 문자열 (HIGH) |
  | build.gradle.kts | 완료 | 서명 설정 안전, 의존성 버전 명시적 |
  | google-services.json | 완료 | API 키 커밋됨 (MEDIUM), oauth_client 미등록 (MEDIUM) |
  | Web/PWA | 완료 | CSP 없음 (LOW), 기본값 description/theme_color (LOW) |
  | 루트 파일 | 완료 | .env asset 번들 위험 (HIGH), 토큰 평문 저장 정책-구현 불일치 (HIGH) |

---

## HIGH (반드시 머지 전 수정)

### [HIGH-1] `.env` 파일이 Flutter asset 으로 번들 — 배포 빌드에 시크릿 노출 가능

- 파일: `fe/doitdo/pubspec.yaml:115`
- 문제: `pubspec.yaml` assets 목록에 `.env` 가 등록되어 있어 `flutter build apk/appbundle/web` 시 `.env` 파일이 APK/AAB/web 산출물 안에 그대로 번들됨
- 영향: `.env` 에 `KAKAO_NATIVE_APP_KEY`, `GOOGLE_SERVER_CLIENT_ID`, `API_BASE_URL` 등이 담길 경우 apktool 이나 단순 unzip 으로 누구든 추출 가능. `.env.example` 주석("클라이언트에 절대 넣지 말 것: JWT secret, Admin 키, Client Secret")과 정면 충돌하는 배포 구조임. 실제 `.env` 파일은 현재 커밋되어 있지 않고 `.gitignore` 에 등록되어 있으나, CI 빌드 환경에서 `.env` 가 생성되어 들어가면 그 내용이 배포 산출물에 포함된다.
- 권장: `pubspec.yaml` 의 assets 항목에서 `.env` 를 제거하고, 환경변수를 런타임에 주입하는 방식(예: `--dart-define-from-file`, `flutter_dotenv` 의 `String.fromEnvironment`) 으로 전환하거나, 노출 허용 값만 `.env` 에 남기고 시크릿은 절대 포함시키지 않는 정책을 CI/CD 단계에서 강제할 것
- 근거:
  ```yaml
  # fe/doitdo/pubspec.yaml (line 110~116)
  flutter:
    uses-material-design: true
    assets:
      - assets/images/
      - assets/icons/
      ...
      - .env      # ← APK/AAB 내부에 평문으로 번들됨
  ```

---

### [HIGH-2] OAuth 토큰을 평문 SharedPreferences 에 저장 — pubspec 정책과 자기모순

- 파일: `fe/doitdo/android/app/src/main/kotlin/com/d107/doitdo/widget/WidgetSharedStore.kt:56-61`
- 문제: `WidgetSharedStore` 가 `access_token` / `refresh_token` 을 일반 `SharedPreferences` 에 `apply()` 로 평문 저장함. `pubspec.yaml` 주석("OAuth access/refresh 토큰은 반드시 flutter_secure_storage 로 보관. SharedPreferences 금지.")과 직접 모순
- 영향: Android 4.3 이하 루팅 기기 또는 앱 데이터 읽기 권한이 있는 동일 기기 내 다른 앱에 의해 토큰 탈취 가능. `HomeWidgetPreferences` 는 `MODE_PRIVATE` 이나 루팅된 기기에서는 충분하지 않음. 위젯이 사용하는 토큰이 만료되면 refresh 토큰으로 새 access 토큰을 자동 발급(WidgetApiClient.refreshAccessToken)하므로, refresh 토큰 탈취 시 세션 완전 장악 가능
- 권장: `home_widget` 패키지의 구조상 위젯-앱 간 공유 스토리지는 `SharedPreferences` 기반으로 제한되므로 완전한 교체가 어렵다면, access 토큰만 위젯 SharedPreferences 에 저장(만료 시 앱 실행 강제)하고 refresh 토큰은 앱 측 `flutter_secure_storage` 에만 두는 설계로 분리하거나, 위젯 전용 단기 토큰(scope 제한)을 발급하는 방향을 검토할 것. 최소한 `KEY_REFRESH_TOKEN` 키를 위젯 SharedPreferences 에 쓰지 않도록 권장
- 근거:
  ```kotlin
  // fe/doitdo/android/app/src/main/kotlin/com/d107/doitdo/widget/WidgetSharedStore.kt
  fun updateAccessToken(context: Context, token: String) {
      prefs(context).edit().putString(KEY_ACCESS_TOKEN, token).apply()  // 평문 저장
  }
  fun updateRefreshToken(context: Context, token: String) {
      prefs(context).edit().putString(KEY_REFRESH_TOKEN, token).apply() // refresh 토큰까지 평문
  }
  // pubspec.yaml 주석 (line ~78):
  // "OAuth 로 발급된 access/refresh 토큰은 반드시 이걸로 보관. SharedPreferences 금지."
  ```

> **🔄 재검증 (2026-04-28) — 성립 유지 (변화 없음)**
>
> - `WidgetSharedStore.kt:24` `KEY_REFRESH_TOKEN` 상수 그대로, `:32~33` 일반 `SharedPreferences MODE_PRIVATE`, `:56~62` access/refresh 평문 저장 그대로
> - `WidgetApiClient.kt:114~138` `refreshAccessToken()` 가 위젯에서 자급자족 refresh 순환 (refresh 응답을 다시 SP 에 덮어씀)
> - `androidx.security:security-crypto` 의존성 0
> - `pubspec.yaml:75~77` "SharedPreferences 금지" 정책 주석 그대로 — **정책-구현 모순 지속**
> - 최근 widget 디렉토리 커밋 (`6d57800` / `25ea67d` / `491795e` / `53dea96`) 모두 기능 / 레이아웃, 보안 미수정
>
> **권장 (현실적)**: `KEY_REFRESH_TOKEN` 위젯 SP 에서 제거 → 만료 시 위젯이 PendingIntent 로 앱 깨우고 앱이 secure_storage 에서 refresh → 위젯엔 access only 위임
>
> **권장 (장기)**: `EncryptedSharedPreferences` 전환 (`androidx.security:security-crypto:1.1.0+`)
>
> **우선순위**: **P1**

---

### [HIGH-3] Kakao Native App Key 미설정 시 빈 scheme 등록 — OAuth 코드 인터셉트 가능

- 파일: `fe/doitdo/android/app/build.gradle.kts:22-24` / `fe/doitdo/android/app/src/main/AndroidManifest.xml:87`
- 문제: `local.properties` 에 `KAKAO_NATIVE_APP_KEY` 가 없으면 `kakaoNativeAppKey = ""` 로 폴백하여 manifest 의 Kakao redirect scheme 이 `kakao://oauth` (빈 문자열 삽입) 로 등록됨
- 영향: 같은 기기에 설치된 악의적인 앱이 동일한 `kakao://oauth` scheme 을 등록하면 OS 가 어느 앱이 인텐트를 수신할지 사용자에게 선택하게 하거나 선택 없이 악의적 앱으로 라우팅할 수 있음. Kakao OAuth 인증 코드 인터셉트로 이어짐. 빌드 타임 누락이 런타임 보안 취약점으로 전파되는 구조
- 권장: `kakaoNativeAppKey` 가 빈 문자열이면 빌드를 즉시 실패(`error("KAKAO_NATIVE_APP_KEY must be set in local.properties")`)시켜 잘못된 manifest 가 배포되지 않도록 강제할 것
- 근거:
  ```kotlin
  // fe/doitdo/android/app/build.gradle.kts:22-24
  val kakaoNativeAppKey: String =
      localProperties.getProperty("KAKAO_NATIVE_APP_KEY") ?: ""
      // ↑ 키 없으면 빈 문자열 폴백 — 빌드 에러 없이 통과
  ```
  ```xml
  <!-- fe/doitdo/android/app/src/main/AndroidManifest.xml:87 -->
  <data android:scheme="kakao${kakaoNativeAppKey}" android:host="oauth" />
  <!-- KAKAO_NATIVE_APP_KEY="" → scheme="kakao" 로 등록됨 -->
  ```

---

## MEDIUM

### [MEDIUM-1] goAsync() 처리 한도 초과 위험 — OkHttp 타임아웃 합산이 10s 초과

- 파일: `fe/doitdo/android/app/src/main/kotlin/com/d107/doitdo/widget/ToggleTodoReceiver.kt:36-44` / `fe/doitdo/android/app/src/main/kotlin/com/d107/doitdo/widget/WidgetApiClient.kt:40-42`
- 문제: `goAsync()` 가 receiver 에게 부여하는 처리 한도는 약 10초. 그런데 `OkHttpClient` 의 `connectTimeout(10s) + readTimeout(10s)` 가 각각 최대치로 설정되어 있어 PATCH 요청 하나만으로도 최대 20초 이상 소요 가능. refresh 재시도 경로에서는 PATCH 2회 + refresh POST 1회 = 최대 30초 이상
- 영향: 네트워크 지연 상황에서 `pending.finish()` 가 10s 내에 호출되지 않으면 OS 가 receiver 를 강제 종료하거나 ANR 를 발생시킴
- 권장: OkHttp 타임아웃을 각 5초 이하로 줄이거나, 위젯 전용 타임아웃 설정을 분리할 것. 또는 goAsync 대신 `WorkManager` 로 네트워크 작업을 위임하는 방향 검토
- 근거:
  ```kotlin
  // WidgetApiClient.kt:40-42
  .connectTimeout(10, TimeUnit.SECONDS)
  .readTimeout(10, TimeUnit.SECONDS)
  .writeTimeout(10, TimeUnit.SECONDS)
  // ToggleTodoReceiver.kt:36
  val pending = goAsync()  // ~10s hard limit
  // refresh 경로: patchStatus → 401 → refreshAccessToken → patchStatus = 최대 3 * 10s
  ```

---

### [MEDIUM-2] PendingIntent 가 pre-API 31 에서 mutable — 보안 권장사항 미준수

- 파일: `fe/doitdo/android/app/src/main/kotlin/com/d107/doitdo/widget/DoitdoWidgetProvider.kt:223-229`
- 문제: `pendingIntentFlags()` 에서 `API 31+` 에만 `FLAG_IMMUTABLE` 을 적용하고, 미만 버전에서는 `FLAG_UPDATE_CURRENT` 만 사용. `FLAG_IMMUTABLE` 은 API 23 (Android 6.0) 부터 사용 가능하므로 pre-S 분기 범위를 좁힐 수 있음
- 영향: API 23~30 기기(Android 6~11)에서 mutable PendingIntent 는 외부 앱이 intent 를 수정해 다른 action 을 주입하는 공격 벡터가 됨. Google Play 보안 정책에서도 mutable PendingIntent 는 API 23+ 에서 사용 지양을 권고
- 권장: `Build.VERSION_CODES.M` (API 23) 이상이면 `FLAG_IMMUTABLE` 을 적용하도록 분기 수정 권장
- 근거:
  ```kotlin
  // DoitdoWidgetProvider.kt:222-229
  private fun pendingIntentFlags(): Int {
      return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {  // API 31+만 IMMUTABLE
          PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
      } else {
          PendingIntent.FLAG_UPDATE_CURRENT  // API 23~30: mutable 상태
      }
  }
  ```

---

### [MEDIUM-3] `google-services.json` 커밋 및 `oauth_client` 미등록

- 파일: `fe/doitdo/android/app/google-services.json`
- 문제 1: Firebase Android API 키(`AIzaSyBT...`)가 레포에 평문 커밋되어 있음. 키 자체는 Android 패키지명 + SHA-1 제한으로 악용이 제한적이나, 일반적으로 `google-services.json` 은 환경별로 분리(dev/prod)하거나 gitignore 후 CI에서 주입하는 것이 best practice
- 문제 2: `oauth_client` 가 빈 배열(`[]`)임. `google_sign_in` 패키지는 Google Sign-In 동작을 위해 `web_client_id` 가 google-services.json 의 `oauth_client` 에 등록되어 있어야 함. 현 상태에서는 Android 에서 Google 소셜 로그인이 동작하지 않을 가능성이 있음 (확인 필요)
- 영향: 문제 2의 경우 production 배포 후 Android Google 로그인 불능으로 이어질 수 있음
- 권장: `oauth_client` 에 Google Cloud Console 의 Android 용 OAuth 클라이언트 ID 를 추가할 것. `google-services.json` 은 환경별 버전으로 분리(dev-google-services.json / prod-google-services.json)하고 `.gitignore` 에 추가 후 CI/CD 에서 주입하는 방식 권장
- 근거:
  ```json
  // fe/doitdo/android/app/google-services.json
  "oauth_client": [],        // Google Sign-In 에 필요한 web client ID 미등록
  "api_key": [
    { "current_key": "AIzaSyBTvdSYkOKiIDQFTQRptRI6r8rEDSCf6T8" }  // 평문 커밋
  ]
  ```

---

### [MEDIUM-4] `WidgetSharedStore` 다중 쓰기 동시성 — rapid tap 시 fading 상태 race

- 파일: `fe/doitdo/android/app/src/main/kotlin/com/d107/doitdo/widget/WidgetSharedStore.kt:43-74`
- 문제: `savePayload` + `markFadingTodo` 가 별도 `edit().apply()` 호출로 분리되어 있음. `apply()` 는 비동기로 메인 스레드에 flush 되므로 빠른 멀티탭 시 `savePayload`(낙관적 갱신)와 `markFadingTodo` 사이에 다른 receiver 인스턴스가 같은 파일을 읽을 수 있음
- 영향: 동시 체크 탭 시 payload 와 fadingTodoId 가 일치하지 않아 잘못된 todo 에 취소선 표시되거나 이미 완료된 항목이 재표시될 수 있음
- 권장: `savePayload` + `markFadingTodo` 를 단일 `edit()` 블록으로 묶어 atomic 하게 처리하거나, 위젯 갱신 트리거 전에 배치 쓰기를 완료하는 패턴 검토
- 근거:
  ```kotlin
  // WidgetSharedStore.kt — 별도 edit().apply() 두 번 호출
  WidgetSharedStore.savePayload(context, updated)   // 비동기 flush
  // ... (갭 발생 가능)
  WidgetSharedStore.markFadingTodo(context, todoId) // 비동기 flush
  reloadAllWidgets(context)  // 위 두 쓰기가 완료 전에 render 가 시작될 수 있음
  ```

---

## LOW

### [LOW-1] `web/index.html` CSP(Content-Security-Policy) 메타 태그 부재

- 파일: `fe/doitdo/web/index.html`
- 문제: `<head>` 에 `<meta http-equiv="Content-Security-Policy">` 가 없음. 인라인 스크립트(`<script>` 태그로 path rewriting 수행)가 포함되어 있어 외부 공격자가 스크립트 주입 성공 시 실행 범위가 넓어짐
- 권장: PWA 가 Flutter web 을 wrapping 하므로 정밀한 CSP 설계가 쉽지 않으나, `default-src 'self'` + nonce 기반 인라인 스크립트 허용을 서버 응답 헤더 수준에서 설정하는 방향 검토

---

### [LOW-2] `web/manifest.json` 에 Flutter 기본값 잔존

- 파일: `fe/doitdo/web/manifest.json`
- 문제:
  - `"description": "A new Flutter project."` — doitdo 브랜딩 미적용
  - `"theme_color": "#0175C2"`, `"background_color": "#0175C2"` — Flutter CLI 기본 파랑. 앱 실제 테마 색상과 불일치할 가능성
  - `"start_url": "."` — 상대 경로로 배포 서브패스 환경에서 동작 실패 가능 (확인 필요)
- 권장: description, theme_color, background_color 를 실제 앱 브랜딩에 맞게 수정

---

### [LOW-3] `analysis_options.yaml` — 에러/경고 강화 규칙 부재

- 파일: `fe/doitdo/analysis_options.yaml`
- 문제: `prefer_single_quotes`, `always_use_package_imports` 두 lint 만 추가. `errors` / `warnings` 섹션이 없어 `avoid_print`, `avoid_dynamic_calls`, `unawaited_futures` 등 실질적 버그 방지 규칙이 적용되지 않음
- 권장: 최소 `avoid_print: error`, `unawaited_futures: warning` 추가 검토

---

### [LOW-4] 위젯 `updatePeriodMillis="0"` — 앱 미실행 시 위젯 stale 처리 없음

- 파일: `fe/doitdo/android/app/src/main/res/xml/doitdo_widget_info.xml:18`
- 문제: `updatePeriodMillis="0"` 으로 OS 자동 갱신을 비활성화했으나, 앱이 장기간 미실행 상태이면 위젯 데이터가 오래된 채로 남음. 실기기에서 며칠 후 "어제 할 일"이 위젯에 표시되는 사용자 경험 저하 가능
- 권장: 앱이 장기간 미실행될 경우를 대비해 `WorkManager` 또는 제한적인 `updatePeriodMillis` (최소 1800000ms = 30분) 도입을 검토하거나, 위젯에 마지막 갱신 시각을 표시하는 방향 고려

---

## 검토한 주요 파일

| 파일 | 분류 | 상태 |
|---|---|---|
| `fe/doitdo/android/app/src/main/AndroidManifest.xml` | Manifest | MEDIUM/HIGH 이슈 포함 |
| `fe/doitdo/android/app/build.gradle.kts` | Build | HIGH-3 (Kakao 빈 폴백) |
| `fe/doitdo/android/app/google-services.json` | Firebase | MEDIUM-3 |
| `fe/doitdo/android/app/src/main/kotlin/com/d107/doitdo/widget/DoitdoWidgetProvider.kt` | 위젯 | MEDIUM-2 (PendingIntent) |
| `fe/doitdo/android/app/src/main/kotlin/com/d107/doitdo/widget/ToggleTodoReceiver.kt` | 위젯 | MEDIUM-1 (goAsync) |
| `fe/doitdo/android/app/src/main/kotlin/com/d107/doitdo/widget/WidgetApiClient.kt` | 위젯 | MEDIUM-1 |
| `fe/doitdo/android/app/src/main/kotlin/com/d107/doitdo/widget/WidgetSharedStore.kt` | 위젯 | HIGH-2, MEDIUM-4 |
| `fe/doitdo/android/app/src/main/kotlin/com/d107/doitdo/widget/WidgetTodo.kt` | 위젯 | 이상 없음 |
| `fe/doitdo/android/app/src/main/res/xml/doitdo_widget_info.xml` | 위젯 메타 | LOW-4 |
| `fe/doitdo/android/app/src/main/res/layout/doitdo_widget.xml` | 레이아웃 | 이상 없음 |
| `fe/doitdo/android/key.properties.example` | 빌드 키 | 정상 (실제 키 미포함) |
| `fe/doitdo/android/.gitignore` | gitignore | key.properties, *.jks 정상 제외 |
| `fe/doitdo/pubspec.yaml` | 의존성 | HIGH-1 (.env asset) |
| `fe/doitdo/.gitignore` | gitignore | .env 제외 정상 — 그러나 asset 등록은 별개 문제 |
| `fe/doitdo/analysis_options.yaml` | Lint | LOW-3 |
| `fe/doitdo/web/index.html` | PWA | LOW-1 (CSP) |
| `fe/doitdo/web/manifest.json` | PWA | LOW-2 (기본값) |
| `.gitignore` (루트) | gitignore | Jira/.env, .codex 제외 — fe/doitdo 에 대한 별도 제외 없음 (fe 자체 .gitignore 가 담당) |
