# Kakao 로그인 — 설정 가이드

Kakao OAuth 를 실제로 동작시키려면 네이티브 레이어 설정이 필요하다.
코드 변경은 이미 반영되어 있으므로 이 문서의 단계만 따라가면 됨.

---

## 1. Kakao Developers 앱 생성

1. <https://developers.kakao.com> 접속 → 로그인
2. **내 애플리케이션** → **애플리케이션 추가하기**
3. 앱 이름: `doitdo` / 회사명: 팀 이름
4. 저장 후 **앱 키** 탭으로 이동

여기서 확인 가능한 키:

| 키 | 어디에 쓰나 |
|---|---|
| 네이티브 앱 키 | **Android/iOS 모두** — 우리가 사용할 값 |
| REST API 키 | 백엔드가 카카오 userinfo API 호출할 때 사용 |
| JavaScript 키 | 웹에서만 필요 (현재 미사용) |
| Admin 키 | 서버 관리용 (절대 클라이언트 포함 금지) |

---

## 2. 플랫폼 등록 (Kakao Developers)

**플랫폼** 탭 → **Android 플랫폼 등록**

| 항목 | 값 |
|---|---|
| 패키지명 | `com.d107.doitdo` |
| 마켓 URL | `market://details?id=com.d107.doitdo` (출시 전엔 빈 값) |
| 키 해시 | 아래 방법으로 생성 |

### 키 해시 생성

디버그용은 Android Studio 의 Gradle 탭 → **signingReport** 실행하면 나오는 SHA-1 을
base64 로 변환한 값. 또는 아래 Kotlin 스니펫을 MainActivity 에 잠깐 넣어 로그로 뽑을 수 있다.

터미널 한 줄로 뽑는 법 (Windows PowerShell):

```powershell
keytool -exportcert -alias androiddebugkey -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -keypass android | openssl sha1 -binary | openssl base64
```

출력된 문자열(28자리)을 Kakao 콘솔의 "키 해시" 에 등록.

---

## 3. 카카오 로그인 활성화

**제품 설정 > 카카오 로그인** 탭에서:

1. **활성화 설정 ON**
2. **Redirect URI**: Android 에서는 등록 불필요 (SDK 가 자동으로 `kakao{KEY}://oauth` 처리)
3. **동의 항목** → 프로필 정보(닉네임/프로필 사진), 카카오계정(이메일) **필수** 로 체크

---

## 4. 프론트 프로젝트 설정

### 4.1 `.env`

프로젝트 루트의 `.env` 에 네이티브 앱 키 입력:

```
KAKAO_NATIVE_APP_KEY=여기에네이티브앱키
```

이 값은 `main.dart` 에서 `KakaoSdk.init()` 에 주입된다.

### 4.2 `android/local.properties`

Android 빌드타임에 `AndroidManifest.xml` 의 redirect scheme 으로 주입되는 값이다.
**`.env` 와 동일한 네이티브 앱 키를 한 번 더 넣어야 한다.**

```
KAKAO_NATIVE_APP_KEY=여기에네이티브앱키
```

`local.properties` 는 `.gitignore` 에 이미 등록돼 있어 커밋되지 않는다.
팀원 간 공유는 1Password / DM 으로.

> **왜 두 군데에 넣나?**
> `.env` 는 런타임(Dart) 용, `local.properties` 는 빌드타임(Gradle) 용.
> Gradle 은 `.env` 를 직접 읽을 수 없어서 불가피하게 분리된다.
> 키 자체는 동일한 값.

### 4.3 빌드 확인

```bash
cd fe/doitdo
flutter clean
flutter pub get
flutter run
```

---

## 5. iOS 설정 (Mac 빌드 시)

> 현재 팀 빌드 환경이 Windows 라 iOS 는 추후 진행. Mac 환경 확보 후 아래 절차 수행.

### 5.1 Kakao Developers 플랫폼 등록

- iOS 플랫폼 추가 → Bundle ID: `com.d107.doitdo`

### 5.2 `ios/Runner/Info.plist`

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>kakaokompassauth</string>
  <string>kakaolink</string>
  <string>kakaoplus</string>
</array>
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>kakao${KAKAO_NATIVE_APP_KEY}</string>
    </array>
  </dict>
</array>
```

`${KAKAO_NATIVE_APP_KEY}` 부분은 실제 키 값으로 대체해서 커밋.
(iOS 는 Android 처럼 manifestPlaceholders 같은 게 없어서 평문 등록이 관행.)

### 5.3 AppDelegate

Flutter SDK 는 내부적으로 URL Scheme callback 을 처리하므로 별도 `application(_:open:options:)`
오버라이드는 필요 없다.

---

## 6. 백엔드 요구사항

서버도 Kakao Developers 콘솔의 **REST API 키** 로 카카오 userinfo API (`https://kapi.kakao.com/v2/user/me`) 를
호출해서 토큰을 검증한다. 백엔드 팀에 전달할 것:

- 팀의 Kakao 앱 REST API 키
- 엔드포인트 스펙: `POST /auth/social/KAKAO`, body: `{"accessToken": "..."}`
- `docs/BACKEND_AUTH_SPEC.md` 참조

---

## 7. 트러블슈팅

| 증상 | 원인 / 해결 |
|---|---|
| `KakaoAuthException: KOE009` | 키 해시가 Kakao 콘솔에 등록되지 않음 — 위 2.1 재확인 |
| `App Switching Error` (iOS) | `Info.plist` 의 `LSApplicationQueriesSchemes` 누락 |
| `WebView 에서 바로 닫힘` | redirect scheme(`kakao{KEY}://oauth`) 등록 누락 — `AndroidManifest.xml` 확인 |
| `KakaoSdk 가 초기화되지 않았습니다` | `.env` 에 `KAKAO_NATIVE_APP_KEY` 빠짐 또는 빈 값 — 4.1 확인 |
| Android 빌드 에러 `kakaoNativeAppKey not set` | `local.properties` 에 키 누락 — 4.2 확인 |

---

## 8. 프론트 코드 매핑

| 동작 | 구현 위치 |
|---|---|
| SDK 초기화 | `lib/main.dart` (`KakaoSdk.init`) |
| 로그인 시트 호출 / 폴백 | `AuthRepositoryImpl.signInWithKakao` |
| 서버 API 호출 | `AuthRemoteDataSource.loginWithKakao` |
| 버튼 UI | `WelcomePage._handleKakaoSignIn` |
| 상태 관리 | `WelcomeViewModel.signInWithKakao` |
| 로그아웃 | `AuthRepositoryImpl.signOut` (Google/Kakao 모두 호출) |
