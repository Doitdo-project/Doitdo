import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:doitdo/core/errors/exceptions.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/app_theme.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/core/utils/error_message_mapper.dart';
import 'package:doitdo/domain/entities/user.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/navigation/post_auth_destination.dart';
import 'package:doitdo/presentation/pages/auth/login_view_model.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_primary_button.dart';
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
    // ref.listen 은 ConsumerWidget/ConsumerStatefulWidget 의 build 메서드 직접
    // 호출 컨텍스트에서만 등록할 수 있다. _buildBody 는 Builder 의 closure 안에서
    // 호출되므로 별도 StatelessElement 의 build 컨텍스트가 되어, 거기서 listen 을
    // 등록하면 element 매핑이 어긋나 assertion 실패. 따라서 listen 만 여기서
    // 등록하고, 실제 화면 구성은 Theme(Builder) 안에서 _buildBody 가 담당.
    ref.listen<AsyncValue<User?>>(loginViewModelProvider, (prev, next) {
      next.whenOrNull(
        data: (user) {
          if (user == null) return;
          if (!mounted) return;
          // 온보딩(생년월일/약관) 미완료 사용자는 메인 탭이 아니라 온보딩 단계로 보낸다.
          // addPostFrameCallback: GoRouter 가 Navigator 를 잠근 상태에서 중복 push
          // 가 발생하지 않도록 현재 프레임 처리 완료 후 이동.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            context.go(resolvePostAuthDestination(ref, user));
          });
        },
        error: (error, _) {
          if (!mounted) return;
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

    // 인증 화면은 브랜드 크림 톤 + 캐릭터 일러스트 기반이라 다크 모드 토글과
    // 무관하게 항상 라이트 테마로 강제. 그래야 토큰 텍스트 색(textPrimary 등) 도
    // 라이트 값을 받아 크림 배경 위에서 가독성이 보장된다.
    //
    // Builder 대신 Consumer 를 써서 (1) 테마 변경 후의 새 context 도 받고
    // (2) 그 안에서 ref.watch / ref.listen 이 정상 동작하도록 한다.
    // (Builder 안의 ref.listen 은 ConsumerStatefulElement 의 debugDoingBuild
    //  체크에 걸려 assertion fail.)
    //
    // PopScope — `/find-password` 의 소셜 안내 카드 CTA 가 `context.go(/login)`
    // 으로 진입할 때 스택이 [login] 만 남아 시스템 back 이 앱을 종료한다.
    // 인증 흐름은 무조건 welcome 으로 회귀하도록 안전망을 둔다. 정상 push 진입엔
    // canPop=true 라 기본 동작 그대로.
    final canPop = Navigator.canPop(context);
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (!mounted) return;
        context.go(AppRoutes.welcome);
      },
      child: Theme(
        data: AppTheme.light,
        child:
            Consumer(builder: (context, ref, _) => _buildBody(context, ref)),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
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

    return Scaffold(
      backgroundColor: LoginPage._bgColor,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Column(
            children: [
              InlineBackBar(
                label: '로그인',
                fallback: () => context.go(AppRoutes.welcome),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 28.w),
                  // AutofillGroup — iOS Keychain / Android Autofill Framework 가
                  // 아이디/비밀번호 한 쌍을 인식하고 자동완성 + 저장 제안을 띄우도록.
                  child: AutofillGroup(
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
                          autofillHints: const [AutofillHints.username],
                        ),
                        AuthTextField(
                          controller: _passwordCtrl,
                          hint: '비밀번호',
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
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

                      DoitdoPrimaryButton(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}


