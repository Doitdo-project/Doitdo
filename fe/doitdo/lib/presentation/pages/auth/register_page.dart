import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/core/utils/error_message_mapper.dart';
import 'package:doitdo/domain/entities/user.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/pages/auth/register_view_model.dart';
import 'package:doitdo/presentation/pages/auth/widgets/auth_text_field.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_primary_button.dart';

/// 회원가입 화면.
///
/// UX 포인트:
/// - 사용자가 필드에 처음 "터치/입력" 하기 전까지는 에러를 띄우지 않는다 (_touched).
/// - 비밀번호 규칙(8자 이상)은 헬퍼 텍스트로 상시 안내.
/// - 비밀번호 확인 필드는 일치 시 초록 체크 아이콘을 보여준다.
/// - 폼 전체가 유효하지 않으면 "회원가입 완료" 버튼은 회색으로 비활성화.
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

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
    // 서버 중복체크 결과가 false 이면 에러 노출. 로딩/에러 상태는 에러로 표시하지 않음.
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
    // 중복체크 서버 결과 — 명시적으로 "사용 가능(true)" 이 확인돼야 제출 허용.
    if (ref.read(emailAvailabilityProvider).valueOrNull != true) return false;
    if (ref.read(usernameAvailabilityProvider).valueOrNull != true) return false;
    return true;
  }

  void _submit() {
    // 버튼은 항상 활성화돼 있지만, 제출 시점에 유효성 검증.
    // 유효하지 않으면 각 필드에 에러 메시지가 이미 노출되므로 별도 스낵바 없이 return.
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
    final colors = context.colors;
    // 중복체크 결과도 구독해 "사용 가능" 체크 아이콘·에러 메시지가 실시간 갱신되게.
    ref.watch(emailAvailabilityProvider);
    ref.watch(usernameAvailabilityProvider);
    final registerState = ref.watch(registerViewModelProvider);

    // 회원가입 성공/실패 부수효과.
    // 자동 로그인은 하지 않고, 사용자가 직접 로그인 화면에서 입력하도록 돌려보낸다.
    ref.listen<AsyncValue<User?>>(registerViewModelProvider, (prev, next) {
      next.whenOrNull(
        data: (user) {
          if (user == null) return;
          if (!context.mounted) return;
          // 스택에 login 이 남아있을 테니 pop 으로 돌아가고, 없으면 go 로 대체.
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.login);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('가입이 완료됐어요. 방금 만든 계정으로 로그인해 주세요.'),
            ),
          );
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
                  // 비율 배치:
                  // - 타이틀: 화면 상단 ~1/3 지점 (상단 여백 25%)
                  // - 버튼: 화면 하단 ~1/3 지점 (필드 후 flexible gap)
                  // SingleChildScrollView 로 감싸서 작은 화면·키보드 상황에도 안전.
                  final h = constraints.maxHeight;
                  final topSpace = h * 0.22;
                  // 필드 이후 ~ 버튼 사이 공간. 최소 24dp.
                  final midGap = math.max(24.0, h * 0.04);
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
                          '회원가입',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: colors.textPrimary,
                            fontSize: 28,
                            fontFamily: 'GmarketSansMedium',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── 필드 4개 (아이디 → 이메일 → 비밀번호 → 확인) ──
                        // showSuccess: 서버 중복체크까지 "true(가능)" 확인된 경우만 초록 체크.
                        AuthTextField(
                          controller: _userIdCtrl,
                          hint: '아이디',
                          textInputAction: TextInputAction.next,
                          errorText: _userIdError,
                          showSuccess: _userIdError == null &&
                              _userIdCtrl.text.trim().length >= 4 &&
                              ref
                                      .read(usernameAvailabilityProvider)
                                      .valueOrNull ==
                                  true,
                        ),
                        const SizedBox(height: 4),
                        AuthTextField(
                          controller: _emailCtrl,
                          hint: '이메일',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          errorText: _emailError,
                          showSuccess: _emailError == null &&
                              _emailCtrl.text.trim().isNotEmpty &&
                              ref
                                      .read(emailAvailabilityProvider)
                                      .valueOrNull ==
                                  true,
                        ),
                        const SizedBox(height: 4),
                        AuthTextField(
                          controller: _passwordCtrl,
                          hint: '비밀번호',
                          obscureText: true,
                          textInputAction: TextInputAction.next,
                          errorText: _passwordError,
                        ),
                        const SizedBox(height: 4),
                        AuthTextField(
                          controller: _confirmCtrl,
                          hint: '비밀번호 확인',
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          errorText: _confirmError,
                          showSuccess: _passwordMatch,
                          onSubmitted: (_) => _submit(),
                        ),

                        SizedBox(height: midGap),

                        // ── 버튼 ──
                        DoitdoPrimaryButton(
                          label: registerState.isLoading
                              ? '가입 중…'
                              : '회원가입 완료',
                          height: 48,
                          onPressed: registerState.isLoading ? null : _submit,
                        ),
                        const SizedBox(height: 16),

                        // ── 로그인 화면으로 이동 ──
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
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward,
                                size: 14,
                                color: colors.textSecondary,
                              ),
                            ],
                          ),
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

// ────────────────────────────────────────────────────────────────
// [앱스토어 심사 대비 재사용] 약관 동의 체크박스.
//
// Apple App Store 5.1.1 / Google Play 정책상 회원가입 시 이용약관·개인정보
// 처리방침 동의 UI가 실질적으로 필수다. 배포 심사 직전 아래 클래스 주석을
// 해제하고 _RegisterPageState 에 _agreed 상태 + 완료 버튼 분기를 다시 붙이면 된다.
//
// class _TermsCheckbox extends StatelessWidget {
//   const _TermsCheckbox({required this.value, required this.onChanged});
//
//   final bool value;
//   final ValueChanged<bool> onChanged;
//
//   @override
//   Widget build(BuildContext context) {
//     final colors = context.colors;
//     return InkWell(
//       onTap: () => onChanged(!value),
//       borderRadius: BorderRadius.circular(8),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 4),
//         child: Row(
//           children: [
//             SizedBox(
//               width: 22,
//               height: 22,
//               child: Checkbox(
//                 value: value,
//                 onChanged: (v) => onChanged(v ?? false),
//                 activeColor: colors.primary,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 side: BorderSide(color: colors.textHint),
//                 materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                 visualDensity: VisualDensity.compact,
//               ),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Wrap(
//                 crossAxisAlignment: WrapCrossAlignment.center,
//                 children: [
//                   Text('이용약관',
//                       style: AppTextStyles.labelMedium.copyWith(
//                         color: colors.textPrimary,
//                         decoration: TextDecoration.underline,
//                       )),
//                   Text(' 및 ',
//                       style: AppTextStyles.labelMedium.copyWith(
//                         color: colors.textSecondary,
//                       )),
//                   Text('개인정보 처리방침',
//                       style: AppTextStyles.labelMedium.copyWith(
//                         color: colors.textPrimary,
//                         decoration: TextDecoration.underline,
//                       )),
//                   Text('에 동의합니다',
//                       style: AppTextStyles.labelMedium.copyWith(
//                         color: colors.textSecondary,
//                       )),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
