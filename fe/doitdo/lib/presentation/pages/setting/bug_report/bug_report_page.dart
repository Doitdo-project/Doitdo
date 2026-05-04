import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/core/utils/error_message_mapper.dart';
import 'package:doitdo/presentation/pages/setting/bug_report/bug_report_view_model.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_primary_button.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_top_bar.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_scaffold.dart';

class BugReportPage extends ConsumerStatefulWidget {
  const BugReportPage({super.key});

  @override
  ConsumerState<BugReportPage> createState() => _BugReportPageState();
}

class _BugReportPageState extends ConsumerState<BugReportPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _titleFocus = FocusNode();
  final _contentFocus = FocusNode();

  static const _maxTitle = 100;
  static const _maxContent = 500;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
    _contentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _titleController.text.trim().isNotEmpty &&
      _contentController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    ref.listen<AsyncValue<bool>>(bugReportViewModelProvider, (_, next) {
      next.whenOrNull(
        error: (error, _) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(mapErrorMessage(error))),
          );
        },
      );
    });

    final asyncState = ref.watch(bugReportViewModelProvider);
    final isSubmitted = asyncState.valueOrNull == true;
    final isLoading = asyncState.isLoading;

    return DoitdoScaffold(
      topBar: const DoitdoTopBar(title: '문의하기'),
      body: isSubmitted
          ? _SuccessView(colors: colors)
          : _FormView(
              colors: colors,
              titleController: _titleController,
              contentController: _contentController,
              titleFocus: _titleFocus,
              contentFocus: _contentFocus,
              canSubmit: _canSubmit,
              isLoading: isLoading,
              onSubmit: _submit,
            ),
    );
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    ref.read(bugReportViewModelProvider.notifier).submit(
          title: _titleController.text,
          content: _contentController.text,
        );
  }
}

// ── 폼 뷰 ────────────────────────────────────────────────────────

class _FormView extends StatelessWidget {
  const _FormView({
    required this.colors,
    required this.titleController,
    required this.contentController,
    required this.titleFocus,
    required this.contentFocus,
    required this.canSubmit,
    required this.isLoading,
    required this.onSubmit,
  });

  final DoitdoColors colors;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final FocusNode titleFocus;
  final FocusNode contentFocus;
  final bool canSubmit;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 헤더 영역
                  Text(
                    '무엇이 불편하셨나요?',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    '불편한 점이나 오류를 알려주시면\n빠르게 확인하고 개선할게요.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colors.textSecondary,
                      height: 1.55,
                    ),
                  ),
                  SizedBox(height: 32.h),
                  // 제목 필드
                  _InputField(
                    controller: titleController,
                    focusNode: titleFocus,
                    hintText: '제목을 입력해 주세요',
                    maxLength: _BugReportPageState._maxTitle,
                    maxLines: 1,
                    colors: colors,
                    onSubmitted: (_) => contentFocus.requestFocus(),
                    textInputAction: TextInputAction.next,
                  ),
                  _Counter(
                    current: titleController.text.length,
                    max: _BugReportPageState._maxTitle,
                    colors: colors,
                  ),
                  SizedBox(height: 12.h),
                  // 내용 필드
                  _InputField(
                    controller: contentController,
                    focusNode: contentFocus,
                    hintText: '어떤 상황에서 문제가 생겼는지 알려주세요.\n(예: 화면, 버튼, 발생 순서 등)',
                    maxLength: _BugReportPageState._maxContent,
                    maxLines: 9,
                    minLines: 9,
                    colors: colors,
                    textInputAction: TextInputAction.newline,
                  ),
                  _Counter(
                    current: contentController.text.length,
                    max: _BugReportPageState._maxContent,
                    colors: colors,
                  ),
                ],
              ),
            ),
          ),
          _SubmitButton(
            canSubmit: canSubmit && !isLoading,
            onSubmit: onSubmit,
            colors: colors,
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.maxLength,
    required this.maxLines,
    required this.colors,
    this.minLines,
    this.onSubmitted,
    this.textInputAction,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final int maxLength;
  final int maxLines;
  final int? minLines;
  final DoitdoColors colors;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      maxLength: maxLength,
      maxLines: maxLines,
      minLines: minLines,
      onSubmitted: onSubmitted,
      textInputAction: textInputAction,
      style: AppTextStyles.bodyMedium.copyWith(color: colors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: colors.textHint,
          height: 1.55,
        ),
        counterText: '',
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        filled: true,
        fillColor: colors.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.current,
    required this.max,
    required this.colors,
  });

  final int current;
  final int max;
  final DoitdoColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 6.h),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          '$current/$max',
          style: AppTextStyles.bodySmall.copyWith(
            color: current >= max ? colors.primary : colors.textHint,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.canSubmit,
    required this.onSubmit,
    required this.colors,
  });

  final bool canSubmit;
  final VoidCallback onSubmit;
  final DoitdoColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 24.h),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.divider)),
      ),
      child: DoitdoPrimaryButton(
        label: '보내기',
        onPressed: canSubmit ? onSubmit : null,
      ),
    );
  }
}

// ── 성공 뷰 ──────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.colors});

  final DoitdoColors colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                color: colors.primary,
                size: 36.sp,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              '소중한 의견 감사해요',
              style: AppTextStyles.titleMedium.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10.h),
            Text(
              '문의 내용을 확인하고\n빠르게 답변드릴게요.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40.h),
            DoitdoPrimaryButton(
              label: '확인',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
