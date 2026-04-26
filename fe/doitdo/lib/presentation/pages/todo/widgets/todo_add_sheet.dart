import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/data/models/category_dto.dart';
import 'package:doitdo/presentation/models/todo.dart';
import 'package:doitdo/presentation/pages/setting/category/category_view_model.dart';
import 'package:doitdo/presentation/pages/todo/todo_view_model.dart';
import 'package:doitdo/presentation/pages/todo/todo_add_notifier.dart';
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

class _TodoAddSheetState extends ConsumerState<TodoAddSheet> {
  final _titleController = TextEditingController();
  final _memoController  = TextEditingController();
  final _titleFocusNode  = FocusNode();

  TodoDateResult? _dateResult;
  String    _selectedCategory = '공부';
  int?      _selectedCategoryId;
  TimeOfDay _selectedTime     = const TimeOfDay(hour: 12, minute: 0);
  bool      _alarmEnabled     = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _dateResult = TodoDateResult(type: TodoDateType.normal, date: widget.initialDate!);
    } else {
      _dateResult = const TodoDateResult(type: TodoDateType.someday);
    }
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
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      _titleFocusNode.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('할 일을 입력해주세요.', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
          backgroundColor: AppColors.calendarPoint, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16), duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

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
      period: r?.repeatType == '매주' ? 7 : null,
      repeatDays:      r?.repeatDays,
    );

    await ref.read(todoAddNotifierProvider.notifier).createTodo(todo);

    final resultState = ref.read(todoAddNotifierProvider);
    if (resultState.hasError) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('서버 저장 실패: ${resultState.error}'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final vm = ref.read(todoViewModelProvider.notifier);
    await vm.fetchTodos();
    await vm.fetchCalendarData();

    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    // 동적 카테고리 색상: 서버에서 받은 카테고리 목록에서 이름으로 색을 찾는다.
    final categories = ref.watch(categoryViewModelProvider).valueOrNull ?? [];
    Color getCategoryColor(String name) {
      try {
        return categories.firstWhere((cat) => cat.categoryName == name).color;
      } catch (_) {
        return AppColors.calendarPoint; // 기본색
      }
    }

    // SafeArea(top: false) 가 시스템 네비바(뒤로가기/홈/멀티태스킹) 영역의 높이를
    // padding 으로 더해줘서 시트 하단이 시스템바와 절대 겹치지 않게 한다.
    // 호출부의 showModalBottomSheet(useSafeArea: true) 가 MediaQuery.padding.bottom
    // 을 보존하기 때문에 가능. 키보드(viewInsets.bottom)는 별도 Padding 으로 처리.
    return SafeArea(
      top: false,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 32),
            _MascotBubble(message: widget.initialDate == null ? '언제가 하고 싶은 일은?' : '이날 어떤 일을 계획해볼까?'),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: TextField(
                controller: _titleController, focusNode: _titleFocusNode,
                style: AppTextStyles.titleLarge.copyWith(fontFamily: 'GmarketSansMedium', fontWeight: FontWeight.w500, color: c.textPrimary),
                decoration: InputDecoration(
                  hintText: '할 일을 입력해주세요.',
                  hintStyle: AppTextStyles.titleLarge.copyWith(fontFamily: 'GmarketSansMedium', fontWeight: FontWeight.w500, color: const Color(0xFFD6D3D1)),
                  border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 32),

            GestureDetector(
              onTap: () async {
                final result = await showModalBottomSheet<TodoDateResult>(
                  context: context, isScrollControlled: true, useSafeArea: true, backgroundColor: Colors.transparent,
                  builder: (_) => TodoDateSheet(initialDate: _dateResult?.date ?? DateTime.now(), initialResult: _dateResult),
                );
                if (result != null) setState(() => _dateResult = result);
              },
              child: _OptionRow(icon: Icons.calendar_today_outlined, label: '기간', valueText: _dateResult?.displayText ?? '미지정', colors: c),
            ),
            Divider(color: c.divider, height: 1, thickness: 1),

            GestureDetector(
              onTap: () async {
                final result = await showModalBottomSheet<dynamic>(
                  context: context, isScrollControlled: true, useSafeArea: true, backgroundColor: Colors.transparent,
                  builder: (_) => TodoCategorySheet(selectedCategory: _selectedCategory, embedded: false),
                );
                if (result != null && result is CategoryResp) {
                  setState(() {
                    _selectedCategory = result.categoryName;
                    _selectedCategoryId = result.categoryId;
                  });
                }
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 20, 0, 20),
                child: Row(
                  children: [
                    const Icon(Icons.category_outlined, size: 18, color: Color(0xFFC8966E)),
                    const SizedBox(width: 12),
                    Text('카테고리', style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary)),
                    const Spacer(),
                    Container(
                      width: 8, height: 8,
                      // ✅ 동적 카테고리 색상 적용
                      decoration: BoxDecoration(color: getCategoryColor(_selectedCategory), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(_selectedCategory, style: AppTextStyles.bodyMedium.copyWith(color: c.textPrimary)),
                    const SizedBox(width: 2),
                    Icon(Icons.chevron_right, size: 16, color: c.textHint),
                  ],
                ),
              ),
            ),

            GestureDetector(
              onTap: () async {
                final result = await showModalBottomSheet<TodoAlarmResult>(
                  context: context, isScrollControlled: true, useSafeArea: true, backgroundColor: Colors.transparent,
                  builder: (_) => TodoTimeSheet(initialTime: _selectedTime, initialEnabled: _alarmEnabled),
                );
                if (result != null) {
                  setState(() {
                    _selectedTime = result.time;
                    _alarmEnabled = result.enabled;
                  });
                }
              },
              child: _OptionRow(icon: Icons.notifications_outlined, label: '알림', valueText: _alarmEnabled ? _formatTime(_selectedTime) : '없음', colors: c),
            ),
            Divider(color: c.divider, height: 1, thickness: 1),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: TextField(
                controller: _memoController, minLines: 5, maxLines: null, keyboardType: TextInputType.multiline,
                style: AppTextStyles.bodyMedium.copyWith(color: c.textPrimary),
                decoration: InputDecoration(
                  hintText: '메모를 입력해 보세요.', hintStyle: AppTextStyles.bodyMedium.copyWith(color: c.textHint),
                  border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 20),

            DoitdoPrimaryButton(label: '저장하기', onPressed: () => _onSave(context)),
          ],
        ),
        ),
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.icon, required this.label, required this.valueText, required this.colors});
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
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: colors.textSecondary)),
          const Spacer(),
          Text(valueText, style: AppTextStyles.bodyMedium.copyWith(color: colors.textPrimary)),
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
              topLeft: Radius.circular(4), topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12),
            ),
          ),
          child: Text(message, style: AppTextStyles.bodySmall.copyWith(color: AppColors.calendarDateText)),
        ),
      ],
    );
  }
}