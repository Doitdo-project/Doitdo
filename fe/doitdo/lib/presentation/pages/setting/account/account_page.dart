import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/pages/setting/account/account_view_model.dart';
import 'package:doitdo/presentation/pages/setting/account/widgets/password_change_dialog.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_dialog.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_top_bar.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_padding_layout.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_scaffold.dart';

/// 설정 > 계정 설정 화면.
///
/// 3개 섹션 구성:
///   1) 로그인 정보 — 이메일 + 비밀번호 변경 진입
///   2) 소셜 계정 연동 — 카카오 / 구글 연결 상태 및 연결/해제
///   3) 기타 — 로그아웃
///
/// 상세/하위 화면이므로 `DoitdoTopBar` 를 두고 자동 back 버튼 활성.
///
/// 소셜 연결 상태는 로컬 [StatefulWidget] 상태로만 관리 (mock).
/// 실제 AuthRepository 연결 플로우가 붙으면 ViewModel / provider 로 승격.
class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  bool _kakaoConnected = false;
  bool _googleConnected = false;

  @override
  Widget build(BuildContext context) {
    return DoitdoScaffold(
      topBar: const DoitdoTopBar(title: '계정 설정'),
      body: DoitdoPaddingLayout(
        top: 24,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _SectionLabel('로그인 정보'),
            const SizedBox(height: 8),
            _AccountCard(
              children: [
                const _EmailRow(
                  // TODO: currentUserProvider 연결 시 실제 사용자 이메일로 교체.
                  email: 'ateliers@example.com',
                ),
                const _CardDivider(),
                _ChevronTile(
                  label: '비밀번호 변경',
                  onTap: () => showPasswordChangeDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionLabel('소셜 계정 연동'),
            const SizedBox(height: 8),
            _AccountCard(
              children: [
                _SocialAccountRow(
                  provider: _SocialProvider.kakao,
                  isConnected: _kakaoConnected,
                  onConnect: () {
                    // TODO: 실제 Kakao 계정 연결 플로우 (AuthRepository 확장 후).
                    setState(() => _kakaoConnected = true);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _AccountCard(
              children: [
                _SocialAccountRow(
                  provider: _SocialProvider.google,
                  isConnected: _googleConnected,
                  onConnect: () {
                    // TODO: 실제 Google 계정 연결 플로우.
                    setState(() => _googleConnected = true);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionLabel('기타'),
            const SizedBox(height: 8),
            _AccountCard(
              children: [
                _ChevronTile(
                  leading: const _DestructiveLeadingIcon(
                    icon: Icons.logout,
                  ),
                  label: '로그아웃',
                  onTap: () => _handleLogout(context, ref),
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

Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
  final ok = await showDoitdoDialog(
    context: context,
    title: '로그아웃하시겠어요?',
    message: '다음 이용을 위해 다시 로그인이 필요해요.',
    confirmLabel: '로그아웃',
    cancelLabel: '취소',
  );
  if (ok != true) return;

  final success = await ref.read(accountViewModelProvider.notifier).signOut();
  if (!context.mounted) return;

  if (success) {
    context.go(AppRoutes.welcome);
    return;
  }
  final error = ref.read(accountViewModelProvider).error;
  if (error != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 섹션 라벨 (회색, 작은 글씨) — "로그인 정보" / "소셜 계정 연동" / "기타".
// ─────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: AppTextStyles.labelMedium.copyWith(
          color: colors.textHint,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 흰색 라운드 카드 컨테이너. 내부 타일들을 Column 으로 쌓음.
// ─────────────────────────────────────────────────────────────────
class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 20,
      endIndent: 20,
      color: context.colors.divider,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 이메일 표시 (라벨 + 값, 탭 불가).
// ─────────────────────────────────────────────────────────────────
class _EmailRow extends StatelessWidget {
  const _EmailRow({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이메일',
            style: AppTextStyles.bodySmall.copyWith(
              color: colors.textHint,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: AppTextStyles.bodyLarge.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 화살표 포함 탭 가능한 행 (비밀번호 변경 / 로그아웃 등).
// ─────────────────────────────────────────────────────────────────
class _ChevronTile extends StatelessWidget {
  const _ChevronTile({
    required this.label,
    required this.onTap,
    this.leading,
  });

  final String label;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
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

// ─────────────────────────────────────────────────────────────────
// 소셜 계정 행 — 좌측 원형 아이콘 + 라벨 + 우측 "연결됨" / "연결하기".
// ─────────────────────────────────────────────────────────────────
enum _SocialProvider { kakao, google }

class _SocialAccountRow extends StatelessWidget {
  const _SocialAccountRow({
    required this.provider,
    required this.isConnected,
    required this.onConnect,
  });

  final _SocialProvider provider;
  final bool isConnected;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (label, iconAsset, iconBg) = switch (provider) {
      // 카카오 공식 브랜드 옐로우 고정 (#FEE500) — 다크모드에서도 동일하게 노출되어야 브랜드 가이드 준수.
      _SocialProvider.kakao => (
          '카카오톡',
          'assets/images/kakao.png',
          const Color(0xFFFEE500),
        ),
      _SocialProvider.google => (
          '구글',
          'assets/images/google.png',
          colors.surface,
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _SocialIconBadge(iconAsset: iconAsset, backgroundColor: iconBg),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyLarge.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
          if (isConnected)
            Text(
              '연결됨',
              style: AppTextStyles.bodyMedium.copyWith(
                // 시안 고정 톤 — 연결 완료를 은은한 베이지 브라운으로.
                color: const Color(0xFFD8C2B6),
              ),
            )
          else
            _ConnectButton(onPressed: onConnect),
        ],
      ),
    );
  }
}

/// 소셜 아이콘 동그라미 배경 + 에셋 로고.
class _SocialIconBadge extends StatelessWidget {
  const _SocialIconBadge({
    required this.iconAsset,
    required this.backgroundColor,
  });

  final String iconAsset;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isNeutralBg = backgroundColor == colors.surface;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        // 배경이 흰색(surface) 인 경우만 가시성 확보를 위한 얇은 테두리.
        border: isNeutralBg ? Border.all(color: colors.border) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Image.asset(iconAsset, fit: BoxFit.contain),
      ),
    );
  }
}

/// 우측 "연결하기" 버튼.
class _ConnectButton extends StatelessWidget {
  const _ConnectButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: 28,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          '연결하기',
          style: AppTextStyles.labelMedium.copyWith(
            color: colors.onPrimary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 로그아웃용 leading 아이콘 — 원형 연한 빨강 배경 + 빨강 아이콘.
// ─────────────────────────────────────────────────────────────────
class _DestructiveLeadingIcon extends StatelessWidget {
  const _DestructiveLeadingIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    // 파괴적(로그아웃/탈퇴) 액션용 고정 브랜드 톤 — 시맨틱 토큰 아직 없음.
    const bg = Color(0xFFFFEEEA);
    const fg = Color(0xFFE04040);
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
      ),
      child: const Icon(Icons.logout, size: 18, color: fg),
    );
  }
}
