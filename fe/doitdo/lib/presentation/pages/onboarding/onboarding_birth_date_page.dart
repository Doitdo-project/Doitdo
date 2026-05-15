import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/app_theme.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/core/utils/error_message_mapper.dart';
import 'package:doitdo/domain/entities/user.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_primary_button.dart';
import 'package:doitdo/presentation/pages/onboarding/onboarding_view_model.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';

/// 첫 로그인 시 노출되는 온보딩 1단계 — 생년월일 입력.
///
/// 디자인 원칙(토스 / 카카오뱅크 / 무신사 등 한국 최신 앱 표준):
///   - 사용자가 8자리 (YYYYMMDD) 를 키보드로 직접 입력
///   - 입력값은 큰 타이포(32sp) 로 "YYYY.MM.DD" 자동 포맷되어 표시
///   - YYYY / MM / DD 가이드 라벨이 입력 칸 아래에 살짝 들어감
///   - 부적절한 값(미래 / 1900 이전 / 존재하지 않는 날짜) 은 인라인 에러로 안내
///   - 전체 8자리가 채워지고 유효해야만 "다음" 버튼이 활성화
class OnboardingBirthDatePage extends ConsumerStatefulWidget {
  const OnboardingBirthDatePage({super.key});

  @override
  ConsumerState<OnboardingBirthDatePage> createState() =>
      _OnboardingBirthDatePageState();
}

