import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/pages/setting/widgets/default_screen_sheet.dart';
import 'package:doitdo/presentation/pages/setting/widgets/profile_image_picker_sheet.dart';
import 'package:doitdo/presentation/pages/setting/widgets/theme_mode_sheet.dart';
import 'package:doitdo/presentation/providers/default_screen_provider.dart';
import 'package:doitdo/presentation/providers/profile_image_provider.dart';
import 'package:doitdo/presentation/providers/theme_mode_provider.dart';
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
            const _ProfileHeader(),
            const SizedBox(height: 32),
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

/// 상단 프로필 영역: 원형 아바타 + 닉네임 + 이메일.
///
/// 실제 유저 정보(닉네임/이메일) 는 `AuthRepository.restoreSession` / currentUserProvider 가
/// 붙으면 교체. 아바타는 로컬 `profileImageProvider` 에 저장된 파일 경로를 사용.
class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final imagePath = ref.watch(profileImageProvider);

    return Column(
      children: [
        GestureDetector(
          onTap: () => _handleAvatarTap(context, ref),
          behavior: HitTestBehavior.opaque,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // 브랜드 크림톤. 라이트/다크 무관하게 고정이므로 raw hex.
                  color: const Color(0xFFFFF5EE),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: imagePath == null
                      ? Center(
                          child: Icon(
                            Icons.person,
                            size: 48,
                            color: colors.primary,
                          ),
                        )
                      : Image.file(
                          File(imagePath),
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          // 파일 삭제/이동으로 로드 실패 시 기본 아이콘으로 폴백.
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(
                              Icons.person,
                              size: 48,
                              color: colors.primary,
                            ),
                          ),
                        ),
                ),
              ),
              // 카메라 뱃지 — 아바타가 탭 가능함을 직관적으로 알려줌.
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary,
                    border: Border.all(color: colors.surface, width: 2),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: 14,
                    color: colors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          // TODO: 실제 사용자 닉네임으로 교체
          '오둥이 주인',
          style: AppTextStyles.titleMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          // TODO: 실제 사용자 이메일로 교체
          'user@email.com',
          style: AppTextStyles.bodySmall.copyWith(
            color: colors.textHint,
          ),
        ),
      ],
    );
  }
}

/// 아바타 탭 핸들러 — 변경 방법 시트 → image_picker 호출 → provider 갱신.
Future<void> _handleAvatarTap(BuildContext context, WidgetRef ref) async {
  final action = await showProfileImagePickerSheet(context);
  if (action == null || !context.mounted) return;

  final picker = ImagePicker();
  XFile? file;
  try {
    switch (action) {
      case ProfileImageAction.camera:
        file = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 1024,
        );
      case ProfileImageAction.gallery:
        file = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1024,
        );
      case ProfileImageAction.reset:
        await ref.read(profileImageProvider.notifier).set(null);
        return;
    }
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('이미지를 불러오지 못했어요: $e')),
    );
    return;
  }

  if (file == null) return;
  await ref.read(profileImageProvider.notifier).set(file.path);
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

