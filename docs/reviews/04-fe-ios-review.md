# 04 FE iOS Native Review

- 대상: `git diff main...HEAD -- fe/doitdo/ios/`
- 방식: 정적 분석만 수행. `xcodebuild`, `pod install` 등 빌드/설치 명령 미실행.
- 제외: `.png`, AppIcon 이미지 자산.
- 참고: `docs/reviews` 안에서 01 리뷰 파일을 찾지 못해, 요청된 요소인 `HIGH/MEDIUM/LOW + 파일:줄 + 권장 + 근거 hunk 발췌` 형식으로 작성.

## Findings

### HIGH-01. 위젯 토글이 서버 반영 실패/순서 역전에도 성공 UI로 확정될 수 있음

- 위치: `fe/doitdo/ios/DoitdoWidget/ToggleTodoIntent.swift:77`, `fe/doitdo/ios/DoitdoWidget/ToggleTodoIntent.swift:92`
- 축: 위젯/SharedStore, ToggleTodoIntent race, 위젯 -> 앱/서버 sync
- 권장: `Task.detached` fire-and-forget 대신 extension 시간 예산 안에서 `await` 가능한 bounded network path를 두거나, 최소한 pending operation을 SharedStore에 남겨 앱 재진입/다음 sync에서 재시도/롤백하도록 처리. 같은 `todoId`에 대한 연속 탭은 per-id 직렬화 또는 idempotency key로 순서 역전을 막는 것이 안전함.
- 근거: SharedStore는 먼저 낙관적으로 저장되고 timeline reload가 발생한 뒤, PATCH는 detached task에서 실패를 삼킨다. App Extension은 `perform()` 반환 뒤 네트워크 task 완료가 보장된다고 단정하기 어렵고, 빠른 연속 탭 시 detached PATCH들이 서버에 도착하는 순서도 보장되지 않는다.

```diff
+        SharedStore.savePayload(
+            WidgetPayload(
+                todayTodos: updatedToday,
+                somedayTodos: updatedSomeday,
+                updatedAt: nowISO
+            )
+        )
+
+        WidgetCenter.shared.reloadTimelines(ofKind: "DoitdoWidget")
+
+        let capturedTodoId = todoId
+        Task.detached(priority: .userInitiated) {
+            do {
+                try await WidgetApiClient.changeTodoStatus(todoId: capturedTodoId, newStatus: nextStatus)
+            } catch {
+                // no-op — 위젯 extension 은 사용자에게 알릴 수단이 없다.
+            }
+        }
```

### HIGH-02. refresh token이 App Group UserDefaults에 저장되고 위젯이 직접 갱신함

- 위치: `fe/doitdo/ios/DoitdoWidget/SharedStore.swift:18`, `fe/doitdo/ios/DoitdoWidget/WidgetApiClient.swift:71`
- 축: 위젯/SharedStore, 의존성/인증 refresh race
- 권장: refresh token은 가능하면 App Group Keychain access group으로 옮기고, 위젯에는 payload와 짧은 수명의 access token만 공유하는 방향을 검토. 위젯 refresh가 필요하면 앱 프로세스의 refresh와 충돌하지 않도록 compare-and-swap, cross-process lock, 또는 서버 idempotent refresh 정책을 확인 필요.
- 근거: App Group UserDefaults는 앱/extension 공유에는 적합하지만 장기 refresh token 저장소로는 위험 표면이 크다. 또한 앱과 위젯이 동시에 401을 만나 refresh token rotation을 수행하면 마지막 저장자가 access/refresh pair를 덮어쓸 수 있다.

```diff
+    enum Key {
+        static let payload = "doitdo.widget.payload"
+        static let accessToken = "doitdo.widget.accessToken"
+        static let refreshToken = "doitdo.widget.refreshToken"
+        static let apiBaseUrl = "doitdo.widget.apiBaseUrl"
+    }
...
+    static func accessToken() -> String? { string(forKey: Key.accessToken) }
+    static func refreshToken() -> String? { string(forKey: Key.refreshToken) }
```

```diff
+    private static func refreshAccessToken() async throws -> String {
+        guard let refresh = SharedStore.refreshToken(), !refresh.isEmpty else {
+            throw WidgetApiError.unauthorized
+        }
...
+            SharedStore.updateAccessToken(pair.accessToken)
+            SharedStore.updateRefreshToken(pair.refreshToken)
+            return pair.accessToken
+        } catch {
+            throw WidgetApiError.decode
+        }
+    }
```

### MEDIUM-01. APNs 등록이 `super.application`보다 먼저 실행되어 FCM swizzling/plugin 초기화와 race 가능

