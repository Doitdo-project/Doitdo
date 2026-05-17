import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/app_theme.dart';
import 'package:doitdo/presentation/providers/font_family_provider.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/core/utils/error_message_mapper.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/pages/auth/reset_password_view_model.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_primary_button.dart';
import 'package:doitdo/presentation/pages/auth/widgets/auth_text_field.dart';
import 'package:doitdo/presentation/pages/auth/widgets/inline_back_bar.dart';

/// 비밀번호 변경 화면.
///
/// 진입 조건 — `/find-password` 에서 인증번호 검증에 성공해 1회용 [resetToken] 을
/// 발급받았을 때만 진입한다. 토큰은 라우트 extra 로 전달.
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key, required this.resetToken});

  /// `/api/auth/password/reset/verify-code` 응답으로 받은 1회용 토큰.
  final String resetToken;

  static const _bgColor = Color(0xFFF8F5EC);

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _passwordTouched = false;
  bool _confirmTouched = false;

  /// 서버 응답 에러 메시지 (인라인 표시용).
  String? _serverError;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(() {
      if (!_passwordTouched) _passwordTouched = true;
      if (_serverError != null) _serverError = null;
      setState(() {});
    });
    _confirmCtrl.addListener(() {
      if (!_confirmTouched) _confirmTouched = true;
      if (_serverError != null) _serverError = null;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? get _passwordError {
    if (_serverError != null) return _serverError;
    if (!_passwordTouched) return null;
    final v = _passwordCtrl.text;
    if (v.isEmpty) return '비밀번호를 입력해주세요';
    if (v.length < 8) return '비밀번호는 8자 이상이어야 합니다';
    return null;
  }

  String? get _confirmError {
    if (!_confirmTouched) return null;
    if (_confirmCtrl.text.isEmpty) return '비밀번호를 한 번 더 입력해주세요';
    if (_confirmCtrl.text != _passwordCtrl.text) return '비밀번호가 일치하지 않습니다';
    return null;
  }

  bool get _passwordMatch =>
      _passwordCtrl.text.isNotEmpty &&
      _passwordCtrl.text == _confirmCtrl.text;

  bool get _isValid =>
      _passwordCtrl.text.length >= 8 &&
      _passwordCtrl.text == _confirmCtrl.text;

  Future<void> _submit(bool isLoading) async {
    if (isLoading) return;
    if (!_isValid) {
      setState(() {
        _passwordTouched = true;
        _confirmTouched = true;
      });
      return;
    }
    await ref.read(resetPasswordViewModelProvider.notifier).submit(
          resetToken: widget.resetToken,
          newPassword: _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool?>>(resetPasswordViewModelProvider, (prev, next) {
      next.whenOrNull(
        data: (success) {
          if (success != true) return;
          if (!mounted) return;
          // 재설정 직후 자동 로그인은 정책상 안 함 — 로그인 화면으로 보내고
          // 안내 스낵바 노출. context.go 로 인증 스택 정리.
          context.go(AppRoutes.login);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('비밀번호가 변경되었어요. 새 비밀번호로 로그인해주세요.')),
          );
        },
        error: (e, _) {
          if (!mounted) return;
          setState(() => _serverError = mapErrorMessage(e));
        },
      );
    });

    final asyncState = ref.watch(resetPasswordViewModelProvider);
    final isLoading = asyncState.isLoading;

    // 인증 화면은 브랜드 크림 톤 기반이라 themeMode 와 무관하게 라이트 강제.
    return Theme(
      data: AppTheme.light(fontFamily: ref.watch(fontFamilyProvider).family),
      child: Builder(builder: (context) => _buildBody(context, isLoading)),
    );
  }

  Widget _buildBody(BuildContext context, bool isLoading) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: ResetPasswordPage._bgColor,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Column(
            children: [
              const InlineBackBar(label: '비밀번호 변경'),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(28.w, 12.h, 28.w, 24.h),
                  // AutofillGroup 으로 두 필드를 묶어야 iOS / Android 비밀번호 관리자가
                  // "새 비밀번호 저장" 제안을 일관되게 띄운다.
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '새 비밀번호 설정',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: colors.textPrimary,
                            fontSize: 22.sp,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          '새로 사용할 비밀번호를 입력해주세요',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colors.textSecondary,
                            fontSize: 13.sp,
                          ),
                        ),
                        SizedBox(height: 24.h),

                        AuthTextField(
                          controller: _passwordCtrl,
                          hint: '변경할 비밀번호 (8자 이상)',
                          obscureText: true,
                          textInputAction: TextInputAction.next,
                          enabled: !isLoading,
                          errorText: _passwordError,
                          autofillHints: const [AutofillHints.newPassword],
                        ),
                        AuthTextField(
                          controller: _confirmCtrl,
                          hint: '비밀번호 확인',
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          enabled: !isLoading,
                          errorText: _confirmError,
                          showSuccess: _passwordMatch,
                          autofillHints: const [AutofillHints.newPassword],
                          onSubmitted: (_) => _submit(isLoading),
                        ),

                        SizedBox(height: 16.h),

                        DoitdoPrimaryButton(
                          label: isLoading ? '변경 중...' : '완료',
                          onPressed:
                              isLoading ? null : () => _submit(isLoading),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
