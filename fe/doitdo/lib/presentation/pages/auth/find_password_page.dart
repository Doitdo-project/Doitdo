import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/pages/auth/widgets/auth_text_field.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_primary_button.dart';

/// 비밀번호 찾기 화면.
///
/// - Step 1: 이메일 입력 → "인증번호 보내기"
/// - Step 2: 인증번호 입력 (이메일 필드는 disabled 상태로 유지) → "다음"
///
/// 레이아웃은 register_page / reset_password_page 와 동일한 규칙:
/// - 상단 여백 `h * 0.22`
/// - 필드 → 버튼 사이 `max(24, h * 0.04)`
/// - 하단 여백 `h * 0.05`
/// - 가로 패딩 36
/// - 타이틀 weight Medium
class FindPasswordPage extends ConsumerStatefulWidget {
  const FindPasswordPage({super.key});

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
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/background2.jpg', fit: BoxFit.cover),
          GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            behavior: HitTestBehavior.opaque,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final h = constraints.maxHeight;
                  final topSpace = h * 0.22;
                  // register_page 의 "타이틀 → 버튼" 거리를 매칭시키기 위한 보정.
                  // Step 1 (필드 1개)일 때 198dp, Step 2 (필드 2개)일 때 126dp 를 더함.
                  final midGap = math.max(24.0, h * 0.04) +
                      (_step == 1 ? 198.0 : 126.0);
                  final bottomSpace = h * 0.05;

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      36,
                      topSpace,
                      36,
                      bottomSpace,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── 타이틀 (Medium weight) ──
                        Text(
                          '비밀번호 찾기',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: colors.textPrimary,
                            fontSize: 28,
                            fontFamily: 'GmarketSansMedium',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _step == 1
                              ? '가입하신 이메일로 인증번호를 보내드려요'
                              : '이메일로 받은 인증번호를 입력해주세요',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── 이메일 ──
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
                        const SizedBox(height: 4),

                        // ── 인증번호 (Step 2) ──
                        if (_step == 2)
                          AuthTextField(
                            controller: _codeCtrl,
                            hint: '인증번호를 입력해주세요',
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            errorText: _codeError,
                            onSubmitted: (_) => _onButtonPressed(),
                          ),

                        SizedBox(height: midGap),

                        // ── 메인 버튼 ──
                        DoitdoPrimaryButton(
                          label: _step == 1 ? '인증번호 보내기' : '다음',
                          height: 48,
                          onPressed: _onButtonPressed,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
