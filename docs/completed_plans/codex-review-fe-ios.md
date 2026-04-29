# Codex Review — FE iOS Native

## 컨텍스트
- 프로젝트: doitdo iOS native (Flutter wrapper + WidgetKit + FCM + Apple Sign-in)
- 현재 브랜치: be/feat/user-birthdate-age-check
- 이 작업: **`fe/doitdo/ios/**` 의 누적 변경에 대한 risk surface 발굴**

## 스코프
- 검토 대상: `fe/doitdo/ios/**` 의 main 대비 모든 변경 파일 중 **코드/설정** (Swift, plist, entitlements, pbxproj, Podfile, xcconfig, storyboard)
- 진단 명령:
  - `git diff main...HEAD --stat -- 'fe/doitdo/ios/'`
  - `git diff main...HEAD -- 'fe/doitdo/ios/<path>'`
- **제외**: 이미지 자산 (`.png`, `.imageset/*.png`, `Assets.xcassets/...AppIcon...`)

## 임무
다음 6축 위험을 발굴하라.

1. **위젯/SharedStore**: App Group entitlement 누락, UserDefaults suite 이름 mismatch, WidgetKit timeline policy 부적절, ToggleTodoIntent race, 위젯 → 앱 sync 시 중복 호출, dark/light asset 누락
2. **APNs/FCM**: AppDelegate 토큰 등록 race (최근 fix 한 영역), notification permission 흐름, swizzling 충돌, foreground notification 옵션 누락, fcm 토큰 갱신 race
3. **Apple Sign-in**: nonce 검증, identity token 처리, ASAuthorizationController delegate 누수, error 매핑, refresh 흐름
4. **Info.plist / entitlements**: 권한 키 누락(NSCameraUsageDescription 등), URL Scheme 충돌, App Transport Security 완화, background mode 과잉
5. **Podfile / 의존성**: 버전 충돌, deployment target mismatch, post_install 훅 부적절, Firebase / GoogleSignIn 등 의존성의 known issue
6. **빌드 설정 (pbxproj/xcconfig)**: Debug/Release 분기 일관성, code signing entitlements 잘못 매핑, BUNDLE_DISPLAY_NAME 등 환경 분리

## 출력
- 결과를 **`docs/reviews/04-fe-ios-review.md`** 한 파일에만 작성
- 형식: 01 리뷰와 동일 (HIGH/MEDIUM/LOW + 파일:줄 + 권장 + 근거 hunk 발췌)

## 제약
- **read-only 사고방식**: 결과 외 어떤 파일도 수정 금지. 결과는 오직 `docs/reviews/04-fe-ios-review.md` 한 곳에만
- **스코프 엄수**: BE, FE lib, Android native 검토 금지
- **빌드 실행 금지**: 정적 분석만 (xcodebuild, pod install 등 실행 금지)
- **단정 금지**: 불확실하면 "확인 필요"
- **CDP MCP(Chrome DevTools Protocol MCP) 절대 사용 금지**
