import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
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
  void dispose() {
    _userIdCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
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
                            const SizedBox(height: 12),
                            AuthTextField(
                              controller: _passwordCtrl,
                              hint: '비밀번호',
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                            ),

                            const SizedBox(height: 40),

                            DoitdoPrimaryButton(
                              label: '로그인',
                              onPressed: () {
                                if (_userIdCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) return;
                                context.go(AppRoutes.tamagochi);
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
