# FE lib 리뷰 결과

## 검토 요약
- 검토 파일 수: 152 (`fe/doitdo/lib/**`, `*.freezed.dart`, `*.g.dart`, `.gitkeep` 제외)
- HIGH: 4건 / MEDIUM: 7건 / LOW: 3건
- 6축 커버리지: 상태관리/Riverpod ✓ / 비동기·에러 ✓ / 보안·입력 검증 ✓ / UI 회귀 ✓ / 데이터·네트워킹 ✓ / 성능 ✓
- 기준: `git diff main...HEAD -- 'fe/doitdo/lib/'`
- 제약 준수: 빌드/테스트 미실행, BE/iOS native/Android native/web 미검토, CDP MCP 미사용
- 확인 필요: 요청 컨텍스트의 브랜치는 `be/feat/user-birthdate-age-check`였으나, 실제 로컬 브랜치는 `be/docs/store-listing`로 확인됨. 아래 내용은 현재 `HEAD` 기준 `main...HEAD` diff에 대한 리뷰다.

## HIGH (반드시 머지 전 수정)

### [HIGH-1] 위젯 동기화 서비스 초기화 인스턴스와 실제 주입 인스턴스가 다름

- 파일: `fe/doitdo/lib/main.dart:53`, `fe/doitdo/lib/presentation/providers/app_data_providers.dart:92`
- 문제: `main.dart`에서 `WidgetSyncService().init()`을 호출하지만, Riverpod provider는 별도 `WidgetSyncService()` 인스턴스를 생성한다.
- 축: 비동기/에러, 데이터/네트워킹, UI 회귀
- 권장: `WidgetSyncService`를 앱 시작 시 1개 인스턴스로 만들고 `widgetSyncServiceProvider.overrideWithValue(initializedService)`로 주입하거나, provider 생성 시 `init()`을 보장하도록 변경한다. `_initialized`가 인스턴스 필드인 이상 `main.dart`에서 만든 임시 인스턴스 초기화는 provider 인스턴스에 전달되지 않는다.
- 영향: iOS App Group 설정이 `main.dart`의 임시 객체에만 적용되고, `AuthRepositoryImpl`/`TodoViewModel`이 쓰는 provider 객체는 `_initialized == false`인 별도 객체다. `syncAuthTokens`/`syncTodos`가 App Group이 아닌 기본 저장소에 쓰거나 저장 실패로 떨어질 수 있어, 최근 수정 영역인 위젯 sync가 실제 런타임에서 불안정할 수 있다.
- 근거: git diff hunk 발췌

```diff
+ // main.dart
+ await WidgetSyncService().init();
+
+ // app_data_providers.dart
+ final widgetSyncServiceProvider = Provider<WidgetSyncService>(
+   (ref) => WidgetSyncService(),
+ );
```

### [HIGH-2] refresh token을 홈 위젯 공유 저장소에 그대로 복제함

- 파일: `fe/doitdo/lib/core/widget_sync/widget_sync_service.dart:80`
- 문제: secure storage에 보관해야 할 refresh token을 홈 위젯 공유 저장소에도 저장한다.
- 축: 보안/입력 검증, 데이터/네트워킹
- 권장: 위젯에 refresh token을 넘기지 않는 설계를 우선 검토한다. 필요 시 Keychain Access Group, 짧은 수명의 위젯 전용 토큰, 또는 앱 본체를 깨워 처리하는 경로로 대체한다. 최소한 refresh token 저장을 제거하고 access token 만료 시 위젯 액션을 앱으로 위임하는 방식을 확인 필요.
- 영향: `AuthLocalDataSource`는 토큰을 secure storage에 저장하지만, 위젯 경로에서 같은 토큰 쌍을 App Group/UserDefaults/SharedPreferences 계열 저장소로 복제한다. `AuthInterceptor`가 refresh 실패로 secure storage를 지워도 위젯 공유 저장소는 별도 logout/clear 전까지 남을 수 있다.
- 근거: git diff hunk 발췌

