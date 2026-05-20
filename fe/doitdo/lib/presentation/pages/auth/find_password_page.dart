import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:doitdo/core/errors/exceptions.dart';
import 'package:doitdo/core/utils/email_validator.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/app_theme.dart';
import 'package:doitdo/presentation/providers/font_family_provider.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/core/utils/error_message_mapper.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/pages/auth/find_password_view_model.dart';
import 'package:doitdo/presentation/pages/auth/widgets/auth_inline_notice.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_primary_button.dart';
import 'package:doitdo/presentation/pages/auth/widgets/auth_text_field.dart';
import 'package:doitdo/presentation/pages/auth/widgets/inline_back_bar.dart';

/// 비밀번호 찾기 화면.
///
/// - Step 1: 이메일 입력 → "인증번호 보내기"
/// - Step 2: 인증번호(6자리 숫자) 입력 → "다음"
///
/// step 전환은 [findPasswordViewModelProvider] 의 phase 변화를 listen 해서 처리.
/// step 2 검증 성공 시 발급된 `resetToken` 을 들고 [ResetPasswordPage] 로 이동
/// (push **replacement** — 토큰 1회용이라 뒤로가기로 step 2 코드 화면에 돌아오면
/// 재검증 시도하는 혼란이 생기므로 find 페이지를 스택에서 제거).
///
/// ### 1단계 응답 정책
///   - 일반 가입자 → 200 OK + 메일 발송 → step 2 진입
///   - 탈퇴 사용자 → 200 OK + 발송 없음 → step 2 에서 자연 실패 (서버 정책상 동상)
///   - 미가입 이메일 → 404 + `A04-007` → "회원가입 하러가기" 인라인 안내 카드
///   - 소셜 가입자 → 409 + `A04-006` → "로그인 화면으로 돌아가기" 인라인 안내 카드
///
/// 두 케이스 모두 "이 화면에서 해결 불가, 다른 흐름으로 가야 함" 이라 인라인 안내 카드로
/// 표시한다(다이얼로그 아님). 이메일을 다시 입력하기 시작하면 카드는 자동 해제 — 오타
/// 정정 흐름이 끊기지 않게 한다.
class FindPasswordPage extends ConsumerStatefulWidget {
  const FindPasswordPage({super.key});

  /// 소셜(Google/Kakao/Apple) 로 가입된 이메일이 비밀번호 재설정을 요청했을 때
  /// 서버가 내려주는 비즈니스 에러 코드.
  static const _socialAccountCode = 'A04-006';

  /// 가입되지 않은 이메일로 비밀번호 재설정을 요청했을 때 코드.
  static const _unregisteredEmailCode = 'A04-007';

  /// 서버 OTP 규격 — 6자리 숫자.
  static const _codeLength = 6;

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

  /// 서버 응답 에러 메시지 (인라인 표시용).
  String? _serverError;

