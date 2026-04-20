import 'package:flutter/material.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';

/// 전역 ThemeData 팩토리.
///
/// 실제 앱 컬러는 대부분 `DoitdoColors` ThemeExtension에 담겨 있고,
/// Material 컴포넌트가 내부적으로 참조하는 `ColorScheme`은 그에 맞게 파생시킨다.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(DoitdoColors.light, Brightness.light);
  static ThemeData get dark => _build(DoitdoColors.dark, Brightness.dark);

  static ThemeData _build(DoitdoColors colors, Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: colors.primary,
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      surface: colors.surface,
      onSurface: colors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      extensions: <ThemeExtension<dynamic>>[colors],
      textTheme: _textTheme(colors.textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.topBarBg,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.titleSmall.copyWith(
          color: colors.textPrimary,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// 텍스트 스타일은 `AppTextStyles`의 typography를 유지하되,
  /// 색상만 테마에 맞게 주입한다.
  static TextTheme _textTheme(Color textColor) {
    TextStyle apply(TextStyle s) => s.copyWith(color: textColor);
    return TextTheme(
      displayLarge: apply(AppTextStyles.displayLarge),
      titleLarge: apply(AppTextStyles.titleLarge),
      titleMedium: apply(AppTextStyles.titleMedium),
      titleSmall: apply(AppTextStyles.titleSmall),
      bodyLarge: apply(AppTextStyles.bodyLarge),
      bodyMedium: apply(AppTextStyles.bodyMedium),
      bodySmall: apply(AppTextStyles.bodySmall),
      labelLarge: apply(AppTextStyles.labelLarge),
      labelMedium: apply(AppTextStyles.labelMedium),
      labelSmall: apply(AppTextStyles.labelSmall),
    );
  }
}