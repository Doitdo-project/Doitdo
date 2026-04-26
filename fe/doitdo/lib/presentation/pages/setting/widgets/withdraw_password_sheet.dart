import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/core/errors/exceptions.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/core/utils/error_message_mapper.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_bottom_sheet.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_sheet_action_button.dart';

/// 회원탈퇴 흐름의 비밀번호 재입력 시트.
///
/// **시트 자체에서 [UserRepository.withdraw] 호출까지 처리**해 비번 오류 시
/// 시트를 닫지 않고 인라인 에러로 다시 입력받게 한다 — 일반 시트(View 는 그리기만)
/// 패턴에서 약간 벗어나지만, "비번 틀려서 SnackBar → 시트 다시 열기" 흐름이
/// 사용자 입장에서 번거롭기 때문에 self-contained 로 둔다.
///
/// 반환:
/// - `true`: 탈퇴 성공 — 부모가 [AuthRepository.signOut] + Welcome 라우팅 처리
/// - `null`: 사용자가 "이전" / 바깥 탭 / 뒤로가기로 취소
///
/// 일반 가입 계정은 비번 필수, 소셜 가입 계정은 비번 비워두면 서버가 검증 스킵.
Future<bool?> showWithdrawPasswordSheet(BuildContext context) {
  return showDoitdoBottomSheet<bool>(
    context: context,
    child: const _WithdrawPasswordSheet(),
  );
}

class _WithdrawPasswordSheet extends ConsumerStatefulWidget {
  const _WithdrawPasswordSheet();

  @override
  ConsumerState<_WithdrawPasswordSheet> createState() =>
      _WithdrawPasswordSheetState();
}

class _WithdrawPasswordSheetState
    extends ConsumerState<_WithdrawPasswordSheet> {
  final _ctrl = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final raw = _ctrl.text;
    final password = raw.isEmpty ? null : raw;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(userRepositoryProvider)
          .withdraw(currentPassword: password);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      // 회원탈퇴는 비번 불일치도 백엔드가 401 로 응답하기 때문에 토큰 만료
      // 매핑 메시지("다시 로그인해 주세요.") 대신 백엔드 message 를 우선 노출.
      final msg = e is UnauthorizedException && e.message.isNotEmpty
          ? e.message
          : mapErrorMessage(e);
      setState(() {
        _isSubmitting = false;
        _errorMessage = msg;
      });
    }
  }

  void _clearErrorIfAny(String _) {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // 파괴적 액션 — 시맨틱 토큰 추가 시 교체 예정. category_page 의 삭제 메뉴와 통일.
    const errorColor = Color(0xFFE04040);
    final hasError = _errorMessage != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              '비밀번호 확인',
              style: AppTextStyles.titleSmall.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '본인 확인을 위해 비밀번호를 입력해 주세요.\n'
            '소셜 로그인으로 가입했다면 비워두고 확인을 눌러주세요.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasError ? errorColor : colors.border,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _ctrl,
              obscureText: true,
              enabled: !_isSubmitting,
              onChanged: _clearErrorIfAny,
              style: AppTextStyles.bodyLarge.copyWith(
                color: colors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '비밀번호',
                hintStyle: AppTextStyles.bodyLarge.copyWith(
                  color: colors.textHint,
                ),
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                _errorMessage!,
                style: AppTextStyles.bodySmall.copyWith(color: errorColor),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: DoitdoSheetActionButton(
                  label: '이전',
                  isPrimary: false,
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DoitdoSheetActionButton(
                  label: _isSubmitting ? '처리 중…' : '확인',
                  onPressed: _isSubmitting ? null : _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
