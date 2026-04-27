import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/app_theme.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/core/utils/error_message_mapper.dart';
import 'package:doitdo/domain/entities/user.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/pages/auth/register_view_model.dart';
import 'package:doitdo/presentation/pages/auth/widgets/auth_pill_button.dart';
import 'package:doitdo/presentation/pages/auth/widgets/auth_text_field.dart';
import 'package:doitdo/presentation/pages/auth/widgets/inline_back_bar.dart';

/// 회원가입 화면.
///
/// UX 포인트:
/// - 사용자가 필드에 처음 "터치/입력" 하기 전까지는 에러를 띄우지 않는다 (_touched).
/// - 비밀번호 규칙(8자 이상)은 헬퍼 텍스트로 상시 안내.
/// - 비밀번호 확인 필드는 일치 시 초록 체크 아이콘을 보여준다.
/// - 폼 전체가 유효하지 않으면 "회원가입 완료" 버튼은 회색으로 비활성화.
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  static const _bgColor = Color(0xFFF8F5EC);

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _emailCtrl = TextEditingController();
  final _userIdCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // 필드별 "사용자가 한 번이라도 상호작용했는지" 플래그.
  // true 가 된 후에만 에러 메시지를 노출한다.
  bool _emailTouched = false;
  bool _userIdTouched = false;
  bool _passwordTouched = false;
  bool _confirmTouched = false;

  // 중복체크 디바운스용 타이머. 사용자가 타이핑 멈추고 400ms 뒤 서버에 check 요청.
  // 타이핑 중에는 매 글자마다 호출하지 않음 — 네트워크/할당량 낭비 방지.
  Timer? _emailDebounce;
  Timer? _userIdDebounce;
  static const _debounceDelay = Duration(milliseconds: 400);

  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(_onEmailChanged);
    _userIdCtrl.addListener(_onUserIdChanged);
    _passwordCtrl.addListener(() {
      if (!_passwordTouched) _passwordTouched = true;
      setState(() {});
    });
    _confirmCtrl.addListener(() {
      if (!_confirmTouched) _confirmTouched = true;
      setState(() {});
    });
  }

  void _onEmailChanged() {
    if (!_emailTouched) _emailTouched = true;
    setState(() {});
    _emailDebounce?.cancel();
    final v = _emailCtrl.text.trim();
    // 형식 유효하지 않은 값은 서버에 보내지 않음 — 기존 check 결과만 초기화.
    if (v.isEmpty || !_emailRegex.hasMatch(v)) {
      ref.read(emailAvailabilityProvider.notifier).clear();
      return;
    }
    _emailDebounce = Timer(_debounceDelay, () {
      if (!mounted) return;
      ref.read(emailAvailabilityProvider.notifier).check(v);
    });
  }

  void _onUserIdChanged() {
    if (!_userIdTouched) _userIdTouched = true;
    setState(() {});
    _userIdDebounce?.cancel();
    final v = _userIdCtrl.text.trim();
    if (v.length < 4) {
      ref.read(usernameAvailabilityProvider.notifier).clear();
      return;
    }
    _userIdDebounce = Timer(_debounceDelay, () {
      if (!mounted) return;
      ref.read(usernameAvailabilityProvider.notifier).check(v);
    });
  }

  @override
  void dispose() {
    _emailDebounce?.cancel();
    _userIdDebounce?.cancel();
    _emailCtrl.dispose();
    _userIdCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ─── Validators ────────────────────────────────────────────────
  String? get _emailError {
    if (!_emailTouched) return null;
    final v = _emailCtrl.text.trim();
    if (v.isEmpty) return '이메일을 입력해주세요';
    if (!_emailRegex.hasMatch(v)) return '올바른 이메일 형식이 아닙니다';
    final avail = ref.read(emailAvailabilityProvider).valueOrNull;
    if (avail == false) return '이미 사용 중인 이메일입니다';
    return null;
  }

  String? get _userIdError {
    if (!_userIdTouched) return null;
    final v = _userIdCtrl.text.trim();
    if (v.isEmpty) return '아이디를 입력해주세요';
    if (v.length < 4) return '아이디는 4자 이상이어야 합니다';
    final avail = ref.read(usernameAvailabilityProvider).valueOrNull;
    if (avail == false) return '이미 사용 중인 아이디입니다';
    return null;
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

  bool get _isFormValid {
    if (_emailCtrl.text.trim().isEmpty) return false;
    if (!_emailRegex.hasMatch(_emailCtrl.text.trim())) return false;
    if (_userIdCtrl.text.trim().length < 4) return false;
    if (_passwordCtrl.text.length < 8) return false;
    if (_passwordCtrl.text != _confirmCtrl.text) return false;
    if (ref.read(emailAvailabilityProvider).valueOrNull != true) return false;
    if (ref.read(usernameAvailabilityProvider).valueOrNull != true) return false;
    return true;
  }

  void _submit() {
    if (!_isFormValid) {
      setState(() {
        _emailTouched = true;
        _userIdTouched = true;
        _passwordTouched = true;
        _confirmTouched = true;
      });
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    ref.read(registerViewModelProvider.notifier).submit(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          username: _userIdCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    // 인증 화면은 브랜드 크림 톤 일러스트 기반이라 themeMode 와 무관하게 라이트 강제.
    // Builder 대신 Consumer 를 써서 안쪽에서 ref.watch / ref.listen 이 정상 동작하도록.
    return Theme(
      data: AppTheme.light,
      child: Consumer(builder: (context, ref, _) => _buildBody(context, ref)),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    // 중복체크 결과도 구독해 "사용 가능" 체크 아이콘·에러 메시지가 실시간 갱신되게.
    ref.watch(emailAvailabilityProvider);
    ref.watch(usernameAvailabilityProvider);
    final registerState = ref.watch(registerViewModelProvider);

    // 회원가입 성공/실패 부수효과.
    // signUp 직후 자동 로그인까지 완료된 상태로 data 가 도착하므로 바로 메인 탭으로 이동.
    ref.listen<AsyncValue<User?>>(registerViewModelProvider, (prev, next) {
      next.whenOrNull(
        data: (user) {
          if (user == null) return;
          if (!context.mounted) return;
          context.go(AppRoutes.tamagochi);
        },
        error: (error, _) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(mapErrorMessage(error))),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: RegisterPage._bgColor,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Column(
            children: [
              const InlineBackBar(label: '회원가입'),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(28.w, 12.h, 28.w, 24.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '계정 만들기',
                        style: AppTextStyles.titleLarge.copyWith(
                          color: colors.textPrimary,
                          fontSize: 22.sp,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        '두잇두에서 사용할 정보를 입력해주세요',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colors.textSecondary,
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // ── 필드 4개 (아이디 → 이메일 → 비밀번호 → 확인) ──
                      AuthTextField(
                        controller: _userIdCtrl,
                        hint: '아이디 (4자 이상)',
                        textInputAction: TextInputAction.next,
                        errorText: _userIdError,
                        showSuccess: _userIdError == null &&
                            _userIdCtrl.text.trim().length >= 4 &&
                            ref
                                    .read(usernameAvailabilityProvider)
                                    .valueOrNull ==
                                true,
                      ),
                      AuthTextField(
                        controller: _emailCtrl,
                        hint: '이메일',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        errorText: _emailError,
                        showSuccess: _emailError == null &&
                            _emailCtrl.text.trim().isNotEmpty &&
                            ref.read(emailAvailabilityProvider).valueOrNull ==
                                true,
                      ),
                      AuthTextField(
                        controller: _passwordCtrl,
                        hint: '비밀번호 (8자 이상)',
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
                        label:
                            registerState.isLoading ? '가입 중…' : '회원가입 완료',
                        onPressed: registerState.isLoading ? null : _submit,
                      ),
                      SizedBox(height: 16.h),

                      GestureDetector(
                        onTap: () => context.pop(),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '로그인 화면으로 이동',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: colors.textSecondary,
                                fontSize: 13.sp,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.arrow_forward,
                              size: 14.sp,
                              color: colors.textSecondary,
                            ),
                          ],
                        ),
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

// ────────────────────────────────────────────────────────────────
// [앱스토어 심사 대비 재사용] 약관 동의 체크박스.
//
// Apple App Store 5.1.1 / Google Play 정책상 회원가입 시 이용약관·개인정보
// 처리방침 동의 UI가 실질적으로 필수다. 배포 심사 직전 아래 클래스 주석을
// 해제하고 _RegisterPageState 에 _agreed 상태 + 완료 버튼 분기를 다시 붙이면 된다.
//
// class _TermsCheckbox extends StatelessWidget {
//   const _TermsCheckbox({required this.value, required this.onChanged});
//   ... (이전 동일) ...
// }
