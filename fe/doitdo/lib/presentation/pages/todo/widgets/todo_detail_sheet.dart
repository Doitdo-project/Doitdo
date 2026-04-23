import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/models/todo.dart';
import 'package:doitdo/presentation/pages/todo/todo_view_model.dart';
import 'package:doitdo/presentation/pages/todo/widgets/todo_category_sheet.dart';
import 'package:doitdo/presentation/pages/todo/widgets/todo_date_sheet.dart';
import 'package:doitdo/presentation/pages/todo/widgets/todo_time_sheet.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_dialog.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_primary_button.dart';

/// Todo 상세 바텀시트
class TodoDetailSheet extends ConsumerWidget {
  const TodoDetailSheet({
    super.key,
    required this.todoId,
    required this.isSomeday,
  });

  final String todoId;
  final bool isSomeday;

  static (Color, Color) _catColors(CategoryColorKey key) {
    switch (key) {
      case CategoryColorKey.health:
        return (AppColors.categoryHealth, Colors.white);
      case CategoryColorKey.study:
        return (AppColors.category1, AppColors.calendarDateText);
      case CategoryColorKey.exercise:
        return (AppColors.category2, AppColors.calendarDateText);
      case CategoryColorKey.work:
        return (AppColors.category3, AppColors.calendarDateText);
      case CategoryColorKey.hobby:
        return (AppColors.category5, AppColors.calendarDateText);
      case CategoryColorKey.etc:
        return (AppColors.chipUnselectedBg, AppColors.chipUnselectedText);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todoViewModelProvider);
    final list  = isSomeday ? state.somedayTodos : state.todos;
    final todo  = list.cast<Todo?>()
        .firstWhere((t) => t?.id == todoId, orElse: () => null);

    if (todo == null) {
      return const SizedBox.shrink();
    }

    final c              = context.colors;
    final vm             = ref.read(todoViewModelProvider.notifier);
    final (catBg, catFg) = _catColors(todo.category.colorKey);

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // add sheet 과 동일한 좌우 24 / 하단 32.
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 드래그 핸들 ──
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 32),

