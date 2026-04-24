import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/core/utils/error_message_mapper.dart';
import 'package:doitdo/presentation/pages/setting/account/password_change_view_model.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_primary_button.dart';

/// 비밀번호 변경 다이얼로그.
///
/// 현재 비밀번호 + 새 비밀번호 + 새 비밀번호 확인 3필드를 받아 비밀번호 변경을 수행한다.
/// 상단 우측 `X`, 하단 `취소` 모두 닫기 동작 동일.
///
/// 반환값: 실제 변경을 수행했으면 `true`, 취소/닫기 시 `null`.
///
/// NOTE: 가이드(§8)에서는 `showDoitdoDialog` + `content:` 권장이지만
/// 이 다이얼로그는 공용 `DoitdoDialog` 가 강제하는 Row 형 confirm/cancel 레이아웃과 맞지 않고
/// (X 닫기 + 세로 배치 변경하기·취소 링크) `confirmLabel` 을 숨길 수 없어 커스텀 구현이 불가피.
/// 추후 `DoitdoDialog` 에 `actions` 커스텀 슬롯이 추가되면 해당 방식으로 이관 예정.
Future<bool?> showPasswordChangeDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _PasswordChangeDialog(),
  );
}

class _PasswordChangeDialog extends ConsumerStatefulWidget {
  const _PasswordChangeDialog();

  @override
  ConsumerState<_PasswordChangeDialog> createState() =>
      _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends ConsumerState<_PasswordChangeDialog> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // 현재 비밀번호 필드만 눈 아이콘 토글 제공 (시안 기준).
  bool _currentObscured = true;

  /// 클라이언트 측 선검증 실패 메시지. 서버 호출 전에 즉시 노출.
  /// (서버가 던지는 에러는 `ref.listen` 으로 스낵바 처리.)
  String? _localError;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentCtrl.text;
    final next = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    // 1) 클라이언트 선검증 — 빈 값 / 확인 불일치는 서버 왕복 없이 즉시 차단.
    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      setState(() => _localError = '모든 항목을 입력해 주세요.');
      return;
    }
    if (next != confirm) {
      setState(() => _localError = '새 비밀번호가 일치하지 않아요.');
      return;
    }
    if (next.length < 8) {
      setState(() => _localError = '새 비밀번호는 8자 이상이어야 해요.');
      return;
    }
    setState(() => _localError = null);

    // 2) ViewModel 호출 — 성공/실패 라우팅은 ref.listen 에서 처리.
    await ref.read(passwordChangeViewModelProvider.notifier).submit(
          currentPassword: current,
          newPassword: next,
        );
  }

  void _cancel() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    // 제출 결과 부수효과.
    // data == true 만 "변경 성공" 으로 판단 (초기 Data(null) 오인 방지).
    ref.listen<AsyncValue<bool?>>(passwordChangeViewModelProvider,
        (prev, next) {
      next.whenOrNull(
        data: (success) {
          if (success != true) return;
          if (!mounted) return;
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('비밀번호가 변경되었어요.')),
          );
        },
        error: (error, _) {
          if (!mounted) return;
          setState(() => _localError = mapErrorMessage(error));
        },
      );
    });

    final isLoading =
        ref.watch(passwordChangeViewModelProvider).isLoading;
    final colors = context.colors;
    return Dialog(
      backgroundColor: colors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 헤더: 중앙 타이틀 + 우측 닫기 ──
            Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '비밀번호 변경',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                Positioned(
                  right: 0,
                  child: GestureDetector(
                    onTap: _cancel,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '보안을 위해 주기적으로 비밀번호를 변경해주세요.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            // ── 입력 필드 3종 ──
            _LabeledPasswordField(
              label: '현재 비밀번호',
              hint: '현재 비밀번호 입력',
              controller: _currentCtrl,
              obscureText: _currentObscured,
              suffixIcon: GestureDetector(
                onTap: () => setState(
                    () => _currentObscured = !_currentObscured),
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  _currentObscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: colors.textHint,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _LabeledPasswordField(
              label: '새 비밀번호',
              hint: '새 비밀번호 입력',
              controller: _newCtrl,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            _LabeledPasswordField(
              label: '새 비밀번호 확인',
              hint: '새 비밀번호 재입력',
              controller: _confirmCtrl,
              obscureText: true,
            ),
            // 선검증 / 서버 에러 메시지를 입력 필드 바로 아래에 노출.
            // 공간이 없을 땐 0 높이로 잡혀서 다이얼로그 높이가 튀지 않게.
            if (_localError != null) ...[
              const SizedBox(height: 12),
              Text(
                _localError!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFFE04040),
                ),
              ),
            ],
            const SizedBox(height: 28),
            DoitdoPrimaryButton(
              label: isLoading ? '변경 중...' : '변경하기',
              height: 48,
              onPressed: isLoading ? null : _submit,
            ),
            const SizedBox(height: 8),
            // ── 취소 텍스트 링크 ──
            Center(
              child: TextButton(
                onPressed: _cancel,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '취소',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 라벨 + 크림톤 배경 TextField 한 쌍.
class _LabeledPasswordField extends StatelessWidget {
  const _LabeledPasswordField({
    required this.label,
    required this.controller,
    this.hint,
    this.obscureText = true,
    this.suffixIcon,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            // 시안 고정 다크 브라운 라벨 — 다크모드 대응은 후속 토큰화.
            color: const Color(0xFF7A5742),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: AppTextStyles.bodyMedium.copyWith(
            color: colors.textPrimary,
            letterSpacing: obscureText ? 2 : 0,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              // 시안 placeholder 톤 (@40%).
              color: const Color(0x66857469),
            ),
            filled: true,
            // 시안 입력 배경 — 크림톤 고정.
            fillColor: const Color(0xFFF5F3F1),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: _fieldBorder,
            enabledBorder: _fieldBorder,
            focusedBorder: _fieldBorder,
            suffixIcon: suffixIcon == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: suffixIcon,
                  ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 20,
              minHeight: 20,
            ),
          ),
        ),
      ],
    );
  }

  static final OutlineInputBorder _fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  );
}
