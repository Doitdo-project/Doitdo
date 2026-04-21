import 'package:flutter/material.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';

/// 인증 화면(로그인·회원가입·비밀번호 찾기)에서 공통으로 쓰는 텍스트 필드.
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
  });

  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  /// 비어있지 않으면 에러 상태로 표시된다.
  final String? errorText;

  /// 에러가 없을 때 필드 아래 회색으로 표시되는 힌트 문구.
  final String? helperText;

  /// 유효값 입력 완료시 suffix 에 초록 체크 아이콘 노출.
  final bool showSuccess;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

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
        padding: EdgeInsets.only(right: 12),
        child: Icon(Icons.check_circle, color: Color(0xFF2EBD6B), size: 18),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      enabled: widget.enabled,
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
        fillColor: colors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFD64545) : colors.border,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: hasError ? const Color(0xFFD64545) : colors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD64545), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD64545), width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: _buildSuffixIcon(colors),
      ),
    );
  }
}
