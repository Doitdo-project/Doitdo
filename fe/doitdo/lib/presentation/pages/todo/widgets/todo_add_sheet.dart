import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/models/todo.dart';
import 'package:doitdo/presentation/pages/setting/category/category_view_model.dart';
import 'package:doitdo/presentation/pages/todo/todo_add_notifier.dart';
import 'package:doitdo/presentation/pages/todo/todo_view_model.dart';
import 'package:doitdo/presentation/pages/todo/widgets/todo_category_sheet.dart';
import 'package:doitdo/presentation/pages/todo/widgets/todo_date_sheet.dart';
import 'package:doitdo/presentation/pages/todo/widgets/todo_time_sheet.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_primary_button.dart';

class TodoAddSheet extends ConsumerStatefulWidget {
  const TodoAddSheet({super.key, this.initialDate});
  final DateTime? initialDate;

  @override
  ConsumerState<TodoAddSheet> createState() => _TodoAddSheetState();
}

/// 시트 내부 단계.
/// 시트 위에 시트가 겹치는 대신 한 시트 안에서 view 만 전환하고
/// AnimatedSwitcher 가 단계별 전환을 부드럽게 처리한다.
enum _Step { main, datePicker, categoryPicker, alertPicker }

class _TodoAddSheetState extends ConsumerState<TodoAddSheet> {
  final _titleController = TextEditingController();
  final _memoController  = TextEditingController();
  final _titleFocusNode  = FocusNode();

  _Step _step = _Step.main;

