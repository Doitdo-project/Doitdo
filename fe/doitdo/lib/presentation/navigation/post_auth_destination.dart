import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/domain/entities/user.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/providers/default_screen_provider.dart';

/// 로그인 / 회원가입 / 소셜 로그인 / 세션 복원 직후 사용자를 보낼 다음 라우트를
/// 한 곳에서 결정한다.
///
/// 결정 규칙:
/// 1. `birthDateRegistered == false` → [AppRoutes.onboardingBirthDate]
/// 2. `agreementsAccepted == false`  → [AppRoutes.onboardingAgreements]
/// 3. 둘 다 true → 사용자가 설정한 [DefaultScreen] 에 따라
///    [AppRoutes.tamagochi] 또는 [AppRoutes.todo]
///
/// 튜토리얼은 온보딩 완료(약관 동의) 직후 agreements 페이지에서 직접 라우팅하므로
/// 여기서는 판단하지 않는다.
String resolvePostAuthDestination(WidgetRef ref, User user) {
  if (!user.birthDateRegistered) return AppRoutes.onboardingBirthDate;
  if (!user.agreementsAccepted) return AppRoutes.onboardingAgreements;
  final defaultScreen = ref.read(defaultScreenProvider);
  return switch (defaultScreen) {
    DefaultScreen.home => AppRoutes.tamagochi,
    DefaultScreen.calendar => AppRoutes.todo,
  };
}
