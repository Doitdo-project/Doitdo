import 'package:flutter/material.dart';

import 'package:doitdo/core/theme/app_colors.dart';

/// 시맨틱 컬러 토큰.
///
/// 위젯 레이어에서는 `AppColors`(원본 팔레트)를 직접 참조하지 않고
/// `Theme.of(context).extension<DoitdoColors>()!` 또는
/// `context.colors` 확장자를 통해 접근한다.
///
/// 라이트/다크는 물론, 추후 사용자 커스텀 테마는
/// 이 확장 인스턴스를 교체하는 방식으로 지원한다.
@immutable
class DoitdoColors extends ThemeExtension<DoitdoColors> {
  const DoitdoColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.primary,
    required this.onPrimary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.border,
    required this.divider,
    required this.topBarBg,
    required this.bottomNavBg,
    required this.scrim,
    required this.streakCardBg,
    required this.streakDotInactive,
    required this.streakDotActive,
    required this.streakSilhouette,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color primary;
  final Color onPrimary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color border;
  final Color divider;
  final Color topBarBg;
  final Color bottomNavBg;
  final Color scrim;

  /// 스트릭/콜렉션 카드의 크림톤 배경.
  /// 라이트는 브랜드 크림(#FFF8F2), 다크에선 surface 톤으로 적응시켜
  /// 다크모드에서 페이지 안에 떠있는 흰 카드처럼 보이는 문제를 막는다.
  final Color streakCardBg;

  /// 스트릭 동그라미(미체크) / 위 카드의 보조 톤.
  /// 라이트는 라이트 그레이(#EAE8DE), 다크는 border 톤(#3A3A3A).
  final Color streakDotInactive;

  /// 스트릭 동그라미(체크) — 브랜드 오렌지.
  /// 라이트는 #E2782B, 다크는 #FFA066 (다크에서 가독성을 위해 더 밝은 톤).
  final Color streakDotActive;

  /// 도감 미해금 캐릭터 실루엣 색.
  /// 라이트(크림 카드) 위에서는 어둡게(#2B2B2B), 다크(어두운 카드) 위에서는
  /// 살짝 밝은 회색(#5A5A5A) 으로 톤을 뒤집어 카드 위에서 보이도록 한다.
  final Color streakSilhouette;

  static const DoitdoColors light = DoitdoColors(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: AppColors.componentBg,
    primary: AppColors.loginBtnOn,
    onPrimary: AppColors.btnText,
    textPrimary: AppColors.textDefault,
    textSecondary: AppColors.calendarDateText,
    textHint: AppColors.textFieldHint,
    border: AppColors.streakCheckX,
    divider: Color(0xFFEAEAEA),
    topBarBg: Color(0xFFFFFFFF),
    bottomNavBg: Color(0xFFFFFFFF),
    scrim: Color(0x66000000),
    streakCardBg: AppColors.streakBg,
    streakDotInactive: AppColors.streakCheckX,
    streakDotActive: AppColors.streakCheck,
    streakSilhouette: Color(0xFF2B2B2B),
  );

  static const DoitdoColors dark = DoitdoColors(
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    surfaceAlt: Color(0xFF2A2A2A),
    primary: Color(0xFFFFA066),
    onPrimary: Color(0xFF1A1A1A),
    textPrimary: Color(0xFFF5F5F5),
    textSecondary: Color(0xFFB0B0B0),
    textHint: Color(0xFF777777),
    border: Color(0xFF3A3A3A),
    divider: Color(0xFF2F2F2F),
    topBarBg: Color(0xFF1A1A1A),
    bottomNavBg: Color(0xFF1A1A1A),
    scrim: Color(0x99000000),
    streakCardBg: Color(0xFF2A2A2A),
    streakDotInactive: Color(0xFF3A3A3A),
    streakDotActive: Color(0xFFFFA066),
    streakSilhouette: Color(0xFF5A5A5A),
  );

  @override
  DoitdoColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? primary,
    Color? onPrimary,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? border,
    Color? divider,
    Color? topBarBg,
    Color? bottomNavBg,
    Color? scrim,
    Color? streakCardBg,
    Color? streakDotInactive,
    Color? streakDotActive,
    Color? streakSilhouette,
  }) {
    return DoitdoColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      topBarBg: topBarBg ?? this.topBarBg,
      bottomNavBg: bottomNavBg ?? this.bottomNavBg,
      scrim: scrim ?? this.scrim,
      streakCardBg: streakCardBg ?? this.streakCardBg,
      streakDotInactive: streakDotInactive ?? this.streakDotInactive,
      streakDotActive: streakDotActive ?? this.streakDotActive,
      streakSilhouette: streakSilhouette ?? this.streakSilhouette,
    );
  }

  @override
  DoitdoColors lerp(ThemeExtension<DoitdoColors>? other, double t) {
    if (other is! DoitdoColors) return this;
    return DoitdoColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      topBarBg: Color.lerp(topBarBg, other.topBarBg, t)!,
      bottomNavBg: Color.lerp(bottomNavBg, other.bottomNavBg, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      streakCardBg: Color.lerp(streakCardBg, other.streakCardBg, t)!,
      streakDotInactive:
          Color.lerp(streakDotInactive, other.streakDotInactive, t)!,
      streakDotActive: Color.lerp(streakDotActive, other.streakDotActive, t)!,
      streakSilhouette:
          Color.lerp(streakSilhouette, other.streakSilhouette, t)!,
    );
  }
}

/// `context.colors.primary` 처럼 짧게 쓰기 위한 확장.
extension DoitdoColorsX on BuildContext {
  DoitdoColors get colors => Theme.of(this).extension<DoitdoColors>()!;
}