  /// "이 화면에서 해결 불가" 안내 카드의 종류. 일반 에러(_serverError) 와 달리
  /// 사용자에게 다른 흐름으로의 액션 버튼을 제시한다.
  _Step1Notice _notice = _Step1Notice.none;

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(() {
      if (!_emailTouched) _emailTouched = true;
      // 새 입력 시 직전 서버 에러 / 안내 카드를 함께 정리. 사용자가 오타를 고치는
      // 흐름에서 이전 응답 잔여물이 그대로 남아 있으면 혼란스럽다.
      if (_serverError != null) _serverError = null;
      if (_notice != _Step1Notice.none) _notice = _Step1Notice.none;
      setState(() {});
    });
    _codeCtrl.addListener(() {
      if (!_codeTouched) _codeTouched = true;
      if (_serverError != null) _serverError = null;
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
    if (_step == 1 && _serverError != null) return _serverError;
    if (!_emailTouched) return null;
    final v = _emailCtrl.text.trim();
    if (v.isEmpty) return '이메일을 입력해주세요';
    if (!isValidEmail(v)) return '올바른 이메일 형식이 아닙니다';
    return null;
  }

  String? get _codeError {
    if (_step == 2 && _serverError != null) return _serverError;
    if (!_codeTouched) return null;
    final v = _codeCtrl.text.trim();
    if (v.isEmpty) return '인증번호를 입력해주세요';
    if (v.length != FindPasswordPage._codeLength) {
      return '인증번호 ${FindPasswordPage._codeLength}자리를 입력해주세요';
    }
    return null;
  }

  bool get _isStepValid {
    if (_step == 1) {
      return isValidEmail(_emailCtrl.text.trim());
    }
    return _codeCtrl.text.trim().length == FindPasswordPage._codeLength;
  }

  Future<void> _onButtonPressed(bool isLoading) async {
    if (isLoading) return;
    if (!_isStepValid) {
      setState(() {
        if (_step == 1) _emailTouched = true;
        if (_step == 2) _codeTouched = true;
      });
      return;
    }
    final notifier = ref.read(findPasswordViewModelProvider.notifier);
    if (_step == 1) {
      await notifier.sendCode(_emailCtrl.text.trim());
    } else {
      await notifier.verifyCode(_codeCtrl.text.trim());
    }
  }

  /// "이메일 다시 입력하기" — step 2 → step 1 회귀.
  /// 코드 입력값 / 코드 에러 / 서버 에러를 정리하고 ViewModel 도 idle 로 되돌린다.
  /// 이메일 컨트롤러는 유지해서 단순 수정 시 다시 타이핑하지 않아도 되게 함.
  void _backToStep1() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _step = 1;
      _codeCtrl.clear();
      _codeTouched = false;
      _serverError = null;
    });
    ref.read(findPasswordViewModelProvider.notifier).resetToIdle();
  }

  @override
  Widget build(BuildContext context) {
    // phase 전이 부수효과: step 전환 / 다음 페이지 이동 / 에러 메시지 노출.
    ref.listen<AsyncValue<FindPasswordPhase>>(findPasswordViewModelProvider,
        (prev, next) {
      next.whenOrNull(
        data: (phase) {
          if (!mounted) return;
          switch (phase) {
            case FindPasswordCodeSent _ when _step == 1:
              setState(() {
                _step = 2;
                _codeTouched = false;
                _serverError = null;
              });
            case FindPasswordVerified(:final resetToken):
              // pushReplacement — 토큰 1회용 + 검증 단계 재진입은 의미 없으므로
              // 현재 find 페이지를 reset 페이지로 교체. reset 의 뒤로가기는 자연스럽게
              // 로그인 화면으로 이어진다.
              context.pushReplacement(
                AppRoutes.resetPassword,
                extra: resetToken,
              );
            default:
              break;
          }
        },
        error: (e, _) {
          if (!mounted) return;
          // "다른 화면으로 가야 풀리는" 케이스는 인라인 안내 카드로 표시.
          // 사용자가 이메일을 다시 입력하기 시작하면 카드는 자동 해제된다.
          final code = e is ServerException ? e.code : null;
          if (code == FindPasswordPage._socialAccountCode) {
            setState(() {
              _serverError = null;
              _notice = _Step1Notice.socialAccount;
            });
            return;
          }
          if (code == FindPasswordPage._unregisteredEmailCode) {
            setState(() {
              _serverError = null;
              _notice = _Step1Notice.unregisteredEmail;
            });
            return;
          }
          setState(() => _serverError = mapErrorMessage(e));
        },
      );
    });

    final asyncState = ref.watch(findPasswordViewModelProvider);
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
                  // AutofillGroup — iOS Keychain / Android Autofill 이 한 폼 안에서
                  // 이메일/OTP 를 묶어 인식하도록.
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _step == 1
                          ? _buildStep1(context, colors, isLoading)
                          : _buildStep2(context, colors, isLoading),
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

  // ── Step 1: 이메일 입력 ─────────────────────────────────────────
  List<Widget> _buildStep1(
    BuildContext context,
    DoitdoColors colors,
    bool isLoading,
  ) {
    return [
      Text(
        '비밀번호를 잊으셨나요?',
        style: AppTextStyles.titleLarge.copyWith(
          color: colors.textPrimary,
          fontSize: 22.sp,
        ),
      ),
      SizedBox(height: 6.h),
      Text(
        '가입하신 이메일로 인증번호를 보내드려요',
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
        textInputAction: TextInputAction.done,
        enabled: !isLoading,
        errorText: _emailError,
        autofillHints: const [AutofillHints.email],
        onSubmitted: (_) => _onButtonPressed(isLoading),
      ),
      // 안내 카드 영역 + 메인 액션 버튼은 한 AnimatedSize 쌍으로 묶어 토글한다.
      // - 카드 ON  : 카드만 노출, 메인 버튼은 숨김. 카드 안 CTA 가 이 상황의 주 액션.
      // - 카드 OFF : 메인 버튼 노출. 카드는 SizedBox.shrink 로 자리만.
      // 사용자가 이메일을 다시 입력하면 _notice 가 none 으로 풀려 메인 버튼이 복귀.
      AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: _notice == _Step1Notice.none
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: _buildNoticeCard(),
              ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: _notice != _Step1Notice.none
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: EdgeInsets.only(top: 16.h),
                child: DoitdoPrimaryButton(
                  label: isLoading ? '발송 중...' : '인증번호 보내기',
                  onPressed:
                      isLoading ? null : () => _onButtonPressed(isLoading),
                ),
              ),
      ),
    ];
  }

  Widget _buildNoticeCard() {
    switch (_notice) {
      case _Step1Notice.socialAccount:
        return AuthInlineNotice(
          title: '소셜 로그인으로 가입된 계정이에요',
          message: '가입하신 소셜 서비스로 로그인해주세요.',
          ctaLabel: '로그인 화면으로 돌아가기',
          onCta: () => context.go(AppRoutes.welcome),
        );
      case _Step1Notice.unregisteredEmail:
        return AuthInlineNotice(
          title: '가입되지 않은 이메일이에요',
          message: '이메일을 다시 확인하거나 회원가입을 진행해주세요.',
          ctaLabel: '회원가입 하러가기',
          onCta: () => context.go(AppRoutes.register),
        );
      case _Step1Notice.none:
        // 도달 불가 — AnimatedSize 분기에서 이미 SizedBox.shrink 로 처리.
        return const SizedBox.shrink();
    }
  }

  // ── Step 2: 인증번호 입력 ───────────────────────────────────────
  List<Widget> _buildStep2(
    BuildContext context,
    DoitdoColors colors,
    bool isLoading,
  ) {
    final emailDisplay = _emailCtrl.text.trim();
    return [
      Text(
        '인증번호를 입력해주세요',
        style: AppTextStyles.titleLarge.copyWith(
          color: colors.textPrimary,
          fontSize: 22.sp,
        ),
      ),
      SizedBox(height: 6.h),
      // 어떤 이메일로 보냈는지 부제에 명시 — 사용자가 발송 대상을 확인할 수 있어야
      // "혹시 다른 이메일로 보냈나?" 하는 의심을 줄임.
      RichText(
        text: TextSpan(
          style: AppTextStyles.bodySmall.copyWith(
            color: colors.textSecondary,
            fontSize: 13.sp,
          ),
          children: [
            TextSpan(
              text: emailDisplay,
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.textPrimary,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            const TextSpan(text: ' 로 보낸 인증번호 '),
            TextSpan(
              text: '${FindPasswordPage._codeLength}자리',
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.textPrimary,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            const TextSpan(text: ' 를 입력해주세요'),
          ],
        ),
      ),
      SizedBox(height: 24.h),
      AuthTextField(
        controller: _codeCtrl,
        hint: '인증번호 ${FindPasswordPage._codeLength}자리',
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        enabled: !isLoading,
        errorText: _codeError,
        autofillHints: const [AutofillHints.oneTimeCode],
        maxLength: FindPasswordPage._codeLength,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onSubmitted: (_) => _onButtonPressed(isLoading),
      ),
      SizedBox(height: 16.h),
      DoitdoPrimaryButton(
        label: isLoading ? '확인 중...' : '다음',
        onPressed: isLoading ? null : () => _onButtonPressed(isLoading),
      ),
      SizedBox(height: 12.h),
      // 이메일을 잘못 적었거나 다른 계정으로 다시 시도하고 싶을 때.
      // 페이지 전체 pop (= 로그인 화면 복귀) 대신 step 1 으로 회귀해 흐름을 잇는다.
      Center(
        child: TextButton(
          onPressed: isLoading ? null : _backToStep1,
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            '이메일 다시 입력하기',
            style: AppTextStyles.labelMedium.copyWith(
              color: colors.textSecondary,
              fontSize: 13.sp,
              decoration: TextDecoration.underline,
              decorationColor: colors.textSecondary,
            ),
          ),
        ),
      ),
    ];
  }

}

/// Step 1 에서 표시할 인라인 안내 카드의 종류.
/// 일반 유효성 에러(_serverError) 와는 별개 — 안내 카드는 액션 버튼이 함께 붙고,
/// 이메일 재입력 시 자동으로 [_Step1Notice.none] 으로 정리된다.
enum _Step1Notice { none, socialAccount, unregisteredEmail }
