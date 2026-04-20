import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/providers/theme_mode_provider.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_padding_layout.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_scaffold.dart';

/// 설정 탭.
///
/// 여백이 필요한 리스트형 화면이므로 `DoitdoPaddingLayout` 사용.
/// 테마 모드 토글 동작을 데모 삼아 배치해 둔다.
class SettingPage extends ConsumerWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final themeMode = ref.watch(themeModeProvider);

    return DoitdoScaffold(
      body: DoitdoPaddingLayout(
        top: 16,
        child: ListView(
          children: [
            Text(
              '설정',
              style: AppTextStyles.titleLarge.copyWith(
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '테마',
              style: AppTextStyles.titleSmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('시스템')),
                ButtonSegment(value: ThemeMode.light, label: Text('라이트')),
                ButtonSegment(value: ThemeMode.dark, label: Text('다크')),
              ],
              selected: {themeMode},
              onSelectionChanged: (set) {
                ref.read(themeModeProvider.notifier).set(set.first);
              },
            ),
          ],
        ),
      ),
    );
  }
}