class _OnboardingBirthDatePageState
    extends ConsumerState<OnboardingBirthDatePage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  // 사용자가 한 번이라도 입력하기 전까지는 에러를 띄우지 않는다.
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 자동으로 키보드를 띄워 첫 인터랙션을 줄인다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
    _controller.addListener(() {
      if (!_touched && _controller.text.isNotEmpty) _touched = true;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 입력값(`YYYY.MM.DD` 또는 `YYYYMMDD`) 을 [DateTime] 으로 안전 변환.
  ///
  /// 반환 null 의 의미: 형식 자체가 안 됐거나 (예: 13월), 미래 / 1900년 이전 등
  /// 비현실적인 값. UI 에서 이 결과로 활성/비활성 + 에러 메시지 분기.
  DateTime? _parseDate(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return null;
    final y = int.tryParse(digits.substring(0, 4));
    final m = int.tryParse(digits.substring(4, 6));
    final d = int.tryParse(digits.substring(6, 8));
    if (y == null || m == null || d == null) return null;
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    final date = DateTime(y, m, d);
    // DateTime 은 1995-02-30 같은 입력을 1995-03-02 로 묵묵히 보정하므로
    // 결과를 다시 필드 단위로 비교해 "실제 달력에 존재하는 날짜" 인지 검증한다.
    if (date.year != y || date.month != m || date.day != d) return null;
    if (y < 1900) return null;
    if (date.isAfter(DateTime.now())) return null;
    return date;
  }

  String? get _errorMessage {
    if (!_touched) return null;
    final raw = _controller.text;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (digits.length < 8) return null; // 입력 중에는 에러 띄우지 않음.
    if (_parseDate(raw) == null) {
      return '올바른 생년월일을 입력해주세요.';
    }
    return null;
  }

  bool get _canSubmit {
    final raw = _controller.text;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return false;
    return _parseDate(raw) != null;
  }

  void _submit() {
    final date = _parseDate(_controller.text);
    if (date == null) return;
    HapticFeedback.lightImpact();
    FocusManager.instance.primaryFocus?.unfocus();
    ref.read(onboardingBirthDateViewModelProvider.notifier).submit(date);
  }

  Future<void> _handleUnderage() async {
    // 만 14세 미만 — 서버가 이미 계정을 hard delete 함. 클라이언트는 토큰만 정리하고
    // 처음 화면(Welcome) 으로 돌려보낸다.
    await ref.read(authRepositoryProvider).signOut();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: const Text('가입할 수 없어요'),
        content: const Text(
          '두잇뚜는 만 14세 이상부터 이용할 수 있어요.\n안전을 위해 입력하신 정보는 모두 삭제했어요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    context.go(AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light,
      child: Consumer(builder: (context, ref, _) => _buildBody(context, ref)),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    ref.listen<AsyncValue<User?>>(onboardingBirthDateViewModelProvider,
        (prev, next) {
      next.whenOrNull(
        data: (user) {
          if (user == null) return;
          if (!mounted) return;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            context.go(AppRoutes.onboardingAgreements);
          });
        },
        error: (error, _) {
          if (!mounted) return;
          if (OnboardingBirthDateViewModel.isUnderageError(error)) {
            _handleUnderage();
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(mapErrorMessage(error))),
          );
        },
      );
    });

    final state = ref.watch(onboardingBirthDateViewModelProvider);
    final isLoading = state.isLoading;
    final error = _errorMessage;
    final hasInput = _controller.text.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EC),
      // 키보드가 올라오면 본문이 살짝 눌리며 CTA 가 키보드 위에 붙도록.
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 18.h, 24.w, 0),
              child: const _OnboardingProgress(step: 1, total: 2),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 32.h),
                    Text(
                      '생년월일을\n알려주세요',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: colors.textPrimary,
                        fontSize: 26.sp,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '맞춤 콘텐츠 추천에 사용돼요.\n만 14세 미만은 서비스를 이용할 수 없어요.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.textSecondary,
                        fontSize: 13.sp,
                        height: 1.5,
                      ),
                    ),

                    SizedBox(height: 56.h),

                    // ── 입력 표시(큰 타이포) ──
                    // 보이는 건 큰 포맷 텍스트필드 하나. 사용자는 8자리 숫자를 입력하고,
                    // formatter 가 4자리·2자리 사이에 점을 자동으로 넣어 "1995.03.15" 형태로 표시.
                    _BirthDateField(
                      controller: _controller,
                      focusNode: _focusNode,
                      hasError: error != null,
                      onSubmitted: _canSubmit ? _submit : null,
                    ),

                    SizedBox(height: 10.h),

                    // 에러 / 가이드 텍스트 — 영역을 항상 차지해서 레이아웃이 안 흔들리게.
                    SizedBox(
                      height: 18.h,
                      child: error != null
                          ? Text(
                              error,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: const Color(0xFFE04040),
                                fontSize: 12.sp,
                              ),
                            )
                          : Text(
                              hasInput ? '예) 1995.03.15' : '숫자 8자리를 입력해주세요',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: colors.textHint,
                                fontSize: 12.sp,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // ── CTA ──
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 16.h),
              child: DoitdoPrimaryButton(
                label: isLoading ? '저장 중…' : '다음',
                onPressed: (_canSubmit && !isLoading) ? _submit : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 입력 필드 + 포맷터

/// 큰 타이포로 보이는 생년월일 입력 필드.
///
/// 토스/카카오뱅크 스타일 — 한 줄 밑줄형. 입력값을 그대로 보여주되 4·2·2 사이에
/// `.` 가 자동으로 끼워져 "YYYY.MM.DD" 처럼 보인다.
class _BirthDateField extends StatelessWidget {
  const _BirthDateField({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent =
        hasError ? const Color(0xFFE04040) : colors.textPrimary;
    final borderColor =
        hasError ? const Color(0xFFE04040) : colors.primary;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      cursorColor: colors.primary,
      style: AppTextStyles.titleLarge.copyWith(
        fontFamily: 'GmarketSansMedium',
        fontSize: 32.sp,
        color: accent,
        letterSpacing: 1.5,
        height: 1.1,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _BirthDateInputFormatter(),
      ],
      decoration: InputDecoration(
        isCollapsed: true,
        contentPadding: EdgeInsets.symmetric(vertical: 12.h),
        hintText: 'YYYY.MM.DD',
        hintStyle: AppTextStyles.titleLarge.copyWith(
          fontFamily: 'GmarketSansMedium',
          fontSize: 32.sp,
          color: colors.textHint.withValues(alpha: 0.5),
          letterSpacing: 1.5,
          height: 1.1,
        ),
        // 한 줄 밑줄. 포커스 시 brand orange, 에러 시 빨강.
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: const Color(0xFFE7DFCC),
            width: 1.4,
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: borderColor, width: 2),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE04040), width: 2),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE04040), width: 2),
        ),
      ),
      onSubmitted: (_) => onSubmitted?.call(),
    );
  }
}

/// 8자리 숫자를 "YYYY.MM.DD" 로 자동 포맷.
///
/// `digitsOnly` 와 함께 써야 안정적이다 (한글 IME 등으로 들어오는 비숫자를 미리 거름).
/// 사용자가 백스페이스로 점을 지워도 자연스럽게 동작하도록 항상 digit 만 추출 → 다시
/// 포맷하는 방식으로 처리.
class _BirthDateInputFormatter extends TextInputFormatter {
  static const int _maxDigits = 8;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > _maxDigits) {
      // 9자리 이상 들어오는 경우 (붙여넣기 등) 8자리로 잘라낸다.
      return _format(digits.substring(0, _maxDigits));
    }
    return _format(digits);
  }

  TextEditingValue _format(String digits) {
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 4 || i == 6) buffer.write('.');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────

/// 단계 진행 바 (라이트 그레이 베이스 + 활성 단계는 brand orange).
class _OnboardingProgress extends StatelessWidget {
  const _OnboardingProgress({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: List.generate(total, (i) {
        final isActive = i < step;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 4.h,
              decoration: BoxDecoration(
                color: isActive ? colors.primary : const Color(0xFFE7DFCC),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        );
      }),
    );
  }
}