            // ── 헤더: 마스코트 말풍선 + 수정 버튼 ──
            Row(
              children: [
                Image.asset(
                  'assets/images/Dooit.png',
                  width: 36, height: 36,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.bubbleBg,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Text('할 일 상세',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.calendarDateText)),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      useRootNavigator: true,
                      builder: (_) => TodoEditSheet(
                        todo: todo,
                        isSomeday: isSomeday,
                      ),
                    );
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
                    child: Text(
                      '수정',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── 제목 ── add sheet 과 동일한 titleLarge(20) + Medium 가중치.
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                todo.title,
                style: AppTextStyles.titleLarge.copyWith(
                  fontFamily: 'GmarketSansMedium',
                  fontWeight: FontWeight.w500,
                  color: todo.isDone ? c.textHint : c.textPrimary,
                  decoration:
                  todo.isDone ? TextDecoration.lineThrough : null,
                  decorationColor: c.textHint,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── 기간 ──
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: '기간',
              value: todo.dateDisplayText,
            ),
            Divider(color: c.divider, height: 1, thickness: 1),

            // ── 카테고리 ──
            Padding(
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: catBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(todo.category.name,
                        style:
                        AppTextStyles.labelSmall.copyWith(color: catFg)),
                  ),
                ],
              ),
            ),

            // ── 알림 ── (카테고리 ↔ 알림 사이 divider 제거)
            _InfoRow(
              icon: Icons.notifications_outlined,
              label: '알림',
              value: todo.alarmDisplayText,
            ),
            Divider(color: c.divider, height: 1, thickness: 1),

            // ── 메모 (있을 때만) ──
            if (todo.memo != null && todo.memo!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('메모',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: c.textSecondary)),
                    const SizedBox(height: 8),
                    Text(todo.memo!,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: c.textPrimary)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // ── 버튼 ──
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final confirmed = await showDoitdoDialog(
                        context: context,
                        title: '할 일 삭제',
                        message: '정말 삭제하시겠어요?',
                        confirmLabel: '삭제',
                        cancelLabel: '취소',
                      );
                      if (confirmed == true && context.mounted) {
                        Navigator.of(context, rootNavigator: true).pop();
                        isSomeday
                            ? vm.deleteSomedayTodo(todo.id)
                            : vm.deleteTodo(todo.id);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.loginBtnOff,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      textStyle: AppTextStyles.bodyLarge,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('삭제'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DoitdoPrimaryButton(
                    label: todo.isDone ? '미완료로 변경' : '완료하기',
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      isSomeday
                          ? vm.toggleSomedayTodo(todo.id)
                          : vm.toggleTodo(todo.id);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Todo 수정 바텀시트
// ─────────────────────────────────────────────
class TodoEditSheet extends ConsumerStatefulWidget {
  const TodoEditSheet({
    super.key,
    required this.todo,
    required this.isSomeday,
  });

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
  late TimeOfDay _selectedTime;
  late bool      _alarmEnabled;
  late TodoDateResult _dateResult;

  @override
  void initState() {
    super.initState();
    final t = widget.todo;
    _titleController    = TextEditingController(text: t.title);
    _memoController     = TextEditingController(text: t.memo ?? '');
    _selectedCategory   = t.category.name;
    _selectedTime       = t.alarmTime ?? const TimeOfDay(hour: 12, minute: 0);
    _alarmEnabled       = t.alarmEnabled;
    _dateResult         = TodoDateResult(
      type:            t.dateType,
      date:            t.date,
      rangeStart:      t.rangeStart,
      rangeEnd:        t.rangeEnd,
      repeatType:      t.repeatType,
      repeatStartDate: t.repeatStartDate,
      repeatEndDate:   t.repeatEndDate,
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

  /// 카테고리 이름 → 점(dot) 색 매핑. add sheet 의 _dotColorOf 와 동일.
  Color _dotColorOf(String name) {
    switch (TodoCategory.fromName(name).colorKey) {
      case CategoryColorKey.study:    return AppColors.categoryDot1;
      case CategoryColorKey.exercise: return AppColors.categoryDot2;
      case CategoryColorKey.work:     return AppColors.categoryDot3;
      case CategoryColorKey.health:   return AppColors.categoryDot4;
      case CategoryColorKey.hobby:    return AppColors.categoryDot5;
      case CategoryColorKey.etc:      return AppColors.chipUnselectedBg;
    }
  }

  void _onSave(BuildContext context) {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _titleFocusNode.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('할 일을 입력해주세요.',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
          backgroundColor: AppColors.calendarPoint,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final r = _dateResult;
    final updated = widget.todo.copyWith(
      title:           title,
      category:        TodoCategory.fromName(_selectedCategory),
      memo:            _memoController.text.trim().isEmpty
          ? null
          : _memoController.text.trim(),
      alarmTime:       _alarmEnabled ? _selectedTime : null,
      alarmEnabled:    _alarmEnabled,
      dateType:        r.type,
      date:            r.date,
      rangeStart:      r.rangeStart,
      rangeEnd:        r.rangeEnd,
      repeatType:      r.repeatType,
      repeatStartDate: r.repeatStartDate,
      repeatEndDate:   r.repeatEndDate,
    );

    final vm = ref.read(todoViewModelProvider.notifier);
    widget.isSomeday
        ? vm.updateSomedayTodo(updated)
        : vm.updateTodo(updated);

    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        // add sheet 과 동일한 좌우 24 / 하단 32 / 상단 12(드래그 핸들 영역).
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 드래그 핸들
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: c.border,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 32),

              // 마스코트 말풍선
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/Dooit.png',
                    width: 36, height: 36,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.bubbleBg,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Text('어떻게 수정할까?',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.calendarDateText)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 할 일 입력 — add sheet 과 동일한 titleLarge(20) + Medium 가중치 + 힌트 #D6D3D1.
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: TextField(
                  controller: _titleController,
                  focusNode: _titleFocusNode,
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
                  ),
                ),
              ),
              // 타이틀 밑 divider 없이 공백만 (add sheet 과 동일).
              const SizedBox(height: 32),

              // 기간
              GestureDetector(
                onTap: () async {
                  final result = await showModalBottomSheet<TodoDateResult>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => TodoDateSheet(
                        initialDate: _dateResult.date ?? DateTime.now()),
                  );
                  if (result != null) setState(() => _dateResult = result);
                },
                child: _OptionRow(
                  icon: Icons.calendar_today_outlined,
                  label: '기간',
                  valueText: _dateResult.displayText,
                  colors: c,
                ),
              ),
              Divider(color: c.divider, height: 1, thickness: 1),

              // 카테고리 — 점 색은 선택된 카테고리 실제 색(categoryDot1~5) 동적 반영.
              GestureDetector(
                onTap: () async {
                  final result = await showModalBottomSheet<String>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => TodoCategorySheet(
                        selectedCategory: _selectedCategory),
                  );
                  if (result != null) {
                    setState(() => _selectedCategory = result);
                  }
                },
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
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                            color: _dotColorOf(_selectedCategory),
                            shape: BoxShape.circle),
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
              // 카테고리 ↔ 알림 사이 divider 없음 (add sheet 과 동일).

              // 알림
              GestureDetector(
                onTap: () async {
                  final result =
                  await showModalBottomSheet<TodoAlarmResult>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => TodoTimeSheet(
                      initialTime: _selectedTime,
                      initialEnabled: _alarmEnabled,
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _selectedTime = result.time;
                      _alarmEnabled = result.enabled;
                    });
                  }
                },
                child: _OptionRow(
                  icon: Icons.notifications_outlined,
                  label: '알림',
                  // off 일 때도 선택된 시간 미리보기 (add sheet 과 동일).
                  valueText: _formatTime(_selectedTime),
                  colors: c,
                ),
              ),
              Divider(color: c.divider, height: 1, thickness: 1),

              // 메모
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: TextField(
                  controller: _memoController,
                  minLines: 5,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style:
                  AppTextStyles.bodyMedium.copyWith(color: c.textPrimary),
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
              const SizedBox(height: 20),

              // 수정 완료 버튼
              DoitdoPrimaryButton(
                label: '수정 완료',
                onPressed: () => _onSave(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 공통 정보 행
// ─────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // add sheet 의 _OptionRow 와 동일한 스타일 — 좌측 8 오프셋, 상하 20, 아이콘 #C8966E.
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 0, 20),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFC8966E)),
          const SizedBox(width: 12),
          Text(label,
              style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary)),
          const Spacer(),
          Text(value,
              style:
              AppTextStyles.bodyMedium.copyWith(color: c.textPrimary)),
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
    // add sheet 의 _OptionRow 와 동일 — 좌측 8 오프셋, 상하 20, 아이콘 #C8966E.
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 0, 20),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFC8966E)),
          const SizedBox(width: 12),
          Text(label,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: colors.textSecondary)),
          const Spacer(),
          Text(valueText,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: colors.textPrimary)),
          const SizedBox(width: 2),
          Icon(Icons.chevron_right, size: 16, color: colors.textHint),
        ],
      ),
    );
  }
}