  TodoDateResult? _dateResult;
  String    _selectedCategory   = '공부';
  int?      _selectedCategoryId;
  TimeOfDay _selectedTime       = const TimeOfDay(hour: 12, minute: 0);
  bool      _alarmEnabled       = false;
  bool      _isLoading          = false; // ✅ 연타 중복 저장 방지

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _dateResult = TodoDateResult(type: TodoDateType.normal, date: widget.initialDate!);
    } else {
      _dateResult = const TodoDateResult(type: TodoDateType.someday);
    }
  }

  /// 단계 전환 — 키보드 닫고 setState.
  void _goToStep(_Step next) {
    FocusScope.of(context).unfocus();
    setState(() => _step = next);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    final period = h < 12 ? '오전' : '오후';
    final display = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$period $display:$m';
  }

  Future<void> _onSave(BuildContext context) async {
    // ✅ 저장 중이면 즉시 차단 — 연타 중복 생성 방지
    if (_isLoading) return;

    final title = _titleController.text.trim();

    if (title.isEmpty) {
      _titleFocusNode.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('할 일을 입력해주세요.',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
          backgroundColor: AppColors.calendarPoint,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // ✅ 저장 시작 — 버튼 비활성화
    setState(() => _isLoading = true);

    try {
      final r = _dateResult;
      final todo = Todo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        category: TodoCategory.fromName(_selectedCategory),
        categoryId: _selectedCategoryId,
        isDone: false,
        memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
        alarmTime:       _alarmEnabled ? _selectedTime : null,
        alarmEnabled:    _alarmEnabled,
        dateType:        r?.type ?? TodoDateType.someday,
        date:            r?.date,
        rangeStart:      r?.rangeStart,
        rangeEnd:        r?.rangeEnd,
        repeatType:      r?.repeatType,
        repeatStartDate: r?.repeatStartDate,
        repeatEndDate:   r?.repeatEndDate,
        period:          r?.repeatType == '매주' ? 7 : null,
        repeatDays:      r?.repeatDays,
      );

      await ref.read(todoAddNotifierProvider.notifier).createTodo(todo);

      final resultState = ref.read(todoAddNotifierProvider);
      if (resultState.hasError) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('서버 저장 실패: ${resultState.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // ✅ 노티파이어 내부에서 fetchTodos/fetchCalendarData 가 실행됨.
      // 구버전 노티파이어 대비 안전망으로 한 번 더 호출.
      if (context.mounted) {
        try {
          final vm = ref.read(todoViewModelProvider.notifier);
          await vm.fetchTodos();
          await vm.fetchCalendarData();
        } catch (_) {
          // 갱신 실패해도 닫기는 진행
        }
      }

      // ✅ mounted 확인 후 딱 한 번만 pop
      if (context.mounted) Navigator.of(context).pop();

    } finally {
      // ✅ 성공/실패/예외 무관하게 항상 로딩 해제
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // 시트 높이를 화면의 75% 로 고정 — 단계 전환 때 시트 자체가 출렁이는 걸 막는다.
    // 각 단계는 자체적으로 [헤더(마스코트) / Expanded(본문) / 하단 버튼] 패턴을 갖는다.
    final fixedHeight = MediaQuery.of(context).size.height * 0.75;

    return Padding(
      padding:
      EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        height: fixedHeight,
        padding: const EdgeInsets.only(top: 12),
        // SafeArea(minimum) 으로 시스템 네비게이션 / 홈 인디케이터와의 시각 간격 보장.
        // 호출부의 useSafeArea 가 꺼져 있더라도 동일한 버퍼를 확보한다.
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // drag handle — 단계와 무관하게 항상 노출.
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 단계 전환 — 시트 크기는 fixedHeight 로 고정.
              // 각 단계 자체가 [상단 anchor / Expanded body / 하단 anchor] 구조라
              // AnimatedSize 는 쓰지 않는다 (Expanded 와 충돌).
              // StackFit.expand 로 각 단계가 시트 잔여 높이를 그대로 받게 한다.
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  layoutBuilder: (current, previous) => Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.center,
                    children: [
                      ...previous,
                      if (current != null) current,
                    ],
                  ),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: _buildStep(c),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(DoitdoColors c) {
    switch (_step) {
      case _Step.main:
        return KeyedSubtree(
          key: const ValueKey('main'),
          child: _buildMainForm(c),
        );
      case _Step.datePicker:
        return KeyedSubtree(
          key: const ValueKey('date'),
          child: TodoDateSheet(
            initialDate: _dateResult?.date ?? DateTime.now(),
            initialResult: _dateResult,
            embedded: true,
            onConfirm: (result) {
              setState(() {
                _dateResult = result;
                _step = _Step.main;
              });
            },
            onBack: () => _goToStep(_Step.main),
          ),
        );
      case _Step.categoryPicker:
        return KeyedSubtree(
          key: const ValueKey('category'),
          child: TodoCategorySheet(
            selectedCategory: _selectedCategory,
            embedded: true,
            onConfirm: (result) {
              setState(() {
                _selectedCategory   = result.categoryName;
                _selectedCategoryId = result.categoryId;
                _step = _Step.main;
              });
            },
            onBack: () => _goToStep(_Step.main),
          ),
        );
      case _Step.alertPicker:
        return KeyedSubtree(
          key: const ValueKey('alert'),
          child: TodoTimeSheet(
            initialTime:    _selectedTime,
            initialEnabled: _alarmEnabled,
            embedded: true,
            onConfirm: (result) {
              setState(() {
                _selectedTime = result.time;
                _alarmEnabled = result.enabled;
                _step = _Step.main;
              });
            },
            onBack: () => _goToStep(_Step.main),
          ),
        );
    }
  }

  Widget _buildMainForm(DoitdoColors c) {
    // 동적 카테고리 색상 — 메인 폼에서만 필요.
    final categories = ref.watch(categoryViewModelProvider).valueOrNull ?? [];
    Color getCategoryColor(String name) {
      try {
        return categories.firstWhere((cat) => cat.categoryName == name).color;
      } catch (_) {
        return AppColors.calendarPoint;
      }
    }


    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 상단 anchor: 마스코트 + 제목 입력
          _MascotBubble(
            message: widget.initialDate == null
                ? '언젠가 하고 싶은 일은?'
                : '이날 어떤 일을 계획해볼까?',
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: TextField(
              controller: _titleController,
              focusNode:  _titleFocusNode,
              maxLength: 20,
              style: AppTextStyles.titleLarge.copyWith(
                fontFamily: 'GmarketSansMedium',
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '할 일을 입력해주세요.',
                hintStyle: AppTextStyles.titleLarge.copyWith(
                  fontFamily: 'GmarketSansMedium',
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFD6D3D1),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                counterStyle: AppTextStyles.labelSmall.copyWith(
                  color: c.textHint,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── 본문: 옵션들 + 메모. 키보드 올라와도 스크롤 가능.
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 기간 — step 전환
                  GestureDetector(
                    onTap: () => _goToStep(_Step.datePicker),
                    child: _OptionRow(
                      icon: Icons.calendar_today_outlined,
                      label: '기간',
                      valueText: _dateResult?.displayText ?? '미지정',
                      colors: c,
                    ),
                  ),
                  Divider(color: c.divider, height: 1, thickness: 1),

                  // 카테고리 — step 전환
                  GestureDetector(
                    onTap: () => _goToStep(_Step.categoryPicker),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 20, 0, 20),
                      child: Row(
                        children: [
                          const Icon(Icons.category_outlined,
                              size: 18, color: Color(0xFFC8966E)),
                          const SizedBox(width: 12),
                          Text('카테고리',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: c.textSecondary)),
                          const Spacer(),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: getCategoryColor(_selectedCategory),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(_selectedCategory,
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: c.textPrimary)),
                          const SizedBox(width: 2),
                          Icon(Icons.chevron_right, size: 16, color: c.textHint),
                        ],
                      ),
                    ),
                  ),

                  // 알림 — step 전환
                  GestureDetector(
                    onTap: () => _goToStep(_Step.alertPicker),
                    child: _OptionRow(
                      icon: Icons.notifications_outlined,
                      label: '알림',
                      valueText: _alarmEnabled ? _formatTime(_selectedTime) : '없음',
                      colors: c,
                    ),
                  ),
                  Divider(color: c.divider, height: 1, thickness: 1),

                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: TextField(
                      controller: _memoController,
                      minLines: 4,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: AppTextStyles.bodyMedium.copyWith(color: c.textPrimary),
                      decoration: InputDecoration(
                        hintText: '메모를 입력해 보세요.',
                        hintStyle: AppTextStyles.bodyMedium
                            .copyWith(color: c.textHint),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 하단 anchor: 저장 버튼 ────────────────────
          // 저장 중에는 onPressed=null 로 disable + 라벨 변경.
          const SizedBox(height: 12),
          // ✅ _isLoading 상태에 따라 버튼 비활성화 + 라벨 변경
          DoitdoPrimaryButton(
            height: 48,
            label: _isLoading ? '저장 중...' : '저장하기',
            onPressed: _isLoading ? null : () => _onSave(context),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.label,
    required this.valueText,
    required this.colors,
  });
  final IconData icon;
  final String label;
  final String valueText;
  final DoitdoColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 0, 20),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFC8966E)),
          const SizedBox(width: 12),
          Text(label,
              style: AppTextStyles.bodyMedium.copyWith(color: colors.textSecondary)),
          const Spacer(),
          Text(valueText,
              style: AppTextStyles.bodyMedium.copyWith(color: colors.textPrimary)),
          const SizedBox(width: 2),
          Icon(Icons.chevron_right, size: 16, color: colors.textHint),
        ],
      ),
    );
  }
}

class _MascotBubble extends StatelessWidget {
  const _MascotBubble({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset('assets/images/Dooit.png', width: 36, height: 36),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: AppColors.bubbleBg,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Text(
            message,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.calendarDateText),
          ),
        ),
      ],
    );
  }
}