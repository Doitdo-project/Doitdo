import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';

/// 인증 화면(로그인·회원가입·비밀번호 찾기)에서 공통으로 쓰는 텍스트 필드.
///
/// 메인 앱 디자인 시스템(radius 12) 과 통일된 직사각형 채움 인풋. 따뜻한 베이지 톤
/// (#EFE8DC) 은 유지해 인증 화면의 크림 배경 위 대비를 보존한다.
///
/// 한글 입력은 자동으로 차단된다 — 인증 자격증명(아이디/이메일/비밀번호)에 한글이
/// 섞이면 서버/스토리지 호환성 문제가 생기고 OTP/이메일도 ASCII 기반이라 의미 없음.
/// 자모(ᄀ-ᇿ), 호환 자모(㄰-㆏, ㄱ-ㅎ ㅏ-ㅣ), 완성형(가-힣,
/// 가-힣) 모두 거른다. 직접 입력·붙여넣기 모두 차단.
///
/// - [obscureText] true 이면 비밀번호 표시/숨김 토글 아이콘이 자동으로 붙는다.
/// - [errorText] 비어있지 않으면 필드 아래 빨간 에러 메시지 표시 + 테두리 빨강.
/// - [helperText] 은 [errorText] 가 없을 때만 표시되는 보조 안내 문구.
/// - [showSuccess] true 면 suffix 에 초록 체크 아이콘을 보여준다 (비밀번호 일치 등).
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.enabled = true,
    this.errorText,
    this.helperText,
    this.showSuccess = false,
    this.autofillHints,
    this.maxLength,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  /// iOS Keychain / Android Autofill 통합용. 예: `[AutofillHints.password]`.
  /// OTP 화면이면 `[AutofillHints.oneTimeCode]`, 신규 비밀번호는 `newPassword`.
  /// AutofillGroup 으로 폼 전체를 감싸야 일부 제스처(저장 제안 등) 가 활성화된다.
  final Iterable<String>? autofillHints;

  /// 입력 최대 길이. OTP / 자릿수 고정 입력용. helper/error 자리에 카운터가 뜨지
  /// 않도록 [TextField.buildCounter] 를 빈 위젯으로 반환해 자동 카운터는 숨긴다.
  final int? maxLength;

  /// 입력 필터 — 예: `[FilteringTextInputFormatter.digitsOnly]`.
  final List<TextInputFormatter>? inputFormatters;

  /// 비어있지 않으면 에러 상태로 표시된다.
  final String? errorText;

  /// 에러가 없을 때 필드 아래 회색으로 표시되는 힌트 문구.
  final String? helperText;

  /// 유효값 입력 완료시 suffix 에 초록 체크 아이콘 노출.
  final bool showSuccess;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

/// 한글(자모·호환자모·완성형) 입력을 거르는 inputFormatter.
/// AuthTextField 가 내부적으로 무조건 prepend 한다.
final _denyKoreanFormatter = FilteringTextInputFormatter.deny(
  RegExp(r'[ᄀ-ᇿ㄰-㆏가-힣]'),
);

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  Widget? _buildSuffixIcon(DoitdoColors colors) {
    // 비밀번호 필드: 토글 + (선택적으로) 성공 체크를 함께 표시
    if (widget.obscureText) {
      final toggle = IconButton(
        icon: Icon(
          _obscure
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: colors.textHint,
          size: 20,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      );
      if (!widget.showSuccess) return toggle;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF2EBD6B), size: 18),
          toggle,
        ],
      );
    }
    // 일반 필드: 성공 체크 아이콘만
    if (widget.showSuccess) {
      return const Padding(
        padding: EdgeInsets.only(right: 16),
        child: Icon(Icons.check_circle, color: Color(0xFF2EBD6B), size: 18),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    // 라운드 12 채움 인풋(테두리 없음) — 메인 앱 디자인 시스템과 통일.
    // 채움 색은 인증 화면 크림 배경 위 대비 확보를 위해 한 톤 진한 베이지 유지.
    const radius = 12.0;
    const fillColor = Color(0xFFEFE8DC);
    const borderSide = BorderSide.none;
    const errorBorderSide = BorderSide(color: Color(0xFFD64545), width: 1);
    const focusedErrorBorderSide =
        BorderSide(color: Color(0xFFD64545), width: 1.2);

    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      enabled: widget.enabled,
      autofillHints: widget.autofillHints,
      maxLength: widget.maxLength,
      // maxLength 를 주면 기본 카운터("3/6")가 helperText 자리에 끼어들어
      // 레이아웃이 흔들린다. 카운터 자체는 OTP UX 에 가치가 적으므로 숨김.
      buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
          null,
      // 한글 차단을 무조건 최상위에 두고, 호출측이 추가로 준 formatter 는 그 뒤에.
      // 순서 중요 — 한글이 먼저 걸러진 뒤 도메인별 formatter(예: digitsOnly)가 동작.
      inputFormatters: [
        _denyKoreanFormatter,
        ...?widget.inputFormatters,
      ],
      style: AppTextStyles.bodyMedium.copyWith(color: colors.textPrimary),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: colors.textHint),
        errorText: hasError ? widget.errorText : null,
        errorStyle: AppTextStyles.labelMedium.copyWith(
          color: const Color(0xFFD64545),
        ),
        // 에러 없을 때도 공간을 예약해서 에러 등장 시 레이아웃이 튀지 않게 한다.
        // 사용자가 helperText 를 지정했으면 그대로, 아니면 공백 문자열로 높이만 예약.
        helperText: hasError ? null : (widget.helperText ?? ' '),
        helperStyle: AppTextStyles.labelMedium.copyWith(
          color: colors.textHint,
        ),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: borderSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: hasError
              ? const BorderSide(color: Color(0xFFD64545), width: 1)
              : borderSide,
        ),
        // 채움형이라 focus 시 별도 테두리는 보이지 않음 (에러 시에만 빨강 테두리).
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: hasError ? errorBorderSide : borderSide,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: errorBorderSide,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: focusedErrorBorderSide,
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        suffixIcon: _buildSuffixIcon(colors),
      ),
    );
  }
}
