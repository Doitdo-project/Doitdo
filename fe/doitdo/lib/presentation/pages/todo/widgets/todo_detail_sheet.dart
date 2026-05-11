import 'dart:async';
import 'dart:math' show max;

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
import 'package:doitdo/presentation/widgets/common/character_mascot_image.dart';

enum _Step { main, datePicker, categoryPicker, alertPicker }

class TodoDetailSheet extends ConsumerStatefulWidget {
  const TodoDetailSheet({super.key, required this.todo, required this.isSomeday});

  final Todo todo;
  final bool isSomeday;

  @override
  ConsumerState<TodoDetailSheet> createState() => _TodoDetailSheetState();
}

class _TodoDetailSheetState extends ConsumerState<TodoDetailSheet> {
  _Step _step        = _Step.main;
  bool  _initialized = false;
  bool  _isDone      = false;
  bool  _textDirty   = false;

  final _titleController = TextEditingController();
  final _memoController  = TextEditingController();
  final _titleFocusNode  = FocusNode();
  final _memoFocusNode   = FocusNode();
  String         _selectedCategory   = '기타';
  TimeOfDay      _selectedTime       = const TimeOfDay(hour: 12, minute: 0);
  bool           _alarmEnabled       = false;
  TodoDateResult _dateResult         = const TodoDateResult(type: TodoDateType.someday);
  bool           _isLoading          = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_markDirty);
    _memoController.addListener(_markDirty);
    _titleFocusNode.addListener(_onFocusChange);
    _memoFocusNode.addListener(_onFocusChange);
    _initFromTodo(widget.todo);
  }

  void _initFromTodo(Todo todo) {
    _titleController.text = todo.title;
    _memoController.text  = todo.memo ?? '';
    _selectedCategory     = todo.category.name;
    _isDone               = todo.isDone;
    _wasTitleEmpty        = todo.title.trim().isEmpty;
    if (todo.alarmTime != null) {
      _selectedTime = todo.alarmTime!;
      _alarmEnabled = todo.alarmEnabled;
    }
    _dateResult = TodoDateResult(
      type:            todo.dateType,
      date:            todo.date,
      rangeStart:      todo.rangeStart,
      rangeEnd:        todo.rangeEnd,
      repeatStartDate: todo.repeatStartDate,
      repeatEndDate:   todo.repeatEndDate,
      repeatDays:      todo.repeatDays,
    );
    _initialized = true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    _titleFocusNode.dispose();
    _memoFocusNode.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (_initialized) _textDirty = true;
    // 제목 empty/non-empty 전이 시 확인 버튼 색을 갱신.
    // 빈 제목으로는 저장 불가 정책이라 disable 신호가 즉시 반영되어야 한다.
    final isEmpty = _titleController.text.trim().isEmpty;
    if (isEmpty != _wasTitleEmpty) {
      _wasTitleEmpty = isEmpty;
      if (mounted) setState(() {});
    }
  }

  bool _wasTitleEmpty = true;

  // 제목/메모 포커스가 둘 다 빠졌을 때 자동 저장
  void _onFocusChange() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 빈 제목이면 자동 저장 트리거하지 않음 — 확인 버튼 회색 정책과 일관.
      // SnackBar 가 시트에 가려지는 문제로 안내도 불가능하므로 silent skip.
      // dirty flag 도 그대로 유지 → 이후 사용자가 제목을 다시 채우고 포커스 빠지면 저장 발동.
      if (_titleController.text.trim().isEmpty) return;
      if (!_titleFocusNode.hasFocus && !_memoFocusNode.hasFocus &&
          _textDirty && _initialized && !_isDone) {
        _textDirty = false;
        unawaited(_onSave(context, _isDone));
      }
    });
  }

  void _goToStep(_Step next) {
    FocusScope.of(context).unfocus();
    setState(() => _step = next);
  }

  String _formatTime(TimeOfDay t) {
    final h      = t.hour;
    final m      = t.minute.toString().padLeft(2, '0');
    final period  = h < 12 ? '오전' : '오후';
    final display = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$period $display:$m';
  }

  Future<void> _onSave(BuildContext context, bool isDone) async {
    if (_isLoading) return;

    final title = _titleController.text.trim();
    // 빈 제목은 확인 버튼 disable + 자동 저장 가드로 정상 경로상 도달 불가.
    // SnackBar 안내는 시트에 가려져 보이지 않으므로 silent return.
    if (title.isEmpty) return;

    setState(() => _isLoading = true);
    final vm = ref.read(todoViewModelProvider.notifier);

    try {
      final r       = _dateResult;
      final updated = Todo(
        id:              widget.todo.id,
        title:           title,
        category:        TodoCategory.fromName(_selectedCategory),
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
    } catch (e) {
      await vm.fetchTodos();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text('수정에 실패했어요. 다시 시도해 주세요.',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: Colors.red.shade700,
            behavior:        SnackBarBehavior.floating,
            shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin:          const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onConfirm(BuildContext context) async {
    if (_isDone) {
      Navigator.of(context, rootNavigator: true).pop();
      return;
    }

    // _textDirty 를 먼저 false 로 — unfocus 로 인한 focus listener 가 중복 저장하지 않도록
    final wasDirty = _textDirty;
    _textDirty = false;
    FocusScope.of(context).unfocus();
    final nav = Navigator.of(context, rootNavigator: true);

    if (wasDirty) {
      await _onSave(context, _isDone);
    }
    if (mounted) nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c           = context.colors;
    final fixedHeight = MediaQuery.of(context).size.height * 0.75;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: MediaQuery(
        data:  MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
        child: Container(
          decoration: BoxDecoration(
            color:        c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          height:  fixedHeight,
          padding: const EdgeInsets.only(top: 12),
          child: Padding(
            // viewPadding 은 키보드 유무와 무관하게 물리적 safe area 를 반환하므로
            // 키보드 등장/퇴장 시 padding.bottom 이 0↔34 로 바뀌는 레이아웃 흔들림이 없다.
            padding: EdgeInsets.only(
              bottom: max(8.0, MediaQuery.viewPaddingOf(context).bottom),
            ),
            child: Column(
              mainAxisSize:       MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                    duration:       const Duration(milliseconds: 180),
                    layoutBuilder:  (current, previous) => Stack(
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
      ),
    );
  }

  Widget _buildStep(DoitdoColors c) {
    switch (_step) {
      case _Step.main:
        return KeyedSubtree(key: const ValueKey('main'), child: _buildMainStep(c));
      case _Step.datePicker:
        return KeyedSubtree(
          key:   const ValueKey('date'),
          child: TodoDateSheet(
            initialDate:   _dateResult.date ?? DateTime.now(),
            initialResult: _dateResult,
            embedded:      true,
            onConfirm: (result) {
              setState(() {
                _dateResult = result;
                _step       = _Step.main;
              });
              unawaited(_onSave(context, _isDone));
            },
            onBack: () => _goToStep(_Step.main),
          ),
        );
      case _Step.categoryPicker:
        return KeyedSubtree(
          key:   const ValueKey('category'),
          child: TodoCategorySheet(
            selectedCategory: _selectedCategory,
            embedded:         true,
            onConfirm: (result) {
              setState(() {
                _selectedCategory = result.categoryName;
                _step               = _Step.main;
              });
              unawaited(_onSave(context, _isDone));
            },
            onBack: () => _goToStep(_Step.main),
          ),
        );
      case _Step.alertPicker:
        return KeyedSubtree(
          key:   const ValueKey('alert'),
          child: TodoTimeSheet(
            initialTime:    _selectedTime,
            initialEnabled: true,
            embedded:       true,
            onConfirm: (result) {
              setState(() {
                _selectedTime = result.time;
                _alarmEnabled = result.enabled;
                _step         = _Step.main;
              });
              unawaited(_onSave(context, _isDone));
            },
            onBack: () => _goToStep(_Step.main),
          ),
        );
    }
  }

  // ── 메인(통합) 단계 ────────────────────────────────────────────────────
  Widget _buildMainStep(DoitdoColors c) {
    final categories = ref.watch(categoryViewModelProvider).valueOrNull ?? [];
    Color getCategoryColor(String name) {
      try {
        return categories.firstWhere((cat) => cat.categoryName == name).color;
      } catch (_) {
        return AppColors.category1;
      }
    }

    return _buildForm(c, getCategoryColor);
  }

  Widget _buildForm(DoitdoColors c, Color Function(String) getCategoryColor) {
    final vm     = ref.read(todoViewModelProvider.notifier);
    final catBg  = getCategoryColor(_selectedCategory);
    final catFg  = catBg.computeLuminance() > 0.4
        ? AppColors.calendarDateText
        : Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
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
                    if (context.mounted) {
                      Navigator.of(context, rootNavigator: true).pop();
                    }
                    widget.isSomeday
                        ? vm.deleteSomedayTodo(widget.todo.id)
                        : vm.deleteTodo(widget.todo.id);
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
          // 제목 (직접 수정 가능)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: TextField(
              controller: _titleController,
              focusNode:  _titleFocusNode,
              readOnly:   _isDone,
              style: AppTextStyles.titleLarge.copyWith(
                fontFamily:      'GmarketSansMedium',
                fontWeight:      FontWeight.w500,
                color:           _isDone ? c.textHint : c.textPrimary,
                decoration:      _isDone ? TextDecoration.lineThrough : null,
                decorationColor: c.textHint,
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
                  // 기간
                  GestureDetector(
                    onTap: (_isDone || widget.isSomeday)
                        ? null
                        : () => _goToStep(_Step.datePicker),
                    child: _OptionRow(
                      icon:      Icons.calendar_today_outlined,
                      label:     '기간',
                      valueText: widget.isSomeday
                          ? '언젠가 할 일'
                          : _dateResult.displayText,
                      colors:   c,
                      disabled: _isDone || widget.isSomeday,
                    ),
                  ),
                  Divider(color: c.divider, height: 1, thickness: 1),
                  // 카테고리
                  GestureDetector(
                    onTap: _isDone ? null : () => _goToStep(_Step.categoryPicker),
                    child: Padding(
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
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(_selectedCategory,
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: catFg)),
                          ),
                          if (!_isDone) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.chevron_right,
                                size: 16, color: c.textHint),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Divider(color: c.divider, height: 1, thickness: 1),
                  // 알림
                  GestureDetector(
                    onTap: _isDone ? null : () => _goToStep(_Step.alertPicker),
                    child: _OptionRow(
                      icon:      Icons.notifications_outlined,
                      label:     '알림',
                      valueText: _alarmEnabled
                          ? _formatTime(_selectedTime)
                          : '없음',
                      colors:   c,
                      disabled: _isDone,
                    ),
                  ),
                  Divider(color: c.divider, height: 1, thickness: 1),
                  const SizedBox(height: 24),
                  // 메모 (직접 수정 가능)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: TextField(
                      controller:   _memoController,
                      focusNode:    _memoFocusNode,
                      readOnly:     _isDone,
                      minLines:     4,
                      maxLines:     null,
                      keyboardType: TextInputType.multiline,
                      style:        AppTextStyles.bodyMedium
                          .copyWith(color: _isDone ? c.textHint : c.textPrimary),
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
          // 하단 버튼
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
                child: Builder(builder: (context) {
                  final canConfirm = _isDone || _titleController.text.trim().isNotEmpty;
                  return IgnorePointer(
                    ignoring: !canConfirm,
                    child: DoitdoPrimaryButton(
                      height:    48,
                      label:     '확인',
                      onPressed: () => _onConfirm(context),
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 공통 위젯 ─────────────────────────────────────────────────────────────

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.label,
    required this.valueText,
    required this.colors,
    this.disabled = false,
  });
  final IconData     icon;
  final String       label;
  final String       valueText;
  final DoitdoColors colors;
  final bool         disabled;

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
              style: AppTextStyles.bodyMedium.copyWith(
                  color: disabled ? colors.textHint : colors.textPrimary)),
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
        const CharacterMascotImage(size: 36),
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