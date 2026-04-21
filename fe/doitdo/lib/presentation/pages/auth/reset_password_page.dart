import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/pages/auth/widgets/auth_text_field.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_primary_button.dart';

/// 비밀번호 변경 화면.
///
/// 레이아웃은 register_page 와 동일한 비율/간격 규칙을 따른다:
/// - 상단 여백: `h * 0.22`
/// - 필드 → 버튼 사이: `max(24, h * 0.04)`
/// - 하단 여백: `h * 0.05`
/// - 가로 패딩: 36
/// - 타이틀 weight: Medium (볼드 X)
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

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
                  // register_page 의 "타이틀 → 버튼" 거리를 매칭시키기 위한 보정값.
                  // register 는 필드 4개 기준 midGap = max(24, h*0.04).
                  // 이 화면은 서브카피 + 필드 2개라 부족분 126dp 를 더함.
                  final midGap = math.max(24.0, h * 0.04) + 126.0;
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
                          '비밀번호 변경',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: colors.textPrimary,
                            fontSize: 28,
                            fontFamily: 'GmarketSansMedium',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '새로 사용할 비밀번호를 입력해주세요',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── 새 비밀번호 ──
                        AuthTextField(
                          controller: _passwordCtrl,
                          hint: '변경할 비밀번호를 작성해주세요',
                          obscureText: true,
                          textInputAction: TextInputAction.next,
                          errorText: _passwordError,
                        ),
                        const SizedBox(height: 4),

                        // ── 비밀번호 확인 ──
                        AuthTextField(
                          controller: _confirmCtrl,
                          hint: '비밀번호 중복확인',
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          errorText: _confirmError,
                          showSuccess: _passwordMatch,
                          onSubmitted: (_) => _submit(),
                        ),

                        SizedBox(height: midGap),

                        // ── 완료 버튼 ──
                        DoitdoPrimaryButton(
                          label: '완료',
                          height: 48,
                          onPressed: _submit,
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
