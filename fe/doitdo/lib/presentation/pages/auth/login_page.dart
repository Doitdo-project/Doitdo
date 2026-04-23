import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:doitdo/core/errors/exceptions.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/core/utils/error_message_mapper.dart';
import 'package:doitdo/domain/entities/user.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/pages/auth/login_view_model.dart';
import 'package:doitdo/presentation/pages/auth/widgets/auth_text_field.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_primary_button.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final loginState = ref.watch(loginViewModelProvider);

    // 실패 메시지는 기본적으로 **비번 필드 아래에 인라인** 으로 표시하고,
    // 네트워크/서버 장애 같은 "시스템 에러" 만 스낵바로 보여준다.
    final errorObj = loginState.error;
    final inlineError =
        errorObj == null ? null : mapLoginErrorMessage(errorObj);
    // 시스템 에러 판별 — 아이디/비번 불일치는 인라인만, 그 외엔 스낵바도.
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
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 36),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 로고를 화면 하단쪽으로 내리기 위한 상단 여백
                            SizedBox(height: constraints.maxHeight * 0.22),

                            // DoitDo 로고 (중앙 정렬)
                            // PNG 자체에 상하 투명 패딩이 있어 ClipRect+OverflowBox 로 가시 영역만 잘라서 보여준다.
                            Center(
                              child: ClipRect(
                                child: SizedBox(
                                  height: 150,
                                  child: OverflowBox(
                                    minHeight: 480,
                                    maxHeight: 480,
                                    minWidth: 0,
                                    maxWidth: 720,
                                    alignment: Alignment.center,
                                    child: Image.asset(
                                      'assets/images/doitdologo.png',
                                      height: 480,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            AuthTextField(
                              controller: _userIdCtrl,
                              hint: '아이디',
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 4),
                            AuthTextField(
                              controller: _passwordCtrl,
                              hint: '비밀번호',
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                            ),

                            // 인라인 에러 메시지 — 아이디/비번 불일치 등.
                            // 자리를 미리 비워두면 뜰 때 레이아웃이 튀니까 조건부로 삽입.
                            if (inlineError != null &&
                                isCredentialError) ...[
                              const SizedBox(height: 12),
                              Text(
                                inlineError,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: const Color(0xFFE04040),
                                ),
                              ),
                            ],

                            const SizedBox(height: 40),

                            DoitdoPrimaryButton(
                              label: loginState.isLoading ? '로그인 중…' : '로그인',
                              onPressed: loginState.isLoading
                                  ? null
                                  : () {
                                      final username = _userIdCtrl.text.trim();
                                      final password = _passwordCtrl.text;
                                      if (username.isEmpty || password.isEmpty) {
                                        return;
                                      }
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      ref
                                          .read(loginViewModelProvider.notifier)
                                          .signIn(
                                            username: username,
                                            password: password,
                                          );
                                    },
                            ),

                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () =>
                                      context.push(AppRoutes.register),
                                  child: Text(
                                    '회원가입',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  child: Text(
                                    '|',
                                    style: TextStyle(color: colors.textHint),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      context.push(AppRoutes.findPassword),
                                  child: Text(
                                    '비밀번호 찾기',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          ],
                        ),
                      ),
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