```diff
+ static const String _keyAccessToken = 'doitdo.widget.accessToken';
+ static const String _keyRefreshToken = 'doitdo.widget.refreshToken';
+
+ Future<void> syncAuthTokens({
+   required String accessToken,
+   required String refreshToken,
+   required String apiBaseUrl,
+ }) async {
+   await _save(_keyAccessToken, accessToken);
+   await _save(_keyRefreshToken, refreshToken);
+   await _save(_keyApiBaseUrl, apiBaseUrl);
+ }
```

### [HIGH-3] 만 14세/생년월일 검증 경로가 FE 가입/소셜 신규 유저 플로우에 없음

- 파일: `fe/doitdo/lib/presentation/pages/auth/register_page.dart:153`, `fe/doitdo/lib/data/models/signup_request_dto.dart:1`, `fe/doitdo/lib/presentation/pages/auth/welcome_page.dart:399`
- 문제: 일반 가입 form/DTO와 소셜 신규 유저 분기에서 생년월일 또는 만 14세 확인 값이 없다.
- 축: 보안/입력 검증
- 권장: BE 스펙이 생년월일 또는 만 14세 동의 값을 요구하는지 확인 필요. 요구한다면 회원가입 form, `RegisterViewModel.submit`, `SignUpRequestDto`, 소셜 `isNewUser` 분기 모두에 동일한 age gate를 추가해야 한다.
- 영향: 일반 가입은 email/password/username만 검증하고 전송한다. 소셜 로그인은 `WelcomeSuccess.isNewUser`를 받지만 실제 라우팅에서 신규/기존을 구분하지 않고 바로 메인으로 보낸다. 만 14세 차단이 FE에서도 요구되는 작업이라면 일반 가입과 소셜 신규 가입 모두 우회 가능하다.
- 근거: git diff hunk 발췌

```diff
+ bool get _isFormValid {
+   if (_emailCtrl.text.trim().isEmpty) return false;
+   if (!_emailRegex.hasMatch(_emailCtrl.text.trim())) return false;
+   if (_userIdCtrl.text.trim().length < 4) return false;
+   if (_passwordCtrl.text.length < 8) return false;
+   if (_passwordCtrl.text != _confirmCtrl.text) return false;
+   if (ref.read(emailAvailabilityProvider).valueOrNull != true) return false;
+   if (ref.read(usernameAvailabilityProvider).valueOrNull != true) return false;
+   return true;
+ }
```

```diff
+ /// 스펙: `{email, password, username}` — 세 필드 모두 필수.
+ class SignUpRequestDto {
+   final String email;
+   final String password;
+   final String username;
+ }
```

```diff
+ data: (success) {
+   if (success == null) return;
+   if (!context.mounted) return;
+   context.go(AppRoutes.tamagochi);
+ },
```

### [HIGH-4] 캐릭터 조회의 모든 ServerException을 "미수령"으로 해석하고 POST를 이어서 호출함

- 파일: `fe/doitdo/lib/presentation/pages/tamagochi/character_view_model.dart:31`
- 문제: `GET /api/characters/me`의 모든 `ServerException`을 캐릭터 미수령으로 간주한다.
- 축: 비동기/에러, 데이터/네트워킹
- 권장: 서버의 "캐릭터 없음" 상태를 명확한 status/code로 구분하고, 그 경우에만 `receiveEgg()`를 호출한다. 500/403/도메인 오류는 `AsyncError`로 유지해 자동 mutation을 막아야 한다.
- 영향: `GET /api/characters/me`가 서버 장애나 권한 이외의 4xx/5xx로 실패해도 `data(null)`이 되고, 홈 진입 시 `POST /api/characters/me/egg`가 자동 실행될 수 있다. 데이터 생성 API가 에러 복구 경로에 묶여 있어 장애를 숨기거나 중복/오염 mutation을 만들 수 있다.
- 근거: git diff hunk 발췌

