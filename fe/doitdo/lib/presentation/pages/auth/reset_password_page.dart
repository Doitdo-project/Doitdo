import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/pages/auth/widgets/auth_pill_button.dart';
import 'package:doitdo/presentation/pages/auth/widgets/auth_text_field.dart';
import 'package:doitdo/presentation/pages/auth/widgets/inline_back_bar.dart';

/// 비밀번호 변경 화면.
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  static const _bgColor = Color(0xFFF8F5EC);

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _passwordTouched = false;
  bool _confirmTouched = false;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(() {
      if (!_passwordTouched) _passwordTouched = true;
      setState(() {});
    });
    _confirmCtrl.addListener(() {
      if (!_confirmTouched) _confirmTouched = true;
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

  void _submit() {
    if (!_isValid) {
      setState(() {
        _passwordTouched = true;
        _confirmTouched = true;
      });
      return;
    }
    // TODO: 비밀번호 변경 API 호출
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
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
                        errorText: _passwordError,
                      ),
                      AuthTextField(
                        controller: _confirmCtrl,
                        hint: '비밀번호 확인',
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        errorText: _confirmError,
                        showSuccess: _passwordMatch,
                        onSubmitted: (_) => _submit(),
                      ),

                      SizedBox(height: 16.h),

                      AuthPillButton(
                        label: '완료',
                        onPressed: _submit,
                      ),
                    ],
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