- 위치: `fe/doitdo/ios/Runner/AppDelegate.swift:15`, `fe/doitdo/ios/Runner/AppDelegate.swift:22`
- 축: APNs/FCM, AppDelegate 토큰 등록 race, swizzling 충돌
- 권장: `super.application(...didFinishLaunching...)` 이후에 `UNUserNotificationCenter.current().delegate`와 `registerForRemoteNotifications()`를 수행하는 순서를 검토. swizzling에 의존하지 않으려면 `didRegisterForRemoteNotificationsWithDeviceToken`에서 APNs token을 Firebase Messaging에 명시 전달하는 경로도 확인 필요.
- 근거: 현재 코드는 foreground delegate 안전망과 APNs 등록을 모두 `super`보다 먼저 실행한다. 의도는 첫 설치/첫 로그인 race 완화지만, plugin/swizzling 초기화가 늦으면 APNs callback이 Firebase 쪽에 연결되지 않는 반대 race가 생길 수 있다.

```diff
+    if #available(iOS 10.0, *) {
+      UNUserNotificationCenter.current().delegate = self
+    }
+
+    // APNs 등록을 명시적으로 트리거.
+    // Firebase swizzling 이 자동으로 처리하지만, 첫 설치/첫 로그인 직후
+    // APNs 토큰 도착이 늦어지는 케이스를 줄이기 위해 launch 시점에 한 번 더 호출.
+    application.registerForRemoteNotifications()
+
+    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
```

### MEDIUM-02. Widget extension 최소 OS가 17.6으로 고정되어 앱 지원 범위와 불일치

- 위치: `fe/doitdo/ios/Runner.xcodeproj/project.pbxproj:569`, `fe/doitdo/ios/Podfile:3`
- 축: 빌드 설정, 위젯/SharedStore
- 권장: 제품 요구 OS를 확인한 뒤 Widget extension의 `IPHONEOS_DEPLOYMENT_TARGET`을 의도한 최소 버전으로 낮출지 검토. iOS 17 인터랙티브 위젯만 목표여도 보통 `17.0` 기준이면 충분한지 확인 필요. App target/Podfile의 `15.0`과 widget target의 `17.6` 차이는 릴리즈 노트나 QA matrix에 명시해야 함.
- 근거: 앱/Podfile은 iOS 15.0인데 widget extension은 Debug/Release/Profile 모두 17.6이다. 코드 주석과 `#available(iOS 17.0, *)` fallback은 17.6 미만 사용자를 고려하는 듯하지만, target 설정상 17.0~17.5 및 iOS 16 사용자는 extension 자체를 받을 수 없다.

```diff
+# firebase_messaging 16.x 요구 조건으로 iOS 15.0 최소 타겟.
+# project.pbxproj 의 IPHONEOS_DEPLOYMENT_TARGET 과 반드시 동일하게 유지할 것.
+platform :ios, '15.0'
```

```diff
+				INFOPLIST_FILE = DoitdoWidget/Info.plist;
+				INFOPLIST_KEY_CFBundleDisplayName = DoitdoWidget;
+				INFOPLIST_KEY_NSHumanReadableCopyright = "";
+				IPHONEOS_DEPLOYMENT_TARGET = 17.6;
```

### MEDIUM-03. Kakao URL scheme 주입 파일이 optional이라 Release가 잘못된 scheme으로도 빌드될 수 있음

- 위치: `fe/doitdo/ios/Flutter/Release.xcconfig:3`, `fe/doitdo/ios/Runner/Info.plist:49`
- 축: Info.plist / URL Scheme, 빌드 설정 환경 분리
- 권장: Release/CI에서는 `KAKAO_NATIVE_APP_KEY` 누락 시 빌드를 실패시키거나, non-secret 값이면 checked-in xcconfig로 분리하는 방식을 검토. 최소한 archive pipeline에서 최종 Info.plist의 `CFBundleURLSchemes` 값을 검증해야 함.
- 근거: `LocalEnv.xcconfig`가 optional include라 누락되어도 빌드가 계속된다. 주석도 “빌드는 되지만 Kakao 로그인 URL scheme이 비어서 동작하지 않는다”고 명시한다. Release archive에서 같은 경로를 사용하므로 운영 앱이 callback을 받지 못할 위험이 있다.

```diff
+#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"
+#include "Generated.xcconfig"
+// 로컬 시크릿(Kakao Native App Key 등) — gitignored. 누락 시 빌드는 되지만 Kakao 로그인 URL scheme 이 비어서 동작하지 않는다.
+#include? "LocalEnv.xcconfig"
```

```diff
+				<string>kakao$(KAKAO_NATIVE_APP_KEY)</string>
```

### MEDIUM-04. `PERMISSION_NOTIFICATIONS` 매크로가 기존 preprocessor 설정이 있으면 추가되지 않음

- 위치: `fe/doitdo/ios/Podfile:47`
- 축: Podfile / 의존성, notification permission 흐름
- 권장: `||=` 대신 기존 `GCC_PREPROCESSOR_DEFINITIONS`를 배열/문자열 모두 처리해 append/uniq 하는 방식으로 바꾸는 것이 안전함. 예: 기존 값이 있으면 보존하고 `PERMISSION_NOTIFICATIONS=1`만 추가.
- 근거: 현재 hook은 값이 nil일 때만 매크로 배열을 설정한다. `flutter_additional_ios_build_settings(target)` 또는 특정 Pod target이 이미 `GCC_PREPROCESSOR_DEFINITIONS`를 설정한 경우, 알림 권한 매크로가 빠질 수 있다.

