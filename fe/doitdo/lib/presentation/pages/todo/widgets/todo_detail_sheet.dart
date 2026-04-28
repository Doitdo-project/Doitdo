import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/models/todo.dart';
import 'package:doitdo/presentation/pages/setting/category/category_view_model.dart';
import 'package:doitdo/presentation/pages/todo/todo_view_model.dart';
import 'package:doitdo/presentation/pages/todo/widgets/todo_category_sheet.dart';
import 'package:doitdo/presentation/pages/todo/widgets/todo_date_sheet.dart';
import 'package:doitdo/presentation/pages/todo/widgets/todo_time_sheet.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_dialog.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_primary_button.dart';
import 'package:doitdo/data/models/todo_detail_response_dto.dart';
import 'package:doitdo/presentation/pages/todo/todo_detail_provider.dart';

// ── 단계 enum ───────────────────────────────────────────────────────────
enum _Step { view, edit, datePicker, categoryPicker, alertPicker }

class TodoDetailSheet extends ConsumerStatefulWidget {
  const TodoDetailSheet({super.key, required this.todoId, required this.isSomeday});

  final String todoId;
  final bool isSomeday;

  @override
  ConsumerState<TodoDetailSheet> createState() => _TodoDetailSheetState();
}

class _TodoDetailSheetState extends ConsumerState<TodoDetailSheet> {
  _Step _step = _Step.view;

  // 수정 모드 상태
  final _titleController = TextEditingController();
  final _memoController  = TextEditingController();
  final _titleFocusNode  = FocusNode();
  String    _selectedCategory   = '기타';
  int?      _selectedCategoryId;
  TimeOfDay _selectedTime       = const TimeOfDay(hour: 12, minute: 0);
  bool      _alarmEnabled       = false;
  TodoDateResult _dateResult    = const TodoDateResult(type: TodoDateType.someday);
  bool      _isLoading          = false;

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _goToStep(_Step next) {
    FocusScope.of(context).unfocus();
    setState(() => _step = next);
  }

