import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';

/// 앱 부팅 직후 잠시 노출되는 스플래시.
///
/// 현 단계에서는 단순히 정해진 시간 뒤 홈으로 이동하지만,
/// 추후 로그인 상태 판별/초기 리소스 프리로드 등을 이 화면에서 수행하고
/// 그 결과에 따라 라우팅을 분기하는 지점으로 확장한다.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    context.go(AppRoutes.tamagochi);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets, size: 80, color: colors.primary),
            const SizedBox(height: 16),
            Text(
              'doitdo',
              style: AppTextStyles.titleLarge.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}