```diff
+ Future<void> load() async {
+   state = const AsyncValue<Character?>.loading().copyWithPrevious(state);
+   try {
+     final character = await _repository.getMyCharacter();
+     state = AsyncValue.data(character);
+   } on ServerException catch (e) {
+     appLogger.d('character not yet received (server ${e.statusCode})');
+     state = const AsyncValue.data(null);
+   } catch (e, st) {
+     state = AsyncValue.error(e, st);
+   }
+ }
+
+ Future<void> ensureCharacter() async {
+   await load();
+   final hasNoCharacter =
+       current is AsyncData<Character?> && current.value == null;
+   if (hasNoCharacter) {
+     await receiveEgg();
+   }
+ }
```

## MEDIUM

### [MEDIUM-1] Apple 로그인 성공 후 FCM 토큰 등록이 빠짐

- 파일: `fe/doitdo/lib/presentation/pages/auth/welcome_view_model.dart:36`
- 문제: Google/Kakao/email 로그인 경로와 달리 Apple 로그인 성공 후 FCM token 등록을 호출하지 않는다.
- 축: 비동기/에러, FCM 토큰 등록
- 권장: Google/Kakao/email과 동일하게 Apple 성공 경로에서도 `unawaited(ref.read(fcmTokenRegistrarProvider).register())`를 호출한다.
- 영향: Apple 신규/기존 사용자는 로그인 직후 서버에 device token이 등록되지 않는다. 앱 재시작 후 splash에서 보정될 수는 있지만, 첫 세션에서는 푸시 수신 대상에서 빠질 수 있다.
- 근거: git diff hunk 발췌

```diff
+ Future<void> signInWithGoogle() async {
+   final (_, __, isNewUser) = await repo.signInWithGoogle();
+   ref.invalidate(currentUserProvider);
+   unawaited(ref.read(fcmTokenRegistrarProvider).register());
+   return WelcomeSuccess(isNewUser: isNewUser);
+ }
+
+ Future<void> signInWithApple() async {
+   final (_, __, isNewUser) = await repo.signInWithApple();
+   ref.invalidate(currentUserProvider);
+   return WelcomeSuccess(isNewUser: isNewUser);
+ }
```

### [MEDIUM-2] Todo 삭제 API 오류가 repository에서 swallow되고 UI는 낙관 삭제를 확정함

- 파일: `fe/doitdo/lib/data/repositories/todo_repository_impl.dart:147`, `fe/doitdo/lib/presentation/pages/todo/todo_view_model.dart:447`
- 문제: 삭제 API 실패를 repository가 `print`만 하고 삼키며, ViewModel은 이미 로컬 목록에서 삭제한다.
- 축: 비동기/에러, 데이터/네트워킹, UI 회귀
- 권장: `deleteTodo`도 `safeApiCallVoid`로 예외를 전파하고, ViewModel에서 이전 state를 보관한 뒤 실패 시 롤백/스낵바/재조회 중 하나를 수행한다.
- 영향: 서버 삭제가 실패해도 repository가 성공처럼 반환하므로 화면에서는 항목이 사라진다. 다음 fetch 전까지 앱/서버/위젯 상태가 diverge하고, 사용자에게 실패를 알릴 방법도 없다.
- 근거: git diff hunk 발췌

```diff
+ Future<void> deleteTodo(String id, {String? scope}) async {
+   final intId = int.tryParse(id) ?? 0;
+   try {
+     await _todoApi.deleteTodo(intId, scope);
+   } catch (e) {
+     print('삭제 통신 에러: $e'); // 에러가 나면 로그만 찍기
+   }
+ }
```

```diff
+ Future<void> deleteTodo(String id, {String? scope}) async {
+   state = state.copyWith(
+     allTodos: state.allTodos.where((t) => t.id != id).toList(),
+   );
+   _updateCalendarEvents(state.allTodos);
+   _updateDisplayedTodos();
+   await AsyncValue.guard(() => _repository.deleteTodo(id, scope: scope));
+ }
```

### [MEDIUM-3] Todo 완료 토글 PATCH 결과를 버려서 실패 시 롤백/재시도 불가

