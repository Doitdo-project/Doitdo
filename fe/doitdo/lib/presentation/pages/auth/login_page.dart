import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:doitdo/core/errors/exceptions.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/core/utils/error_message_mapper.dart';
import 'package:doitdo/domain/entities/user.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/pages/auth/login_view_model.dart';
import 'package:doitdo/presentation/pages/auth/widgets/auth_pill_button.dart';
import 'package:doitdo/presentation/pages/auth/widgets/auth_text_field.dart';
import 'package:doitdo/presentation/pages/auth/widgets/inline_back_bar.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  static const _bgColor = Color(0xFFF8F5EC);

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _userIdCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 사용자가 필드를 수정하면 이전 실패 메시지(아이디/비번 틀림 등) 를 자동으로 지운다.
    // 안 지우면 "틀렸어요" 상태 그대로 남아서 UX 가 어색.
    _userIdCtrl.addListener(_maybeClearError);
    _passwordCtrl.addListener(_maybeClearError);
  }

  void _maybeClearError() {
    ref.read(loginViewModelProvider.notifier).clearError();
  }

  @override
  void dispose() {
    _userIdCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final username = _userIdCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (username.isEmpty || password.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    ref.read(loginViewModelProvider.notifier).signIn(
          username: username,
          password: password,
        );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final loginState = ref.watch(loginViewModelProvider);

    // 실패 메시지는 기본적으로 **비번 필드 아래에 인라인** 으로 표시하고,
    // 네트워크/서버 장애 같은 "시스템 에러" 만 스낵바로 보여준다.
    final errorObj = loginState.error;
    final inlineError =
        errorObj == null ? null : mapLoginErrorMessage(errorObj);
    final isCredentialError = errorObj is UnauthorizedException ||
        (errorObj is ServerException &&
            (errorObj.statusCode == 400 || errorObj.statusCode == 401));

    // 성공 시 메인 이동, 시스템 에러만 스낵바.
    ref.listen<AsyncValue<User?>>(loginViewModelProvider, (prev, next) {
      next.whenOrNull(
        data: (user) {
          if (user == null) return;
          if (!context.mounted) return;
          context.go(AppRoutes.tamagochi);
        },
        error: (error, _) {
          if (!context.mounted) return;
          final isCred = error is UnauthorizedException ||
              (error is ServerException &&
                  (error.statusCode == 400 || error.statusCode == 401));
          if (isCred) return; // 인라인으로 이미 노출됨.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(mapErrorMessage(error))),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: LoginPage._bgColor,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Column(
            children: [
              const InlineBackBar(label: '로그인'),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 28.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 12.h),
                      // 로고 + 작은 캐릭터를 같은 라인에 묶어 시각적 무게를 줄임.
                      Center(
                        child: Image.asset(
                          'assets/images/doitdo__login_2.png',
                          height: 72.h,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.none,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Center(
                        child: Image.asset(
                          'assets/images/doitdo__login_3.png',
                          height: 28.h,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: 28.h),
                      AuthTextField(
                        controller: _userIdCtrl,
                        hint: '아이디',
                        textInputAction: TextInputAction.next,
                      ),
                      AuthTextField(
                        controller: _passwordCtrl,
                        hint: '비밀번호',
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                      ),

                      // 인라인 에러 메시지 — 아이디/비번 불일치 등.
                      if (inlineError != null && isCredentialError) ...[
                        SizedBox(height: 4.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: Text(
                            inlineError,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: const Color(0xFFE04040),
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ],

                      SizedBox(height: 24.h),

                      AuthPillButton(
                        label: loginState.isLoading ? '로그인 중…' : '로그인',
                        onPressed: loginState.isLoading ? null : _submit,
                      ),

                      SizedBox(height: 16.h),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => context.push(AppRoutes.register),
                            child: Text(
                              '회원가입',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: colors.textSecondary,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14.w),
                            child: Container(
                              width: 1,
                              height: 12.h,
                              color: colors.textHint.withOpacity(0.5),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.push(AppRoutes.findPassword),
                            child: Text(
                              '비밀번호 찾기',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: colors.textSecondary,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),
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