```diff
+    target.build_configurations.each do |config|
+      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
+        '$(inherited)',
+        'PERMISSION_NOTIFICATIONS=1',
+      ]
+    end
```

### LOW-01. Widget 색상 asset이 비어 있는데 build setting에서 참조됨

- 위치: `fe/doitdo/ios/DoitdoWidget/Assets.xcassets/WidgetBackground.colorset/Contents.json:2`, `fe/doitdo/ios/Runner.xcodeproj/project.pbxproj:551`
- 축: 위젯/SharedStore, dark/light asset 누락
- 권장: `WidgetBackground`와 `AccentColor` colorset에 실제 color value 및 필요 시 dark appearance를 정의하거나, SwiftUI hardcoded color만 쓸 계획이면 asset compiler build setting 참조가 필요한지 확인 필요.
- 근거: Widget target은 `ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME = WidgetBackground`를 설정하지만, colorset에는 `idiom`만 있고 color component가 없다. 실제 배경은 SwiftUI `Color.doitdoBackground`로 칠하고 있어 빌드/런타임 영향은 확인 필요지만, asset 기반 background가 필요한 경로에서는 비어 있는 색상 정의가 위험하다.

```diff
+				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
+				ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME = WidgetBackground;
```

```diff
+  "colors" : [
+    {
+      "idiom" : "universal"
+    }
+  ],
```

### LOW-02. `GeneratedPluginRegistrant.*`가 pbxproj에 참조되지만 gitignore로 제외됨

- 위치: `fe/doitdo/ios/.gitignore:28`, `fe/doitdo/ios/Runner.xcodeproj/project.pbxproj:74`
- 축: 빌드 설정
- 권장: CI/Archive가 항상 Flutter tool을 통해 registrant를 생성하는지 확인 필요. 직접 Xcode archive를 지원해야 한다면 generated registrant 파일 커밋 또는 사전 생성 단계 문서화가 필요함.
- 근거: 현재 worktree에는 `fe/doitdo/ios/Runner/GeneratedPluginRegistrant.m`/`.h`가 없지만 pbxproj는 source로 참조한다. Flutter build pipeline이 생성한다면 문제 없을 수 있으나, 순수 Xcode build 경로에서는 missing file build failure가 날 수 있다.

```diff
+Runner/GeneratedPluginRegistrant.*
```

```diff
+		1498D2321E8E86230040F4C2 /* GeneratedPluginRegistrant.h */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.c.h; path = GeneratedPluginRegistrant.h; sourceTree = "<group>"; };
+		1498D2331E8E89220040F4C2 /* GeneratedPluginRegistrant.m */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.c.objc; path = GeneratedPluginRegistrant.m; sourceTree = "<group>"; };
```

### LOW-03. Profile build가 development APNs entitlement를 사용함

- 위치: `fe/doitdo/ios/Runner.xcodeproj/project.pbxproj:735`, `fe/doitdo/ios/Runner/Runner.entitlements:5`
- 축: APNs/FCM, 빌드 설정 entitlements 매핑
- 권장: Profile 빌드가 Firebase/APNs production 환경 검증에 쓰이는지 확인 필요. TestFlight/App Store archive만 Release를 사용한다면 낮은 위험이지만, Profile 산출물을 배포/QA에 쓰면 APNs environment mismatch가 생길 수 있다.
- 근거: Release만 `Runner-Release.entitlements`를 쓰고, Profile은 `Runner.entitlements`를 써서 `aps-environment=development`가 적용된다.

```diff
+				CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;
+				CURRENT_PROJECT_VERSION = "$(FLUTTER_BUILD_NUMBER)";
+				DEVELOPMENT_TEAM = T4VZYFUG54;
```

```diff
+	<key>aps-environment</key>
+	<string>development</string>
```

## 확인된 비위험 / 추가 확인 필요

- App Group id는 `SharedStore.appGroupId`, Runner Debug/Release entitlements, Widget entitlements 모두 `group.com.d107.doitdo`로 일치함.
- iOS native diff 안에는 `NSAppTransportSecurity` 완화와 `UIBackgroundModes` 과잉 선언이 보이지 않음.
- `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`은 존재함. 추가 권한 키 필요 여부는 실제 Flutter plugin 사용 범위 확인 필요.
- Apple Sign-in native 구현(`ASAuthorizationController`, nonce, identity token 처리)은 iOS native diff 안에 없고 entitlement/Pod만 있음. nonce 검증과 identity token 처리, refresh 흐름은 Flutter/Dart 또는 백엔드 범위에서 별도 확인 필요.
- `FirebaseAppDelegateProxyEnabled` override는 Info.plist에서 보이지 않음. 따라서 native 설정만 보면 swizzling을 끄지는 않았음.
