import 'package:flutter/material.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_bottom_sheet.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_sheet_action_button.dart';

/// 오전·오후 + 시 + 분 3단 휠 피커 바텀시트.
///
/// 반환: 확인 시 선택한 [TimeOfDay], 이전/바깥 탭/뒤로가기 시 null.
Future<TimeOfDay?> showTimePickerSheet({
  required BuildContext context,
  required TimeOfDay initial,
}) {
  return showDoitdoBottomSheet<TimeOfDay>(
    context: context,
    child: _TimePickerSheet(initial: initial),
  );
}

class _TimePickerSheet extends StatefulWidget {
  const _TimePickerSheet({required this.initial});
  final TimeOfDay initial;

  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  late bool _isAm;
  late int _hour12; // 1~12
  late int _minute; // 0~59

  @override
  void initState() {
    super.initState();
    _isAm = widget.initial.hour < 12;
    final h = widget.initial.hour % 12;
    _hour12 = h == 0 ? 12 : h;
    _minute = widget.initial.minute;
  }

  TimeOfDay _result() {
    // 12시간제 → 24시간제 변환.
    // 오전 12시 = 0시, 오후 12시 = 12시, 그 외 오후는 +12.
    final twelveToBase = _hour12 % 12;
    final hour24 = _isAm ? twelveToBase : twelveToBase + 12;
    return TimeOfDay(hour: hour24, minute: _minute);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        SizedBox(
          height: 260,
          child: Row(
            children: [
              Expanded(
                child: _WheelPicker(
                  items: const ['오전', '오후'],
                  selectedIndex: _isAm ? 0 : 1,
                  onChanged: (i) => setState(() => _isAm = i == 0),
                ),
              ),
              Expanded(
                child: _WheelPicker(
                  items: List.generate(12, (i) => '${i + 1}'),
                  selectedIndex: _hour12 - 1,
                  onChanged: (i) => setState(() => _hour12 = i + 1),
                ),
              ),
              Expanded(
                child: _WheelPicker(
                  items: List.generate(
                    60,
                    (i) => i.toString().padLeft(2, '0'),
                  ),
                  selectedIndex: _minute,
                  onChanged: (i) => setState(() => _minute = i),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Expanded(
                child: DoitdoSheetActionButton(
                  label: '이전',
                  isPrimary: false,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DoitdoSheetActionButton(
                  label: '확인',
                  onPressed: () => Navigator.of(context).pop(_result()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 하나의 휠 컬럼 — 중앙에 오는 항목을 크고 진하게, 주변은 작고 옅게.
///
/// ListWheelScrollView + FixedExtent 로 스냅 스크롤 구현.
/// `onSelectedItemChanged` 가 현재 중앙 인덱스를 알려주므로 해당 인덱스만
/// 강조 스타일을 주어 시안의 "선택된 값은 크고 어둡게" 효과 구현.
class _WheelPicker extends StatefulWidget {
  const _WheelPicker({
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  State<_WheelPicker> createState() => _WheelPickerState();
}

class _WheelPickerState extends State<_WheelPicker> {
  late int _currentIndex = widget.selectedIndex;
  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(initialItem: widget.selectedIndex);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListWheelScrollView.useDelegate(
      controller: _controller,
      itemExtent: 56,
      perspective: 0.003,
      diameterRatio: 2.0,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (i) {
        setState(() => _currentIndex = i);
        widget.onChanged(i);
      },
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: widget.items.length,
        builder: (ctx, index) {
          final isCenter = index == _currentIndex;
          return Center(
            child: Text(
              widget.items[index],
              // 중앙 = 시간 피커 전용 displayLarge (28sp), 주변 = titleLarge (20sp).
              style: (isCenter
                      ? AppTextStyles.displayLarge
                      : AppTextStyles.titleLarge)
                  .copyWith(
                // 중앙만 진한 색, 나머지는 옅게 페이드.
                color: isCenter
                    ? colors.textPrimary
                    : colors.textPrimary.withOpacity(0.35),
              ),
            ),
          );
        },
      ),
    );
  }
}
