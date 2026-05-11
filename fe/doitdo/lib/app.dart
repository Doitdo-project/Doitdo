import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_theme.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/pages/todo/todo_view_model.dart';
import 'package:doitdo/presentation/providers/current_user_provider.dart';
import 'package:doitdo/presentation/providers/font_scale_provider.dart';
import 'package:doitdo/presentation/providers/theme_mode_provider.dart';
import 'package:doitdo/presentation/widgets/shell/doitdo_web_preview_shell.dart';

class DoitdoApp extends ConsumerStatefulWidget {
  const DoitdoApp({super.key});

  static const Size _designSize = Size(375, 812);
  static const bool _minTextAdapt = true;
  static const bool _splitScreenMode = false;

  @override
  ConsumerState<DoitdoApp> createState() => _DoitdoAppState();
}

class _DoitdoAppState extends ConsumerState<DoitdoApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 홈 위젯에서 todo 가 토글/추가/삭제되면 서버에는 반영되지만 앱 메모리의
      // TodoViewModel state 는 갱신되지 않는다. foreground 복귀 시 notifier 를
      // 직접 호출해 state 를 유지한 채로 서버 데이터만 새로 덮어쓴다.
      // (ref.invalidate 는 state 를 파괴해 잠깐 로딩 플래시가 발생하므로 사용 안 함)
      //
      // 단, 비로그인 상태에서는 refresh 하지 않는다 — iOS 의 Google/Kakao/Apple
      // OAuth 는 시스템 UI 가 뜨면서 Flutter 앱이 background → foreground 로 전환되어
      // 이 콜백이 발화하는데, 그 시점엔 currentUser 가 아직 null 이고 새로 생성될
      // ViewModel 의 fetchTodos / fetchCalendarData 는 401 만 받고 끝난다. 그러는
      // 사이 frame 안의 provider refresh 가 unmount 중인 widget(defunct element) 의
      // listener 를 호출해 framework.dart 5340 어설션 → cascade 어설션으로 release
      // 빌드에서 회색 화면이 뜬다.
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user == null) return;
      unawaited(ref.read(todoViewModelProvider.notifier).fetchTodos());
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final fontScale = ref.watch(fontScaleProvider);

    final app = MaterialApp.router(
      title: 'doitdo',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(fontScale),
        ),
        child: child!,
      ),
    );

    // 웹 프리뷰 모드에서는 DoitdoWebPreviewShell 이 내부적으로 ScreenUtil.configure 를
    // 호출해 디바이스별 viewport 로 재구성하므로 바깥쪽 ScreenUtilInit 을 생략.
    // 모바일/데스크톱 네이티브 빌드에서는 기존처럼 ScreenUtilInit 이 감싼다.
    if (DoitdoWebPreviewShell.isEnabled) {
      return DoitdoWebPreviewShell(
        designSize: DoitdoApp._designSize,
        minTextAdapt: DoitdoApp._minTextAdapt,
        splitScreenMode: DoitdoApp._splitScreenMode,
        child: app,
      );
    }

    return ScreenUtilInit(
      designSize: DoitdoApp._designSize,
      minTextAdapt: DoitdoApp._minTextAdapt,
      splitScreenMode: DoitdoApp._splitScreenMode,
      child: app,
    );
  }
}
