import 'package:flutter/material.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';

/// 전역 ThemeData 팩토리.
///
/// 실제 앱 컬러는 대부분 `DoitdoColors` ThemeExtension에 담겨 있고,
/// Material 컴포넌트가 내부적으로 참조하는 `ColorScheme`은 그에 맞게 파생시킨다.
///
/// [fontFamily] 는 사용자가 설정에서 고른 폰트 family 이름.
/// 'GmarketSans' 또는 'Pretendard' 등. AppTextStyles 의 TextStyle 은 fontFamily 를
/// 비워뒀으므로 이 값이 모든 Text 의 기본 폰트가 된다.
class AppTheme {
  AppTheme._();

  static ThemeData light({String fontFamily = 'GmarketSans'}) =>
      _build(DoitdoColors.light, Brightness.light, fontFamily);
  static ThemeData dark({String fontFamily = 'GmarketSans'}) =>
      _build(DoitdoColors.dark, Brightness.dark, fontFamily);

  static ThemeData _build(
      DoitdoColors colors, Brightness brightness, String fontFamily) {
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
      fontFamily: fontFamily,
      extensions: <ThemeExtension<dynamic>>[colors],
      textTheme: _textTheme(colors.textPrimary, fontFamily),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.topBarBg,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.titleSmall.copyWith(
          color: colors.textPrimary,
          fontFamily: fontFamily,
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
  /// 색상과 fontFamily를 테마에 맞게 주입한다.
  static TextTheme _textTheme(Color textColor, String fontFamily) {
    TextStyle apply(TextStyle s) =>
        s.copyWith(color: textColor, fontFamily: fontFamily);
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