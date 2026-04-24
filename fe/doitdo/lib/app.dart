import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_theme.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/providers/theme_mode_provider.dart';
import 'package:doitdo/presentation/widgets/shell/doitdo_web_preview_shell.dart';

class DoitdoApp extends ConsumerWidget {
  const DoitdoApp({super.key});

  static const Size _designSize = Size(375, 812);
  static const bool _minTextAdapt = true;
  static const bool _splitScreenMode = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        designSize: _designSize,
        minTextAdapt: _minTextAdapt,
        splitScreenMode: _splitScreenMode,
        child: app,
      );
    }

    return ScreenUtilInit(
      designSize: _designSize,
      minTextAdapt: _minTextAdapt,
      splitScreenMode: _splitScreenMode,
      child: app,
    );
  }
}