- 파일: `fe/doitdo/lib/presentation/pages/todo/todo_view_model.dart:350`, `fe/doitdo/lib/presentation/pages/todo/todo_view_model.dart:480`
- 문제: 완료 토글 PATCH를 `unawaited(AsyncValue.guard(...))`로 실행한 뒤 결과를 확인하지 않는다.
- 축: 비동기/에러, race condition, 위젯 sync
- 권장: optimistic update를 유지하더라도 `AsyncValue.guard` 결과를 await하고 실패 시 이전 todo 상태로 롤백하거나 `fetchTodos()`로 서버 truth를 다시 당긴다. fire-and-forget을 유지할 경우 실패 telemetry와 보정 루프가 필요하다.
- 영향: PATCH 실패가 `AsyncValue` 안에만 갇히고 호출자는 결과를 보지 않는다. 완료 count 증가를 감지한 다마고치 exp refresh와 홈 위젯 sync도 낙관 상태를 기반으로 움직여 서버 실패 시 연쇄 오염 가능성이 있다.
- 근거: git diff hunk 발췌

```diff
+ state = state.copyWith(
+   allTodos: state.allTodos
+       .map((t) => t.id == id ? t.copyWith(isDone: newIsDone) : t)
+       .toList(),
+   fadingTodoIds: newFading,
+ );
+ _updateCalendarEvents(state.allTodos);
+ _updateDisplayedTodos();
+
+ unawaited(
+   AsyncValue.guard(() => _repository.updateTodoStatus(id, newStatus)),
+ );
```

### [MEDIUM-4] TodoState 모든 변경마다 홈 위젯 저장/갱신이 발생함

- 파일: `fe/doitdo/lib/presentation/pages/todo/todo_view_model.dart:22`, `fe/doitdo/lib/presentation/pages/todo/todo_view_model.dart:649`
- 문제: `TodoState`의 모든 변경에 `_syncWidget` listener가 반응한다.
- 축: 성능, 위젯 sync
- 권장: `allTodos`/`allSomedayTodos`가 변경된 경우에만 sync하거나 debounce/distinct를 둔다. 필터, 선택 날짜, 캘린더 format, fading UI 상태 변경은 위젯 payload와 무관하므로 제외한다.
- 영향: `setFilter`, `onDaySelected`, `_updateCalendarEvents`, fading 제거처럼 payload가 변하지 않는 state 변경도 디스크 I/O와 `HomeWidget.updateWidget`을 유발한다. 빠른 스크롤/필터 조작/토글 시 OS throttling과 불필요한 rebuild/I/O가 누적될 수 있다.
- 근거: git diff hunk 발췌

```diff
+ addListener(_syncWidget, fireImmediately: false);
+ fetchTodos();
+ fetchCalendarData();
```

```diff
+ void _syncWidget(TodoState s) {
+   final todayTodos = s.allTodos
+       .where((t) => _isTodayForWidget(t, today))
+       .map(_toWidgetDto)
+       .toList(growable: false);
+   final somedayTodos =
+       s.allSomedayTodos.map(_toWidgetDto).toList(growable: false);
+   unawaited(_widgetSync.syncTodos(
+     todayTodos: todayTodos,
+     somedayTodos: somedayTodos,
+   ));
+ }
```

### [MEDIUM-5] 이메일/아이디 중복 확인 결과가 현재 입력값과 결합되지 않아 debounce 구간에서 이전 true를 재사용할 수 있음

- 파일: `fe/doitdo/lib/presentation/pages/auth/register_page.dart:71`, `fe/doitdo/lib/presentation/pages/auth/register_page.dart:153`
- 문제: 입력 변경 직후 availability provider를 초기화하지 않아 이전 `available == true` 상태가 남을 수 있다.
- 축: 상태관리/Riverpod, 비동기/에러, 입력 검증
- 권장: 입력이 바뀌는 즉시 availability provider를 `null` 또는 keyed state로 초기화하고, 응답이 돌아올 때 요청했던 값이 현재 controller 값과 같은지 확인한다.
- 영향: 이전 이메일/아이디가 `available == true`인 상태에서 사용자가 다른 유효한 값으로 바꾼 뒤 400ms debounce 또는 새 응답 전 제출하면, 현재 입력값에 대한 중복 확인 없이 `_isFormValid`가 통과할 수 있다. 서버 unique 제약이 최종 방어선인지 확인 필요.
- 근거: git diff hunk 발췌

