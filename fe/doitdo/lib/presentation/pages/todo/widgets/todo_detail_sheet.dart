import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/data/models/category_dto.dart';
import 'package:doitdo/presentation/models/todo.dart';
import 'package:doitdo/presentation/pages/setting/category/category_view_model.dart';
import 'package:doitdo/presentation/pages/todo/todo_view_model.dart';
import 'package:doitdo/presentation/pages/todo/widgets/todo_category_sheet.dart';
import 'package:doitdo/presentation/pages/todo/widgets/todo_date_sheet.dart';
import 'package:doitdo/presentation/pages/todo/widgets/todo_time_sheet.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_dialog.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_primary_button.dart';
import 'package:doitdo/presentation/pages/todo/todo_detail_provider.dart';

class TodoDetailSheet extends ConsumerWidget {
  const TodoDetailSheet({super.key, required this.todoId, required this.isSomeday});

  final String todoId;
  final bool isSomeday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final vm = ref.read(todoViewModelProvider.notifier);
    final detailAsync = ref.watch(todoDetailProvider(todoId));

    // ✅ 동적 카테고리 색상 찾기
    final categories = ref.watch(categoryViewModelProvider).valueOrNull ?? [];
    Color getCategoryColor(String name) {
      try {
        return categories.firstWhere((cat) => cat.categoryName == name).color;
      } catch (_) {
        return AppColors.category1; // 기본색
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: detailAsync.when(
        loading: () => const SizedBox(height: 300, child: Center(child: CircularProgressIndicator(color: AppColors.calendarPoint))),
        error: (err, stack) => SizedBox(height: 300, child: Center(child: Text('상세 정보를 불러오지 못했습니다.\n$err', style: AppTextStyles.bodyMedium))),
        data: (detailDto) {
          final catName = detailDto.category ?? '기타';
          final catKey = TodoCategory.fromName(catName);

          // ✅ 동적 색상 적용 — 배경 밝기에 따라 글자색 자동 결정
          final catBg = getCategoryColor(catName);
          final catFg = catBg.computeLuminance() > 0.4
              ? AppColors.calendarDateText  // 밝은 배경 → 어두운 글자
              : Colors.white;              // 어두운 배경 → 흰 글자

          final isDone = detailDto.status == 'DONE';
          final memo = detailDto.content;

          String dateDisplay = '미지정';
          if (detailDto.type == 'SOMEDAY') {
            dateDisplay = '언제가 할 일';
          } else if (detailDto.startDate != null) {
            final sParts = detailDto.startDate!.split('-');
            if (sParts.length == 3) {
              dateDisplay = '${int.parse(sParts[1])}월 ${int.parse(sParts[2])}일';
            } else {
              dateDisplay = detailDto.startDate!;
            }
            if (detailDto.endDate != null) {
              final eParts = detailDto.endDate!.split('-');
              if (eParts.length == 3) dateDisplay += ' ~ ${int.parse(eParts[1])}월 ${int.parse(eParts[2])}일';
            }
            if (detailDto.type == 'RECURRING') dateDisplay += ' 시작 (반복)';
          }

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 32),
                Row(
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
                      child: Text('할 일 상세', style: AppTextStyles.bodySmall.copyWith(color: AppColors.calendarDateText)),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        final sDate = detailDto.startDate != null ? DateTime.tryParse(detailDto.startDate!) : null;
                        List<int>? restoredDays;
                        if (detailDto.type == 'RECURRING') {
                          if (detailDto.daysOfWeek != null && detailDto.daysOfWeek!.isNotEmpty) {
                            const codeToIndex = {'SUN': 0, 'MON': 1, 'TUE': 2, 'WED': 3, 'THU': 4, 'FRI': 5, 'SAT': 6};
                            restoredDays = detailDto.daysOfWeek!.map((cd) => codeToIndex[cd.toUpperCase()]).whereType<int>().toList();
                          } else if (sDate != null) {
                            final fw = sDate.weekday;
                            restoredDays = [fw == 7 ? 0 : fw];
                          }
                        }

                        final todoToEdit = Todo(
                          id: detailDto.todoId.toString(),
                          title: detailDto.title,
                          isDone: isDone,
                          category: catKey,
                          categoryId: detailDto.categoryId,
                          memo: detailDto.content,
                          dateType: detailDto.type == 'PERIOD' ? TodoDateType.range
                              : (detailDto.type == 'RECURRING' ? TodoDateType.repeat
                              : (detailDto.type == 'SOMEDAY' ? TodoDateType.someday : TodoDateType.normal)),
                          date: sDate,
                          rangeEnd: detailDto.endDate != null ? DateTime.tryParse(detailDto.endDate!) : null,
                          alarmTime: detailDto.alarmTime != null ? TimeOfDay(
                              hour: int.parse(detailDto.alarmTime!.split(':')[0]), minute: int.parse(detailDto.alarmTime!.split(':')[1])
                          ) : null,
                          alarmEnabled: detailDto.alarmTime != null,
                          repeatStartDate: sDate,
                          repeatEndDate: detailDto.type == 'RECURRING' && detailDto.endDate != null ? DateTime.tryParse(detailDto.endDate!) : null,
                          repeatDays: restoredDays,
                        );

                        Navigator.of(context, rootNavigator: true).pop();
                        showModalBottomSheet(
                          context: context, isScrollControlled: true, backgroundColor: Colors.transparent, useRootNavigator: true,
                          builder: (_) => TodoEditSheet(todo: todoToEdit, isSomeday: isSomeday),
                        );
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
                        child: Text('수정', style: AppTextStyles.labelMedium.copyWith(color: c.textSecondary)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    detailDto.title,
                    style: AppTextStyles.titleLarge.copyWith(
                      fontFamily: 'GmarketSansMedium', fontWeight: FontWeight.w500, color: isDone ? c.textHint : c.textPrimary,
                      decoration: isDone ? TextDecoration.lineThrough : null, decorationColor: c.textHint,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _InfoRow(icon: Icons.calendar_today_outlined, label: '기간', value: dateDisplay),
                Divider(color: c.divider, height: 1, thickness: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 20, 0, 20),
                  child: Row(
                    children: [
                      const Icon(Icons.category_outlined, size: 18, color: Color(0xFFC8966E)),
                      const SizedBox(width: 12),
                      Text('카테고리', style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: catBg, borderRadius: BorderRadius.circular(6)),
                        child: Text(catName, style: AppTextStyles.labelSmall.copyWith(color: catFg)),
                      ),
                    ],
                  ),
                ),
                Divider(color: c.divider, height: 1, thickness: 1),
                _InfoRow(icon: Icons.notifications_outlined, label: '알림', value: detailDto.alarmTime ?? '없음'),
                Divider(color: c.divider, height: 1, thickness: 1),
                if (memo != null && memo.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('메모', style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary)),
                        const SizedBox(height: 8),
                        Text(memo, style: AppTextStyles.bodyMedium.copyWith(color: c.textPrimary)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final confirmed = await showDoitdoDialog(
                            context: context, title: '할 일 삭제', message: '정말 삭제하시겠어요?', confirmLabel: '삭제', cancelLabel: '취소',
                          );
                          if (confirmed == true && context.mounted) {
                            Navigator.of(context, rootNavigator: true).pop();
                            isSomeday ? vm.deleteSomedayTodo(todoId) : vm.deleteTodo(todoId);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.loginBtnOff, foregroundColor: Colors.white,
                          elevation: 0, shadowColor: Colors.transparent, textStyle: AppTextStyles.bodyLarge,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('삭제'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DoitdoPrimaryButton(
                        label: isDone ? '미완료로 변경' : '완료하기',
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).pop();
                          isSomeday ? vm.toggleSomedayTodo(todoId) : vm.toggleTodo(todoId);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class TodoEditSheet extends ConsumerStatefulWidget {
  const TodoEditSheet({super.key, required this.todo, required this.isSomeday});
  final Todo todo;
  final bool isSomeday;
  @override
  ConsumerState<TodoEditSheet> createState() => _TodoEditSheetState();
}

class _TodoEditSheetState extends ConsumerState<TodoEditSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _memoController;
  final _titleFocusNode = FocusNode();

  late String    _selectedCategory;
  int?           _selectedCategoryId;
  late TimeOfDay _selectedTime;
  late bool      _alarmEnabled;
  late TodoDateResult _dateResult;
  bool           _isLoading = false; // ✅ 연타 방지 플래그

  @override
  void initState() {
    super.initState();
    final t = widget.todo;
    _titleController    = TextEditingController(text: t.title);
    _memoController     = TextEditingController(text: t.memo ?? '');
    _selectedCategory   = t.category.name;
    _selectedCategoryId = t.categoryId;
    _selectedTime       = t.alarmTime ?? const TimeOfDay(hour: 12, minute: 0);
    _alarmEnabled       = t.alarmEnabled;
    _dateResult         = TodoDateResult(
      type: t.dateType, date: t.date, rangeStart: t.rangeStart, rangeEnd: t.rangeEnd,
      repeatType: t.repeatType, repeatStartDate: t.repeatStartDate, repeatEndDate: t.repeatEndDate, repeatDays: t.repeatDays,
    );
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
    // ✅ 연타 방지
    if (_isLoading) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _titleFocusNode.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('할 일을 입력해주세요.', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
          backgroundColor: AppColors.calendarPoint, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    // ✅ 수정 시작 — 버튼 비활성화
    setState(() => _isLoading = true);

    try {
      final r = _dateResult;
      final updated = widget.todo.copyWith(
        title:           title,
        category:        TodoCategory.fromName(_selectedCategory),
        categoryId:      _selectedCategoryId,
        memo:            _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
        alarmTime:       _alarmEnabled ? _selectedTime : null,
        alarmEnabled:    _alarmEnabled,
        dateType:        r.type,
        date:            r.date,
        rangeStart:      r.rangeStart,
        rangeEnd:        r.rangeEnd,
        repeatType:      r.repeatType,
        repeatStartDate: r.repeatStartDate,
        repeatEndDate:   r.repeatEndDate,
        repeatDays:      r.repeatDays,
      );

      final vm = ref.read(todoViewModelProvider.notifier);

      // ✅ await로 API 완료까지 대기
      widget.isSomeday
          ? await vm.updateSomedayTodo(updated)
          : await vm.updateTodo(updated);

      // ✅ 수정 후 목록 + 캘린더 재조회
      await vm.fetchTodos();
      await vm.fetchCalendarData();

      // ✅ 완료 후 딱 한 번만 pop
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수정 실패: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      // ✅ 성공/실패/예외 무관하게 항상 로딩 해제
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    // ✅ 동적 카테고리 색상
    final categories = ref.watch(categoryViewModelProvider).valueOrNull ?? [];
    Color getCategoryColor(String name) {
      try {
        return categories.firstWhere((cat) => cat.categoryName == name).color;
      } catch (_) {
        return AppColors.category1;
      }
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('assets/images/Dooit.png', width: 36, height: 36),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: const BoxDecoration(
                      color: AppColors.bubbleBg,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(12), bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                    ),
                    child: Text('어떻게 수정할까?', style: AppTextStyles.bodySmall.copyWith(color: AppColors.calendarDateText)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
                    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                    builder: (_) => TodoDateSheet(initialDate: _dateResult.date ?? DateTime.now(), initialResult: _dateResult),
                  );
                  if (result != null) setState(() => _dateResult = result);
                },
                child: _OptionRow(icon: Icons.calendar_today_outlined, label: '기간', valueText: _dateResult.displayText, colors: c),
              ),
              Divider(color: c.divider, height: 1, thickness: 1),
              GestureDetector(
                onTap: () async {
                  final result = await showModalBottomSheet<dynamic>(
                    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                    builder: (_) => TodoCategorySheet(selectedCategory: _selectedCategory),
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
                      // ✅ 동적 카테고리 색상 적용
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: getCategoryColor(_selectedCategory), shape: BoxShape.circle)),
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
                    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                    builder: (_) => TodoTimeSheet(initialTime: _selectedTime, initialEnabled: _alarmEnabled),
                  );
                  if (result != null) {
                    setState(() {
                      _selectedTime = result.time;
                      _alarmEnabled = result.enabled;
                    });
                  }
                },
                child: _OptionRow(icon: Icons.notifications_outlined, label: '알림', valueText: _formatTime(_selectedTime), colors: c),
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
              DoitdoPrimaryButton(
                label: _isLoading ? '수정 중...' : '수정 완료',
                onPressed: _isLoading ? null : () => _onSave(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 0, 20),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFC8966E)),
          const SizedBox(width: 12),
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary)),
          const Spacer(),
          Text(value, style: AppTextStyles.bodyMedium.copyWith(color: c.textPrimary)),
        ],
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