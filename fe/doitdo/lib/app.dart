import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_theme.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/pages/todo/todo_view_model.dart';
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
      // TodoViewModel state 는 갱신되지 않는다. foreground 복귀 시 invalidate 로
      // autoDispose 재생성을 유도해 fetchTodos() 가 다시 돌게 한다.
      ref.invalidate(todoViewModelProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    final app = MaterialApp.router(
      title: 'doitdo',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
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