  // detailDto 로부터 수정 모드 초기 상태 세팅
  void _initEditState(TodoDetailResponseDto detailDto) {
    _titleController.text = detailDto.title;
    _memoController.text  = detailDto.content ?? '';
    _selectedCategory     = detailDto.category ?? '기타';
    _selectedCategoryId   = detailDto.categoryId;

    if (detailDto.alarmTime != null) {
      final parts = detailDto.alarmTime!.split(':');
      _selectedTime = TimeOfDay(
        hour:   int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
      _alarmEnabled = true;
    } else {
      _selectedTime = const TimeOfDay(hour: 12, minute: 0);
      _alarmEnabled = false;
    }

    final sDate = detailDto.startDate != null ? DateTime.tryParse(detailDto.startDate!) : null;
    final eDate = detailDto.endDate   != null ? DateTime.tryParse(detailDto.endDate!)   : null;

    List<int>? restoredDays;
    if (detailDto.type == 'RECURRING') {
      if (detailDto.daysOfWeek != null && detailDto.daysOfWeek!.isNotEmpty) {
        const codeToIndex = {'SUN': 0, 'MON': 1, 'TUE': 2, 'WED': 3, 'THU': 4, 'FRI': 5, 'SAT': 6};
        restoredDays = (detailDto.daysOfWeek as List<String>)
            .map((cd) => codeToIndex[cd.toUpperCase()])
            .whereType<int>()
            .toList();
      } else if (sDate != null) {
        final fw = sDate.weekday;
        restoredDays = [fw == 7 ? 0 : fw];
      }
    }

    _dateResult = TodoDateResult(
      type: detailDto.type == 'PERIOD'
          ? TodoDateType.range
          : (detailDto.type == 'RECURRING'
              ? TodoDateType.repeat
              : (detailDto.type == 'SOMEDAY' ? TodoDateType.someday : TodoDateType.normal)),
      date:            sDate,
      rangeStart:      detailDto.type == 'PERIOD'    ? sDate : null,
      rangeEnd:        detailDto.type == 'PERIOD'    ? eDate : null,
      repeatStartDate: detailDto.type == 'RECURRING' ? sDate : null,
      repeatEndDate:   detailDto.type == 'RECURRING' ? eDate : null,
      repeatDays:      restoredDays,
    );
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    final period  = h < 12 ? '오전' : '오후';
    final display = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$period $display:$m';
  }

  Future<void> _onSave(BuildContext context, bool isDone) async {
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
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final vm = ref.read(todoViewModelProvider.notifier);

    try {
      final r = _dateResult;
      final updated = Todo(
        id:              widget.todoId,
        title:           title,
        category:        TodoCategory.fromName(_selectedCategory),
        categoryId:      _selectedCategoryId,
        isDone:          isDone,
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

      widget.isSomeday
          ? await vm.updateSomedayTodo(updated)
          : await vm.updateTodo(updated);

      await vm.fetchTodos();
      await vm.fetchCalendarData();

      if (mounted) {
        ref.invalidate(todoDetailProvider(widget.todoId));
        _goToStep(_Step.view);
      }
    } catch (e) {
      await vm.fetchTodos();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('수정에 실패했어요. 다시 시도해 주세요.',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c           = context.colors;
    final fixedHeight = MediaQuery.of(context).size.height * 0.75;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
      child: Container(
        decoration: BoxDecoration(
          color:        c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        height:  fixedHeight,
        padding: const EdgeInsets.only(top: 12),
        child: SafeArea(
          top:     false,
          minimum: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisSize:       MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // drag handle
            Center(
              child: Container(
                width:  40,
                height: 4,
                decoration: BoxDecoration(
                  color:        c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                layoutBuilder: (current, previous) => Stack(
                  fit:       StackFit.expand,
                  alignment: Alignment.center,
                  children:  [...previous, ?current],
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
      case _Step.view:
        return KeyedSubtree(key: const ValueKey('view'), child: _buildViewStep(c));
      case _Step.edit:
        return KeyedSubtree(key: const ValueKey('edit'), child: _buildEditStep(c));
      case _Step.datePicker:
        return KeyedSubtree(
          key:   const ValueKey('date'),
          child: TodoDateSheet(
            initialDate:   _dateResult.date ?? DateTime.now(),
            initialResult: _dateResult,
            embedded:      true,
            onConfirm: (result) => setState(() {
              _dateResult = result;
              _step       = _Step.edit;
            }),
            onBack: () => _goToStep(_Step.edit),
          ),
        );
      case _Step.categoryPicker:
        return KeyedSubtree(
          key:   const ValueKey('category'),
          child: TodoCategorySheet(
            selectedCategory: _selectedCategory,
            embedded:         true,
            onConfirm: (result) => setState(() {
              _selectedCategory   = result.categoryName;
              _selectedCategoryId = result.categoryId;
              _step               = _Step.edit;
            }),
            onBack: () => _goToStep(_Step.edit),
          ),
        );
      case _Step.alertPicker:
        return KeyedSubtree(
          key:   const ValueKey('alert'),
          child: TodoTimeSheet(
            initialTime:    _selectedTime,
            initialEnabled: _alarmEnabled,
            embedded:       true,
            onConfirm: (result) => setState(() {
              _selectedTime = result.time;
              _alarmEnabled = result.enabled;
              _step         = _Step.edit;
            }),
            onBack: () => _goToStep(_Step.edit),
          ),
        );
    }
  }

  // ── 상세 보기 단계 ──────────────────────────────────────────────────
  Widget _buildViewStep(DoitdoColors c) {
    final vm          = ref.read(todoViewModelProvider.notifier);
    final detailAsync = ref.watch(todoDetailProvider(widget.todoId));
    final categories  = ref.watch(categoryViewModelProvider).valueOrNull ?? [];

    Color getCategoryColor(String name) {
      try {
        return categories.firstWhere((cat) => cat.categoryName == name).color;
      } catch (_) {
        return AppColors.category1;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.calendarPoint),
        ),
        error: (err, _) => Center(
          child: Text('상세 정보를 불러오지 못했습니다.\n$err',
              style: AppTextStyles.bodyMedium),
        ),
        data: (detailDto) {
          final catName = detailDto.category ?? '기타';
          final catBg   = getCategoryColor(catName);
          final catFg   = catBg.computeLuminance() > 0.4
              ? AppColors.calendarDateText
              : Colors.white;

          final allLocal = [
            ...ref.read(todoViewModelProvider).allTodos,
            ...ref.read(todoViewModelProvider).allSomedayTodos,
          ];
          final localMatch = allLocal.where((t) => t.id == widget.todoId);
          final isDone = localMatch.isNotEmpty
              ? localMatch.first.isDone
              : detailDto.status == 'DONE';

          String dateDisplay = '미지정';
          if (detailDto.type == 'SOMEDAY') {
            dateDisplay = '언젠가 할 일';
          } else if (detailDto.startDate != null) {
            final sParts = detailDto.startDate!.split('-');
            if (sParts.length == 3) {
              dateDisplay =
                  '${int.parse(sParts[1])}월 ${int.parse(sParts[2])}일';
            } else {
              dateDisplay = detailDto.startDate!;
            }
            if (detailDto.endDate != null) {
              final eParts = detailDto.endDate!.split('-');
              if (eParts.length == 3) {
                dateDisplay +=
                    ' ~ ${int.parse(eParts[1])}월 ${int.parse(eParts[2])}일';
              }
            }
            if (detailDto.type == 'RECURRING') dateDisplay += ' 시작 (반복)';
          }

          return Column(
            mainAxisSize:       MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 상단: 마스코트 + 삭제 버튼
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const _MascotBubble(message: '할 일 상세'),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      final confirmed = await showDoitdoDialog(
                        context:      context,
                        title:        '할 일 삭제',
                        message:      '정말 삭제하시겠어요?',
                        confirmLabel: '삭제',
                        cancelLabel:  '취소',
                      );
                      if (confirmed == true && mounted) {
                        if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
                        widget.isSomeday
                            ? vm.deleteSomedayTodo(widget.todoId)
                            : vm.deleteTodo(widget.todoId);
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
                      child: Text('삭제',
                          style: AppTextStyles.labelMedium
                              .copyWith(color: c.textSecondary)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 제목
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  detailDto.title,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontFamily:      'GmarketSansMedium',
                    fontWeight:      FontWeight.w500,
                    color:           isDone ? c.textHint : c.textPrimary,
                    decoration:      isDone ? TextDecoration.lineThrough : null,
                    decorationColor: c.textHint,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 상세 정보 (스크롤)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _InfoRow(
                          icon:  Icons.calendar_today_outlined,
                          label: '기간',
                          value: dateDisplay),
                      Divider(color: c.divider, height: 1, thickness: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 20, 8, 20),
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
                                  color:        catBg,
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text(catName,
                                  style: AppTextStyles.labelSmall
                                      .copyWith(color: catFg)),
                            ),
                          ],
                        ),
                      ),
                      Divider(color: c.divider, height: 1, thickness: 1),
                      _InfoRow(
                          icon:  Icons.notifications_outlined,
                          label: '알림',
                          value: detailDto.alarmTime ?? '없음'),
                      Divider(color: c.divider, height: 1, thickness: 1),
                      ...[
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                (detailDto.content != null && detailDto.content!.isNotEmpty)
                                    ? detailDto.content!
                                    : '메모를 입력해 보세요.',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: (detailDto.content != null && detailDto.content!.isNotEmpty)
                                      ? c.textPrimary
                                      : c.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 하단 버튼: 닫기 / 수정하기
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context, rootNavigator: true).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.loginBtnOff,
                        foregroundColor: Colors.white,
                        elevation:       0,
                        shadowColor:     Colors.transparent,
                        textStyle:       AppTextStyles.bodyMedium,
                        shape:           RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        fixedSize: const Size.fromHeight(48),
                      ),
                      child: const Text('닫기'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DoitdoPrimaryButton(
                      height: 48,
                      label:  '수정하기',
                      onPressed: isDone
                          ? () => showDoitdoDialog(
                                context:      context,
                                title:        '수정 불가',
                                message:      '완료된 할 일은 수정할 수 없어요.\n먼저 미완료로 변경해 주세요.',
                                confirmLabel: '확인',
                              )
                          : () {
                              _initEditState(detailDto);
                              _goToStep(_Step.edit);
                            },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ── 수정 단계 ──────────────────────────────────────────────────────
  Widget _buildEditStep(DoitdoColors c) {
    final categories = ref.watch(categoryViewModelProvider).valueOrNull ?? [];
    Color getCategoryColor(String name) {
      try {
        return categories.firstWhere((cat) => cat.categoryName == name).color;
      } catch (_) {
        return AppColors.category1;
      }
    }

    final allLocal   = [...ref.read(todoViewModelProvider).allTodos, ...ref.read(todoViewModelProvider).allSomedayTodos];
    final localMatch = allLocal.where((t) => t.id == widget.todoId);
    final isDone     = localMatch.isNotEmpty ? localMatch.first.isDone : false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize:       MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 마스코트
          const _MascotBubble(message: '어떻게 수정할까?'),
          const SizedBox(height: 16),
          // 제목 입력
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: TextField(
              controller: _titleController,
              focusNode:  _titleFocusNode,
              style: AppTextStyles.titleLarge.copyWith(
                fontFamily: 'GmarketSansMedium',
                fontWeight: FontWeight.w500,
                color:      c.textPrimary,
              ),
              decoration: InputDecoration(
                hintText:  '할 일을 입력해주세요.',
                hintStyle: AppTextStyles.titleLarge.copyWith(
                  fontFamily: 'GmarketSansMedium',
                  fontWeight: FontWeight.w500,
                  color:      const Color(0xFFD6D3D1),
                ),
                border:         InputBorder.none,
                isDense:        true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // 옵션 + 메모 (스크롤)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize:       MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 기간 — 언젠가 할 일은 날짜 변경 불가
                  GestureDetector(
                    onTap: widget.isSomeday ? null : () => _goToStep(_Step.datePicker),
                    child: _OptionRow(
                      icon:      Icons.calendar_today_outlined,
                      label:     '기간',
                      valueText: widget.isSomeday ? '언젠가 할 일' : _dateResult.displayText,
                      colors:    c,
                      disabled:  widget.isSomeday,
                    ),
                  ),
                  Divider(color: c.divider, height: 1, thickness: 1),
                  // 카테고리
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
                            width:  8,
                            height: 8,
                            decoration: BoxDecoration(
                              color:  getCategoryColor(_selectedCategory),
                              shape:  BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(_selectedCategory,
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: c.textPrimary)),
                          const SizedBox(width: 2),
                          Icon(Icons.chevron_right,
                              size: 16, color: c.textHint),
                        ],
                      ),
                    ),
                  ),
                  // 알림
                  GestureDetector(
                    onTap: () => _goToStep(_Step.alertPicker),
                    child: _OptionRow(
                      icon:      Icons.notifications_outlined,
                      label:     '알림',
                      valueText: _alarmEnabled
                          ? _formatTime(_selectedTime)
                          : '없음',
                      colors: c,
                    ),
                  ),
                  Divider(color: c.divider, height: 1, thickness: 1),
                  const SizedBox(height: 16),
                  // 메모
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: TextField(
                      controller:   _memoController,
                      minLines:     4,
                      maxLines:     null,
                      keyboardType: TextInputType.multiline,
                      style:        AppTextStyles.bodyMedium
                          .copyWith(color: c.textPrimary),
                      decoration: InputDecoration(
                        hintText:       '메모를 입력해 보세요.',
                        hintStyle:      AppTextStyles.bodyMedium
                            .copyWith(color: c.textHint),
                        border:         InputBorder.none,
                        isDense:        true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 수정 완료 버튼
          DoitdoPrimaryButton(
            height:    48,
            label:     _isLoading ? '수정 중...' : '수정 완료',
            onPressed: _isLoading ? null : () => _onSave(context, isDone),
          ),
        ],
      ),
    );
  }
}

// ── 공통 위젯 ─────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String   label;
  final String   value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 20),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFC8966E)),
          const SizedBox(width: 12),
          Text(label,
              style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary)),
          const Spacer(),
          Text(value,
              style: AppTextStyles.bodyMedium.copyWith(color: c.textPrimary)),
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
    this.disabled = false,
  });
  final IconData      icon;
  final String        label;
  final String        valueText;
  final DoitdoColors  colors;
  final bool          disabled;

  @override
  Widget build(BuildContext context) {
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
                  .copyWith(color: disabled ? colors.textHint : colors.textPrimary)),
          if (!disabled) ...[
            const SizedBox(width: 2),
            Icon(Icons.chevron_right, size: 16, color: colors.textHint),
          ],
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
        Image.asset('assets/images/Dooit.png', width: 30, height: 30),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: AppColors.bubbleBg,
            borderRadius: BorderRadius.only(
              topLeft:     Radius.circular(4),
              topRight:    Radius.circular(12),
              bottomLeft:  Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Text(
            message,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.calendarDateText),
          ),
        ),
      ],
    );
  }
}
