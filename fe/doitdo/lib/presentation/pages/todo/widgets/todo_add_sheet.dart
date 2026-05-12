import 'dart:async';

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
import 'package:doitdo/presentation/widgets/common/character_mascot_image.dart';

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
  String    _selectedCategory   = '';
  int?      _selectedCategoryId;
  TimeOfDay _selectedTime       = const TimeOfDay(hour: 12, minute: 0);
  bool      _alarmEnabled       = false;
  bool      _isLoading          = false;
  bool      _showTitleError     = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _dateResult = TodoDateResult(type: TodoDateType.normal, date: widget.initialDate!);
    } else {
      _dateResult = const TodoDateResult(type: TodoDateType.someday);
    }

    final cats = ref.read(categoryViewModelProvider).valueOrNull;
    if (cats != null && cats.isNotEmpty) {
      _selectedCategory   = cats.first.categoryName;
      _selectedCategoryId = cats.first.categoryId;
    }

    // 제목이 비어있으면 저장 버튼을 disable 한다 — 변화 감지를 위해 controller listener 등록.
    // empty/non-empty 전이가 일어날 때만 setState 를 돌려 불필요한 리빌드를 줄인다.
    _titleController.addListener(_onTitleChanged);

    // 시트 진입 직후 제목 필드에 자동 포커스 → 키보드 즉시 노출.
    // 회색 저장 버튼의 "왜 비활성?" 첫 진입 비용을 줄여준다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _titleFocusNode.requestFocus();
    });
  }

  bool _wasEmpty = true;
  void _onTitleChanged() {
    final isEmpty = _titleController.text.trim().isEmpty;
    if (_showTitleError && !isEmpty) {
      setState(() => _showTitleError = false);
      return;
    }
    if (isEmpty != _wasEmpty) {
      _wasEmpty = isEmpty;
      setState(() {});
    }
  }

  /// 단계 전환 — 키보드 닫고 setState.
  void _goToStep(_Step next) {
    FocusScope.of(context).unfocus();
    setState(() => _step = next);
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
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
    if (_isLoading) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _showTitleError = true);
      _titleFocusNode.requestFocus();
      return;
    }

    setState(() => _isLoading = true);

    final r = _dateResult;
    final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final todo = Todo(
      id: localId,
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

    // 1. 낙관적 삽입 — 목록에 즉시 표시
    ref.read(todoViewModelProvider.notifier).insertLocalTodo(todo);

    // 2. 시트 즉시 닫기 — 사용자 체감 latency 0ms
    if (context.mounted) Navigator.of(context).pop();

    // 3. API 호출 백그라운드 — 성공: 로컬 ID → 서버 ID 교체, 실패: 제거 + 에러 상태
    unawaited(ref.read(todoAddNotifierProvider.notifier).createTodo(todo, localId));
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
            disableRange: widget.initialDate == null,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
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
                if (_showTitleError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '제목을 입력해주세요.',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: const Color(0xFFE07A2E),
                      ),
                    ),
                  ),
              ],
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
                  // 기간 — 언젠가 할 일 컨텍스트에서는 날짜 변경 불가.
                  GestureDetector(
                    onTap: widget.initialDate == null
                        ? null
                        : () => _goToStep(_Step.datePicker),
                    child: _OptionRow(
                      icon: Icons.calendar_today_outlined,
                      label: '기간',
                      valueText: _dateResult?.displayText ?? '미지정',
                      colors: c,
                      disabled: widget.initialDate == null,
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
          // 저장 중이거나 제목이 비어있으면 탭 차단. 색상은 메인 컬러 그대로 유지.
          const SizedBox(height: 12),
          Builder(builder: (context) {
            return IgnorePointer(
              ignoring: _isLoading,
              child: DoitdoPrimaryButton(
                height: 48,
                label: _isLoading ? '저장 중...' : '저장하기',
                onPressed: () => _onSave(context),
              ),
            );
          }),
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
  final IconData icon;
  final String label;
  final String valueText;
  final DoitdoColors colors;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: Padding(
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
            if (!disabled)
              Icon(Icons.chevron_right, size: 16, color: colors.textHint),
          ],
        ),
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