```diff
+ void _onEmailChanged() {
+   _emailDebounce?.cancel();
+   final v = _emailCtrl.text.trim();
+   if (v.isEmpty || !_emailRegex.hasMatch(v)) {
+     ref.read(emailAvailabilityProvider.notifier).clear();
+     return;
+   }
+   _emailDebounce = Timer(_debounceDelay, () {
+     if (!mounted) return;
+     ref.read(emailAvailabilityProvider.notifier).check(v);
+   });
+ }
+
+ bool get _isFormValid {
+   ...
+   if (ref.read(emailAvailabilityProvider).valueOrNull != true) return false;
+   if (ref.read(usernameAvailabilityProvider).valueOrNull != true) return false;
+   return true;
+ }
```

### [MEDIUM-6] 보호 라우트에 인증 redirect가 없어 deep link로 메인 화면 진입 가능

- 파일: `fe/doitdo/lib/presentation/navigation/app_router.dart:50`
- 문제: GoRouter redirect가 widget deep link만 처리하고 인증이 필요한 route 접근은 검사하지 않는다.
- 축: 보안/입력 검증, UI 회귀, navigator stack
- 권장: GoRouter redirect를 Riverpod auth state와 연결해 `/todo`, `/tamagochi`, `/setting` 등 보호 라우트 접근 시 토큰이 없으면 welcome/login으로 보내도록 한다. widget deep link만 예외 처리하는 현재 redirect와 별도로 auth guard가 필요하다.
- 영향: 일반 앱 기동은 splash가 토큰을 검사하지만, 외부 deep link/복원된 route/웹 프리뷰 등으로 보호 route가 직접 열리면 인증 없는 화면 생성과 API 호출이 가능하다. 서버가 막더라도 앱은 Unauthorized UI/스택 오염 상태로 진입할 수 있다.
- 근거: git diff hunk 발췌

```diff
+ final GoRouter appRouter = GoRouter(
+   navigatorKey: _rootNavigatorKey,
+   initialLocation: AppRoutes.splash,
+   redirect: (context, state) {
+     final raw = state.uri.toString();
+     final path = state.uri.path;
+     if (raw.startsWith('doitdo://widget') || path.startsWith('/widget')) {
+       return AppRoutes.splash;
+     }
+     return null;
+   },
+   routes: [
+     GoRoute(path: AppRoutes.todo, builder: ...),
+     GoRoute(path: AppRoutes.tamagochi, builder: ...),
+     GoRoute(path: AppRoutes.setting, builder: ...),
+   ],
+ );
```

### [MEDIUM-7] 디버그 네트워크 로그가 request/response body를 그대로 출력함

- 파일: `fe/doitdo/lib/core/network/logging_interceptor.dart:16`
- 문제: header는 마스킹하지만 request/response body는 그대로 로그에 남긴다.
- 축: 보안/입력 검증
- 권장: auth endpoint의 body 로그를 생략하거나 `password`, `accessToken`, `refreshToken`, `appleAuthorizationCode`, `idToken` 계열 키를 재귀적으로 마스킹한다. response body에도 토큰이 포함될 수 있으므로 동일하게 마스킹한다.
- 영향: header의 Authorization은 마스킹하지만 로그인 body의 password, 소셜 token, 로그인 응답의 access/refresh token은 디버그 로그에 남는다. release는 `kDebugMode`로 막혀 있으나, 실기 디버그/공유 로그/CI 디버그 빌드에서 민감정보가 노출될 수 있다.
- 근거: git diff hunk 발췌

```diff
+ appLogger.d(
+   '→ ${options.method} ${options.uri}\n'
+   'headers: ${_maskHeaders(options.headers)}\n'
+   'body: ${options.data}',
+ );
+
+ appLogger.d(
+   '← ${response.statusCode} ${response.requestOptions.uri}\n'
+   'body: ${response.data}',
+ );
```

