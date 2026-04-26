import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/pages/setting/widgets/default_screen_sheet.dart';
import 'package:doitdo/presentation/pages/setting/widgets/theme_mode_sheet.dart';
import 'package:doitdo/presentation/pages/setting/widgets/withdraw_password_sheet.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';
import 'package:doitdo/presentation/providers/default_screen_provider.dart';
import 'package:doitdo/presentation/providers/theme_mode_provider.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_dialog.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_padding_layout.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_scaffold.dart';

/// 메인 3탭 중 "설정" 탭.
///
/// 메인 탭이라 DoitdoTopBar 는 두지 않는다 (가이드 §4).
/// 상단에 프로필 섹션, 아래로 기능 카드 3종.
/// 로그아웃은 계정 설정 페이지로 이동해 처리한다 (중복 방지).
/// 하단 BottomNav 는 셸이 담당하므로 페이지에서는 신경 쓰지 않는다.
class SettingPage extends ConsumerWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final defaultScreen = ref.watch(defaultScreenProvider);

    return DoitdoScaffold(
      body: DoitdoPaddingLayout(
        top: 40,
        child: ListView(
          // DoitdoPaddingLayout 이 좌우 24 를 담당하므로 ListView 기본 padding 제거.
          padding: EdgeInsets.zero,
          children: [
            _SettingCard(
              children: [
                _SettingTile(
                  icon: Icons.account_circle_outlined,
                  label: '계정',
                  onTap: () => context.push(AppRoutes.account),
                ),
                _SettingTile(
                  icon: Icons.category_outlined,
                  label: '투두 카테고리',
                  onTap: () => context.push(AppRoutes.category),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SettingCard(
              children: [
                _SettingTile(
                  icon: Icons.notifications_none_outlined,
                  label: '알림',
                  onTap: () => context.push(AppRoutes.notification),
                ),
                _SettingTile(
                  icon: Icons.home_outlined,
                  label: '기본 화면',
                  trailing: _defaultScreenLabel(defaultScreen),
                  onTap: () => _openDefaultScreenSheet(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SettingCard(
              children: [
                _SettingTile(
                  icon: Icons.brightness_6_outlined,
                  label: '화면 모드',
                  trailing: _themeModeLabel(context, themeMode),
                  onTap: () => _openThemeModeSheet(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 회원탈퇴 — 파괴적이지만 노출 우선순위는 낮게. 카드/아이콘 없이
            // 작은 회색 텍스트로 두어 일반 설정과 시각적으로 구분.
            Center(
              child: InkWell(
                onTap: () => _handleWithdraw(context, ref),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    '회원탈퇴',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.colors.textHint,
                      decoration: TextDecoration.underline,
                      decorationColor: context.colors.textHint,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// 테마 모드 → 사용자 표시용 라벨.
/// 저장값이 `system` 인 경우 현재 실제 밝기에 해당하는 라벨로 치환 — 시트에 system 선택지를 두지 않으므로
/// 사용자가 "라이트 / 다크" 관점으로만 보게 한다.
String _themeModeLabel(BuildContext context, ThemeMode mode) {
  if (mode == ThemeMode.system) {
    final brightness = MediaQuery.of(context).platformBrightness;
    return brightness == Brightness.dark ? '다크 모드' : '라이트 모드';
  }
  return mode == ThemeMode.dark ? '다크 모드' : '라이트 모드';
}

Future<void> _openThemeModeSheet(BuildContext context, WidgetRef ref) async {
  final currentMode = ref.read(themeModeProvider);
  final picked = await showThemeModeSheet(
    context: context,
    current: currentMode,
  );
  // [이전] / 바깥 탭 = null, [확인] = 선택한 ThemeMode.
  if (picked != null && picked != currentMode) {
    await ref.read(themeModeProvider.notifier).set(picked);
  }
}

/// 기본 화면 → 타일 trailing 표시용 라벨.
String _defaultScreenLabel(DefaultScreen screen) => switch (screen) {
      DefaultScreen.home => '홈',
      DefaultScreen.calendar => '캘린더',
    };

Future<void> _openDefaultScreenSheet(
    BuildContext context, WidgetRef ref) async {
  final current = ref.read(defaultScreenProvider);
  final picked = await showDefaultScreenSheet(
    context: context,
    current: current,
  );
  if (picked != null && picked != current) {
    await ref.read(defaultScreenProvider.notifier).set(picked);
  }
}

/// 회원탈퇴 핸들러.
///
/// 흐름: 확인 다이얼로그 → 비밀번호 시트(시트가 DELETE 까지 self-contained) →
///       성공 시 AuthRepository.signOut → Welcome 으로 이동.
///
/// 비번 입력 검증 및 백엔드 호출/에러 표시는 모두 시트 안에서 처리되므로
/// 여기서는 시트가 true 를 돌려준 경우(=탈퇴 성공)만 후속 정리한다.
Future<void> _handleWithdraw(BuildContext context, WidgetRef ref) async {
  final ok = await showDoitdoDialog(
    context: context,
    title: '정말 탈퇴하시겠어요?',
    message: '계정을 탈퇴하면 모든 할 일과 캐릭터 정보가 삭제되며 되돌릴 수 없어요.',
    confirmLabel: '탈퇴',
    cancelLabel: '취소',
  );
  if (ok != true) return;
  if (!context.mounted) return;

  final success = await showWithdrawPasswordSheet(context);
  if (success != true) return;
  if (!context.mounted) return;

  // 탈퇴 성공 → 로컬 토큰 + SDK 세션 정리.
  // signOut 안의 서버 logout 호출은 이미 세션이 정리된 상태라 401 떨어질 수 있는데,
  // signOut 이 try/catch 로 무시하도록 설계돼 있어 영향 없음.
  await ref.read(authRepositoryProvider).signOut();
  if (!context.mounted) return;
  context.go(AppRoutes.welcome);
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('회원탈퇴가 완료되었어요.')),
  );
}

/// 기능 타일들을 묶는 흰 라운드 카드.
///
/// 자식 사이에 얇은 divider 를 좌우 20px 인덴트해서 삽입.
/// 카드 라운드 밖으로 ink splash 가 튀어나오지 않도록 ClipRRect 로 클리핑.
class _SettingCard extends StatelessWidget {
  const _SettingCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i != children.length - 1) {
        items.add(Divider(
          height: 1,
          thickness: 1,
          indent: 20,
          endIndent: 20,
          color: colors.divider,
        ));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: Column(children: items),
        ),
      ),
    );
  }
}

/// 카드 한 줄 항목 — 좌측 오렌지 아이콘 + 라벨 + (선택) 우측 부가 텍스트 + 화살표.
class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// "라이트 모드" 처럼 우측에 현재 상태를 보여주고 싶을 때만 지정.
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Icon(icon, size: 22, color: colors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
            if (trailing != null) ...[
              Text(
                trailing!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.chevron_right,
              size: 20,
              color: colors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

