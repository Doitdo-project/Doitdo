import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/models/todo.dart';
import 'package:doitdo/presentation/pages/todo/todo_view_model.dart';
// ✅ [수정된 부분] 우리가 새로 만든 API Notifier 파일 import 추가
import 'package:doitdo/presentation/pages/todo/todo_add_notifier.dart';
import 'package:doitdo/presentation/pages/todo/widgets/todo_category_sheet.dart';
import 'package:doitdo/presentation/pages/todo/widgets/todo_date_sheet.dart';
import 'package:doitdo/presentation/pages/todo/widgets/todo_time_sheet.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_primary_button.dart';

class TodoAddSheet extends ConsumerStatefulWidget {
  const TodoAddSheet({super.key, this.initialDate});

  /// null 이면 "언제가 할 일" 목록에 추가, 아니면 "오늘의 할 일"에 추가
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
  TimeOfDay _selectedTime     = const TimeOfDay(hour: 12, minute: 0);
  bool      _alarmEnabled     = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate ?? DateTime.now();
    _dateResult = TodoDateResult(type: TodoDateType.normal, date: initial);
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

  // ── 저장하기 ──────────────────────────────
  Future<void> _onSave(BuildContext context) async {
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

    final r = _dateResult;
    final todo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      category: TodoCategory.fromName(_selectedCategory),
      isDone: false,
      memo: _memoController.text.trim().isEmpty
          ? null
          : _memoController.text.trim(),
      alarmTime:       _alarmEnabled ? _selectedTime : null,
      alarmEnabled:    _alarmEnabled,
      dateType:        r?.type          ?? TodoDateType.normal,
      date:            r?.date,
      rangeStart:      r?.rangeStart,
      rangeEnd:        r?.rangeEnd,
      repeatType:      r?.repeatType,
      repeatStartDate: r?.repeatStartDate,
      repeatEndDate:   r?.repeatEndDate,
    );

    // 1. 서버로 전송 요청!
    await ref.read(todoAddNotifierProvider.notifier).createTodo(todo);

    // ✅ 2. 전송 결과 확인하기 (성공했는지 에러 났는지)
    final resultState = ref.read(todoAddNotifierProvider);

    // 🚨 에러가 발생했다면? (서버에 안 넘어감)
    if (resultState.hasError) {
      print('서버 통신 실패: ${resultState.error}'); // 콘솔창에 진짜 에러 원인 출력

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('서버 저장 실패: ${resultState.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return; // ❌ 화면에 추가하지 않고, 바텀시트도 닫지 않고 여기서 멈춤!
    }

    // ✅ 3. 에러가 없다면(통신 성공) 비로소 로컬 화면(UI)에 추가
    final vm = ref.read(todoViewModelProvider.notifier);
    widget.initialDate == null
        ? vm.addSomedayTodo(todo)
        : vm.addTodo(todo);

    // 창 닫기
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 드래그 핸들
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: c.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            // 시안: 드래그 핸들 아래 마스코트 말풍선이 뜰 공간.
            const SizedBox(height: 32),

            // 마스코트 말풍선
            _MascotBubble(
              message: widget.initialDate == null
                  ? '언제가 하고 싶은 일은?'
                  : '이날 어떤 일을 계획해볼까?',
            ),
            const SizedBox(height: 16),

            // 할 일 입력 — 시안: 20pt / Medium(w500) / 힌트 #D6D3D1.
            // 본문·옵션 텍스트는 마스코트 "가시 영역" 과 맞추기 위해 좌측 8 오프셋.
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
            // 시안: 타이틀 밑 divider 없이 공백만 두고 옵션 영역 시작.
            const SizedBox(height: 32),

            // 기간
            GestureDetector(
              onTap: () async {
                final result = await showModalBottomSheet<TodoDateResult>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => TodoDateSheet(
                      initialDate: _dateResult?.date ?? DateTime.now()),
                );
                if (result != null) setState(() => _dateResult = result);
              },
              child: _OptionRow(
                icon: Icons.calendar_today_outlined,
                label: '기간',
                valueText: _dateResult?.displayText ?? '',
                colors: c,
              ),
            ),
            Divider(color: c.divider, height: 1, thickness: 1),

            // 카테고리 — 점 색은 선택된 카테고리 실제 색(category1~5) 을 동적으로 반영.
            GestureDetector(
              onTap: () async {
                final result = await showModalBottomSheet<String>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) =>
                      TodoCategorySheet(selectedCategory: _selectedCategory),
                );
                if (result != null) setState(() => _selectedCategory = result);
              },
              child: Padding(
                // 마스코트 가시 영역과 수평 정렬을 위해 좌측 8 오프셋.
                padding: const EdgeInsets.fromLTRB(8, 20, 0, 20),
                child: Row(
                  children: [
                    // 시안 지정 아이콘 브랜드 컬러 (#C8966E — muted brown-orange).
                    const Icon(Icons.category_outlined,
                        size: 18, color: Color(0xFFC8966E)),
                    const SizedBox(width: 12),
                    Text('카테고리',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: c.textSecondary)),
                    const Spacer(),
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                          color: AppColors.calendarPoint,
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
            // 시안: 카테고리 ↔ 알림 사이 divider 없음.

            // ── 알림 — 시간 탭으로 TodoTimeSheet 열기 ──
            GestureDetector(
              onTap: () async {
                final result = await showModalBottomSheet<TodoAlarmResult>(
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
                // 시안: 알림 off 일 때도 선택된 시간을 미리 보여줌(설정값 확인용).
                valueText: _formatTime(_selectedTime),
                colors: c,
              ),
            ),
            Divider(color: c.divider, height: 1, thickness: 1),

            // 메모 (5줄 기본, 무제한 확장)
            const SizedBox(height: 16),
            Padding(
              // 메모 텍스트도 타이틀/옵션 행과 동일한 좌측 8 오프셋.
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
                  hintStyle:
                      AppTextStyles.bodyMedium.copyWith(color: c.textHint),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 저장하기
            DoitdoPrimaryButton(
              label: '저장하기',
              onPressed: () => _onSave(context),
            ),
          ],
        ),
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
      // 시안상 옵션 행 높이 ≈ 66~70px. 아이콘 18 + 상하 여백 20 씩.
      // 좌측 8 은 마스코트 가시 영역과 수평 정렬을 맞추기 위함.
      padding: const EdgeInsets.fromLTRB(8, 20, 0, 20),
      child: Row(
        children: [
          // 시안 지정 아이콘 브랜드 컬러 (#C8966E — muted brown-orange).
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

class _MascotBubble extends StatelessWidget {
  const _MascotBubble({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/Dooit.png',
          width: 36,
          height: 36,
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.bubbleBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Text(
            message,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.calendarDateText,
            ),
          ),
        ),
      ],
    );
  }
}