## LOW

### [LOW-1] SnapScrollPhysics가 snap target을 maxScrollExtent로 clamp하지 않음

- 파일: `fe/doitdo/lib/core/utils/snap_scroll_physics.dart:49`, `fe/doitdo/lib/presentation/pages/tamagochi/tamagochi_page.dart:319`
- 문제: snap target을 `snapOffset`으로 직접 잡고 실제 `maxScrollExtent` 안으로 제한하지 않는다.
- 축: UI 회귀, snap scroll physics edge
- 권장: `final snapTarget = snapOffset.clamp(position.minScrollExtent, position.maxScrollExtent)`처럼 실제 scroll extent 안으로 target을 제한한다.
- 영향: 콘텐츠가 짧거나 디바이스 높이가 커서 `maxScrollExtent < headerHeight`인 경우 snap target이 실제 extent 밖이 된다. 일부 뷰포트에서 overscroll/jank 또는 헤더 half-hidden 상태가 생길 수 있다.
- 근거: git diff hunk 발췌

```diff
+ if (pixels <= 0 || pixels >= snapOffset) {
+   return super.createBallisticSimulation(position, velocity);
+ }
+
+ if (velocity.abs() >= _flingVelocityThreshold) {
+   target = velocity > 0 ? snapOffset : 0.0;
+ } else {
+   target = pixels > snapOffset / 2 ? snapOffset : 0.0;
+ }
+ return ScrollSpringSimulation(spring, pixels, target, velocity, ...);
```

```diff
+ CustomScrollView(
+   physics: SnapScrollPhysics(snapOffset: headerHeight),
+   slivers: [
```

### [LOW-2] FCM foreground listener 구독을 보관하지 않아 재초기화 시 중복 리스너를 막을 수 없음

- 파일: `fe/doitdo/lib/core/notifications/fcm_service.dart:13`
- 문제: `FirebaseMessaging.onMessage.listen`의 subscription을 보관하지 않는다.
- 축: 상태관리/Riverpod, 비동기/에러
- 권장: `StreamSubscription<RemoteMessage>`를 static 필드로 보관하고 init 재호출 시 기존 구독을 재사용하거나 cancel 후 재등록한다.
- 영향: 현재 `main()`에서 1회 호출되는 구조라 즉시 문제는 제한적이다. 다만 Firebase 재초기화, 테스트 harness, hot restart 유사 흐름에서 foreground 알림이 중복 표시될 수 있어 방어가 없다.
- 근거: git diff hunk 발췌

```diff
+ static Future<void> init() async {
+   ...
+   FirebaseMessaging.onMessage.listen(_handleForeground);
+ }
```

### [LOW-3] page-local 성격의 AsyncNotifierProvider 일부가 autoDispose가 아님

- 파일: `fe/doitdo/lib/presentation/pages/setting/notification/notification_settings_view_model.dart:165`, `fe/doitdo/lib/presentation/pages/todo/todo_add_notifier.dart:47`
- 문제: 화면/시트 전용 성격의 provider가 `autoDispose` 없이 선언되어 있다.
- 축: 상태관리/Riverpod
- 권장: 화면/시트 전용 provider는 `autoDispose`로 바꾸고, 전역 캐시가 필요한 provider만 non-autoDispose로 남긴다.
- 영향: 알림 설정 페이지와 Todo 추가 시트 상태가 화면 이탈 후에도 ProviderContainer에 남는다. 큰 메모리 누수는 아니지만, stale error/loading state가 다음 진입에 재사용될 여지가 있다.
- 근거: git diff hunk 발췌

```diff
+ final notificationSettingsViewModelProvider =
+     AsyncNotifierProvider<NotificationSettingsViewModel, UserSettingResp>(
+   NotificationSettingsViewModel.new,
+ );
+
+ final todoAddNotifierProvider = AsyncNotifierProvider<TodoAddNotifier, void>(
+   () => TodoAddNotifier(),
+ );
```
