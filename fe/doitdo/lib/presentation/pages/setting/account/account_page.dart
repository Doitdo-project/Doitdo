import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/core/utils/error_message_mapper.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/pages/auth/welcome_view_model.dart';
import 'package:doitdo/presentation/pages/setting/account/account_view_model.dart';
import 'package:doitdo/presentation/providers/active_palette_provider.dart';
import 'package:doitdo/presentation/pages/setting/account/widgets/password_change_dialog.dart';
import 'package:doitdo/presentation/pages/setting/widgets/withdraw_password_sheet.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';
import 'package:doitdo/presentation/providers/current_user_provider.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_dialog.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_top_bar.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_padding_layout.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_scaffold.dart';

/// 설정 > 계정 설정 화면.
///
/// 2개 섹션 + 하단 회원탈퇴 링크 구성:
///   1) 로그인 정보 — 이메일 + 비밀번호 변경 진입
///   2) 기타 — 로그아웃
///   3) 회원탈퇴 — 파괴적 액션. 카드 외 작은 텍스트 링크로 노출 우선순위 낮춤.
///
/// 상세/하위 화면이므로 `DoitdoTopBar` 를 두고 자동 back 버튼 활성.
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 로그아웃 결과 부수효과.
    // state 가 `bool?` 이라 data 가 `true` 인 경우만 "signOut 성공" 으로 판단한다.
    // `null` 은 초기 진입이라 무시 — void 로 두면 초기 build 전이도 성공으로 오인됨.
    ref.listen<AsyncValue<bool?>>(accountViewModelProvider, (prev, next) {
      next.whenOrNull(
        data: (success) {
          if (success != true) return;
          if (!context.mounted) return;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            context.go(AppRoutes.welcome);
          });
        },
        error: (error, _) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(mapErrorMessage(error))),
          );
        },
      );
    });

    return DoitdoScaffold(
      topBar: const DoitdoTopBar(title: '계정 설정'),
      body: DoitdoPaddingLayout(
        top: 24,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _SectionLabel('로그인 정보'),
            const SizedBox(height: 8),
            // 전역 currentUserProvider 구독 — 이메일 표시 + hasPassword 분기.
            // 로딩 중엔 빈 문자열 / 에러면 "-" 로 페일세이프 (계정 화면에서 에러 메시지까지
            // 노출하면 본질이 흐려지므로 축약). hasPassword 도 로딩/에러 시엔 false 로 폴백 →
            // "비밀번호 변경" 진입을 일단 숨기는 게 보수적으로 안전.
            Builder(builder: (_) {
              final userAsync = ref.watch(currentUserProvider);
              final email = userAsync.when(
                data: (u) => u?.email ?? '',
                loading: () => '',
                error: (_, __) => '-',
              );
              final hasPassword = userAsync.maybeWhen(
                data: (u) => u?.hasPassword ?? false,
                orElse: () => false,
              );
              return _AccountCard(
                children: [
                  _EmailRow(email: email),
                  // 소셜 전용 가입자(hasPassword=false) 는 "비밀번호 변경" 자체를 숨긴다.
                  // 백엔드도 시도 시 U03-001 으로 거절하므로 진입 자체를 막는 게 UX 정합.
                  if (hasPassword) ...[
                    const _CardDivider(),
                    _ChevronTile(
                      label: '비밀번호 변경',
                      onTap: () => showPasswordChangeDialog(context),
                    ),
                  ],
                ],
              );
            }),
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
            const SizedBox(height: 24),
            // 회원탈퇴 — 파괴적이지만 노출 우선순위 낮게. 카드/아이콘 없이
            // 작은 회색 텍스트로 두어 일반 메뉴와 시각적으로 구분.
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

Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
  final ok = await showDoitdoDialog(
    context: context,
    title: '로그아웃하시겠어요?',
    message: '다음 이용을 위해 다시 로그인이 필요해요.',
    confirmLabel: '로그아웃',
    cancelLabel: '취소',
  );
  if (ok != true) return;

  // signOut 시작만 알리고 결과는 View 의 ref.listen 이 처리.
  // (성공 시 웰컴으로 이동, 실패 시 스낵바)
  ref.read(accountViewModelProvider.notifier).signOut();
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

  // 탈퇴 성공 → 로컬 토큰 + SDK 세션만 정리.
  // 서버가 이미 모든 토큰을 무효화했으므로 logout API 호출은 불필요.
  ref.read(welcomeViewModelProvider.notifier).reset();
  ref.invalidate(currentUserProvider);
  await ref.read(activePaletteProvider.notifier).clear();
  await ref.read(authRepositoryProvider).signOut(skipServerLogout: true);
  if (!context.mounted) return;
  context.go(AppRoutes.welcome);
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('회원탈퇴가 완료되었어요.')),
  );
}

// ─────────────────────────────────────────────────────────────────
// 섹션 라벨 (회색, 작은 글씨) — "로그인 정보" / "기타".
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
