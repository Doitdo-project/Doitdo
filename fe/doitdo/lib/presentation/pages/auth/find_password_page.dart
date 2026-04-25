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

/// 비밀번호 찾기 화면.
///
/// - Step 1: 이메일 입력 → "인증번호 보내기"
/// - Step 2: 인증번호 입력 (이메일 필드는 disabled 상태로 유지) → "다음"
class FindPasswordPage extends ConsumerStatefulWidget {
  const FindPasswordPage({super.key});

  static const _bgColor = Color(0xFFF8F5EC);

  @override
  ConsumerState<FindPasswordPage> createState() => _FindPasswordPageState();
}

class _FindPasswordPageState extends ConsumerState<FindPasswordPage> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  bool _emailTouched = false;
  bool _codeTouched = false;

  int _step = 1;

  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(() {
      if (!_emailTouched) _emailTouched = true;
      setState(() {});
    });
    _codeCtrl.addListener(() {
      if (!_codeTouched) _codeTouched = true;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  String? get _emailError {
    if (!_emailTouched) return null;
    final v = _emailCtrl.text.trim();
    if (v.isEmpty) return '이메일을 입력해주세요';
    if (!_emailRegex.hasMatch(v)) return '올바른 이메일 형식이 아닙니다';
    return null;
  }

  String? get _codeError {
    if (!_codeTouched) return null;
    final v = _codeCtrl.text.trim();
    if (v.isEmpty) return '인증번호를 입력해주세요';
    if (v.length < 4) return '인증번호를 다시 확인해주세요';
    return null;
  }

  bool get _isStepValid {
    if (_step == 1) {
      return _emailCtrl.text.trim().isNotEmpty &&
          _emailRegex.hasMatch(_emailCtrl.text.trim());
    }
    return _codeCtrl.text.trim().length >= 4;
  }

  void _onButtonPressed() {
    if (!_isStepValid) {
      setState(() {
        if (_step == 1) _emailTouched = true;
        if (_step == 2) _codeTouched = true;
      });
      return;
    }
    if (_step == 1) {
      // TODO: 이메일로 인증번호 발송 API 호출
      setState(() => _step = 2);
    } else {
      // TODO: 인증번호 검증 API 호출
      context.push(AppRoutes.resetPassword);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: FindPasswordPage._bgColor,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Column(
            children: [
              const InlineBackBar(label: '비밀번호 찾기'),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(28.w, 12.h, 28.w, 24.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _step == 1 ? '비밀번호를 잊으셨나요?' : '인증번호를 입력해주세요',
                        style: AppTextStyles.titleLarge.copyWith(
                          color: colors.textPrimary,
                          fontSize: 22.sp,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        _step == 1
                            ? '가입하신 이메일로 인증번호를 보내드려요'
                            : '이메일로 받은 인증번호를 입력해주세요',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colors.textSecondary,
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(height: 24.h),

                      AuthTextField(
                        controller: _emailCtrl,
                        hint: '이메일을 입력해주세요',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: _step == 1
                            ? TextInputAction.done
                            : TextInputAction.next,
                        enabled: _step == 1,
                        errorText: _step == 1 ? _emailError : null,
                      ),
                      if (_step == 2)
                        AuthTextField(
                          controller: _codeCtrl,
                          hint: '인증번호를 입력해주세요',
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          errorText: _codeError,
                          onSubmitted: (_) => _onButtonPressed(),
                        ),

                      SizedBox(height: 16.h),

                      AuthPillButton(
                        label: _step == 1 ? '인증번호 보내기' : '다음',
                        onPressed: _onButtonPressed,
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
