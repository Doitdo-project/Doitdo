# Apple Sign In 셋업 가이드

Windows 개발 환경에서 **Flutter 코드는 이미 다 준비**돼 있어요.
나중에 Mac 에서 iOS 빌드할 때 아래 수동 작업만 하면 됩니다.

이 문서는 "Mac 에 처음 앉았을 때" 팀원(또는 본인)이 복붙 수준으로 따라할 수 있도록 작성했습니다.

---

## 0. 사전 준비

- [ ] macOS (Sonoma 이상 권장)
- [ ] Xcode 15 이상 설치
- [ ] Apple Developer Program 가입 (연 $99, 한국 약 14만원)
- [ ] `fe/doitdo` 프로젝트 git clone 완료
- [ ] `flutter pub get` 실행 완료 (`sign_in_with_apple` 포함)

---

## 1. Apple Developer Portal 설정

브라우저에서 https://developer.apple.com 로그인 후:

### 1-1. App ID에 Sign In with Apple 활성화
1. **Certificates, Identifiers & Profiles** → **Identifiers**
2. 기존 App ID (`com.d107.doitdo`) 선택 — 없으면 새로 생성
3. Capabilities 목록에서 **Sign In with Apple** 체크
4. **Save** 클릭

### 1-2. Provisioning Profile 재생성
Capability 바꾸면 기존 profile 은 무효가 돼요.
1. **Profiles** 섹션 → 기존 프로파일 Edit
2. 아무것도 안 바꾸고 그대로 **Save** (서버가 자동으로 capability 반영)
3. 아니면 Xcode 에서 **Automatically manage signing** 체크돼 있으면 자동으로 해결됨

---

## 2. Xcode 설정

### 2-1. Capability 추가
1. 터미널에서:
   ```bash
   cd fe/doitdo/ios
   open Runner.xcworkspace
   ```
2. 왼쪽 트리에서 `Runner` 프로젝트 클릭
3. `TARGETS` 하위의 `Runner` 선택
4. 상단 탭 **Signing & Capabilities**
5. 좌상단 **+ Capability** 버튼 클릭
6. 검색창에 **"Sign in with Apple"** 입력 → 더블클릭
7. 화면에 `Sign in with Apple` 섹션이 새로 생기면 완료

이 작업을 하면 `ios/Runner/Runner.entitlements` 파일이 자동으로 생성/수정돼요.
다음 내용이 들어가야 정상:

```xml
<key>com.apple.developer.applesignin</key>
<array>
  <string>Default</string>
</array>
```

### 2-2. 서명 확인
1. 같은 **Signing & Capabilities** 탭
2. **Automatically manage signing** 체크 유지
3. Team 드롭다운에서 본인/팀 Apple Developer 계정 선택
4. "Provisioning Profile" 에 에러 없이 초록색 체크 표시면 OK

---

## 3. 빌드 테스트

### 3-1. 시뮬레이터에서
```bash
cd fe/doitdo
flutter run -d ios
```
- 시뮬레이터가 자동으로 뜸
- "Apple로 로그인" 버튼 탭해서 iOS 로그인 시트가 뜨는지 확인
- 시뮬레이터에서도 테스트 Apple ID 로 로그인 가능 (Settings → iCloud → Sign In)

### 3-2. 실기기에서
1. iPhone USB 연결
2. Xcode 좌상단 디바이스 선택 드롭다운에서 내 iPhone 선택
3. `flutter run -d <device_id>` 또는 Xcode 의 Run 버튼

---

## 4. 백엔드 연동 시 할 일

코드에 `TODO: credential.identityToken...` 주석이 있어요.
실제 서버 연동 시:

1. `credential.identityToken` (JWT) 을 서버 POST 엔드포인트로 전송
2. 서버에서 Apple 공개키로 JWT 서명 검증:
   - Apple 공개키 엔드포인트: `https://appleid.apple.com/auth/keys`
   - JWT header 의 `kid` 로 매칭되는 공개키 찾기
   - JWT `aud` 가 앱 Bundle ID 와 일치하는지 확인
   - JWT `iss` 가 `https://appleid.apple.com` 인지 확인
3. 검증 성공 시 서버에서 자체 세션 발급
4. 최초 로그인에서 받은 `email`, `fullName` 을 DB 에 저장 (이후에는 Apple 이 안 줌)

### 주의사항
- `email` 이 `user@privaterelay.appleid.com` 형태면 **Apple이 가려준 릴레이 이메일**
- 사용자가 "이메일 공유 안 함" 선택했을 때 이렇게 옴
- 이 경우 Apple 릴레이 서버에 이메일 발송 가능 (본인 메일로 전달됨)
- Apple Developer Portal 에서 Sender 도메인 등록 필요

---

## 5. 앱 스토어 제출 전 체크리스트

- [ ] iOS 시뮬레이터에서 Apple 로그인 전체 플로우 성공 확인
- [ ] 실기기에서도 확인
- [ ] App Store Connect 의 "앱 정보" → "로그인 요구 사항" 에 Apple Sign In 지원 명시
- [ ] Privacy Policy 에 Apple Sign In 으로 수집하는 데이터(이름, 이메일) 명시
- [ ] 최초 로그인 후 이름/이메일을 DB 저장하는지 서버 로직 재점검

---

## 참고

- 패키지: https://pub.dev/packages/sign_in_with_apple
- Apple Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple
- App Store 심사 규정 4.8: https://developer.apple.com/app-store/review/guidelines/#sign-in-with-apple
