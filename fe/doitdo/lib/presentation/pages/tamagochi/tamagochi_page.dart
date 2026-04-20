import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_full_layout.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_scaffold.dart';

/// 메인 홈(다마고치) 탭.
///
/// 픽셀 아트 캐릭터가 화면 전체를 채워야 하므로 `DoitdoFullLayout` 을 사용하고,
/// TopBar 는 의도적으로 두지 않는다(메인에서는 숨김).
class TamagochiPage extends ConsumerWidget {
  const TamagochiPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return DoitdoScaffold(
      body: DoitdoFullLayout(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pets, size: 120, color: colors.primary),
              const SizedBox(height: 16),
              Text(
                '다마고치 홈',
                style: AppTextStyles.titleLarge.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '여기에 픽셀 아트 캐릭터/배경이 들어갑니다.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}