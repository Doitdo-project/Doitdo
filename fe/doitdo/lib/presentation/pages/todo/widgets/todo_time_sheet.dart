import 'package:flutter/material.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_primary_button.dart';
import 'package:doitdo/presentation/widgets/common/character_mascot_image.dart';

// ─────────────────────────────────────────────
// 알림 시트 반환 모델
// 시간 + 알람 활성화 여부를 함께 반환한다.
// ─────────────────────────────────────────────
class TodoAlarmResult {
  const TodoAlarmResult({
    required this.time,
    required this.enabled,
  });
  final TimeOfDay time;
  final bool enabled;
}

/// 알림 시간 설정 바텀시트.
///
/// [embedded] 가 true 면 외부 시트 안에 임베드되어 렌더링되어
/// drag handle / 외곽 padding 을 자체로 그리지 않는다.
/// 그 경우 확인/이전은 `Navigator.pop` 대신 [onConfirm] / [onBack] 콜백으로 위임.
class TodoTimeSheet extends StatefulWidget {
  const TodoTimeSheet({
    super.key,
    this.initialTime,
    this.initialEnabled = true,
    this.embedded = false,
    this.onConfirm,
    this.onBack,
  });

  final TimeOfDay? initialTime;
  final bool initialEnabled;

  /// 외부 바텀시트 안에 임베드되어 렌더링될지 여부.
  final bool embedded;

  final ValueChanged<TodoAlarmResult>? onConfirm;
  final VoidCallback? onBack;

  @override
  State<TodoTimeSheet> createState() => _TodoTimeSheetState();
}

class _TodoTimeSheetState extends State<TodoTimeSheet> {
  late int _selectedHour;
  late int _selectedMinute;
  bool _isAm = false;
  late bool _alarmEnabled;

  final List<int> _hours = List.generate(12, (i) => i + 1);
  final List<int> _minutes = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];

  @override
  void initState() {
    super.initState();
    _alarmEnabled = widget.initialEnabled;
    final time = widget.initialTime ?? const TimeOfDay(hour: 12, minute: 0);
    _isAm = time.hour < 12;
    _selectedHour =
    time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    _selectedMinute = time.minute;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final embedded = widget.embedded;

    // ── 본문(헤더 + 휠 + 버튼) 은 embedded / standalone 공용. 외곽 wrapping 만 다름.
    // 마스코트 + 말풍선은 todo_add_sheet 와 동일 스펙(36×36 + 꼬리형 BorderRadius).
    final headerRow = Row(
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
            '몇시에 알려줄까?',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.calendarDateText),
          ),
        ),
        const Spacer(),
        // Switch 의 기본 tap-target padding(48dp) 이 Row 높이를 부풀려
        // 마스코트 위치가 add 시트보다 아래로 밀리는 걸 방지.
        // shrinkWrap 으로 tap-target 을 위젯 크기에 맞추고, Transform.scale 로 시각만 축소.
        Transform.scale(
          scale: 0.85,
          child: Switch(
            value: _alarmEnabled,
            onChanged: (v) => setState(() => _alarmEnabled = v),
            activeColor: Colors.white,
            activeTrackColor: AppColors.calendarPoint,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.toggleOff,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );

    final wheelRow = AnimatedOpacity(
      opacity: _alarmEnabled ? 1.0 : 0.35,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: !_alarmEnabled,
        child: SizedBox(
          height: 160,
          child: Row(
            children: [
              Expanded(child: _buildAmPmWheel(colors)),
              Expanded(child: _buildHourWheel(colors)),
              Expanded(child: _buildMinuteWheel(colors)),
            ],
          ),
        ),
      ),
    );

    // embedded 모드 본문: 휠을 가운데에 배치해 위/아래 여백을 골고루.
    final embeddedBody = Center(child: wheelRow);

    final buttonRow = Row(
      children: [
        Expanded(child: _PrevButton(onTap: embedded ? widget.onBack : null)),
        const SizedBox(width: 8),
        Expanded(
          child: DoitdoPrimaryButton(
            height: 48,
            label: '확인',
            onPressed: () {
              final hour = _isAm
                  ? (_selectedHour == 12 ? 0 : _selectedHour)
                  : (_selectedHour == 12 ? 12 : _selectedHour + 12);
              final result = TodoAlarmResult(
                time: TimeOfDay(hour: hour, minute: _selectedMinute),
                enabled: _alarmEnabled,
              );
              if (embedded) {
                widget.onConfirm?.call(result);
              } else {
                Navigator.of(context).pop(result);
              }
            },
          ),
        ),
      ],
    );

    if (embedded) {
      // 부모(todo_add_sheet) 가 시트 잔여 높이를 통째로 넘겨주므로
      // mainAxisSize.max + Expanded 로 마스코트(상단)/버튼(하단) 을 anchor.
      // 좌우/상단 padding 24/14 — todo_add_sheet 메인폼과 동일하게 맞춰
      // 마스코트 위치를 일치시킨다.
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            headerRow,
            const SizedBox(height: 16),
            Expanded(child: embeddedBody),
            const SizedBox(height: 16),
            buttonRow,
          ],
        ),
      );
    }

    // SafeArea(top: false, minimum: 8): 시스템 네비바와 시각 간격 보장 +
    // useSafeArea 가 꺼져 있어도 최소 8px 버퍼.
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 드래그 핸들 — standalone 모드 전용
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            headerRow,
            const SizedBox(height: 24),
            wheelRow,
            const SizedBox(height: 24),
            buttonRow,
          ],
        ),
      ),
    );
  }

  Widget _buildAmPmWheel(DoitdoColors colors) {
    return ListWheelScrollView.useDelegate(
      itemExtent: 48,
      perspective: 0.002,
      controller: FixedExtentScrollController(initialItem: _isAm ? 0 : 1),
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (i) => setState(() => _isAm = i == 0),
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: 2,
        builder: (_, i) {
          final label = i == 0 ? '오전' : '오후';
          final isSelected = (_isAm && i == 0) || (!_isAm && i == 1);
          return Center(
            child: Text(
              label,
              style: (isSelected
                  ? AppTextStyles.titleSmall
                  : AppTextStyles.bodyMedium)
                  .copyWith(
                color: isSelected ? colors.textPrimary : colors.textHint,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHourWheel(DoitdoColors colors) {
    return ListWheelScrollView.useDelegate(
      itemExtent: 48,
      perspective: 0.002,
      controller: FixedExtentScrollController(
          initialItem: _hours.indexOf(_selectedHour)),
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (i) => setState(() => _selectedHour = _hours[i]),
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: _hours.length,
        builder: (_, i) {
          final isSelected = _hours[i] == _selectedHour;
          return Center(
            child: Text(
              '${_hours[i]}',
              style: (isSelected
                  ? AppTextStyles.displayLarge
                  : AppTextStyles.bodyMedium)
                  .copyWith(
                color: isSelected ? colors.textPrimary : colors.textHint,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMinuteWheel(DoitdoColors colors) {
    final initIdx = _minutes.indexOf(_selectedMinute);
    return ListWheelScrollView.useDelegate(
      itemExtent: 48,
      perspective: 0.002,
      controller:
      FixedExtentScrollController(initialItem: initIdx < 0 ? 0 : initIdx),
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (i) =>
          setState(() => _selectedMinute = _minutes[i]),
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: _minutes.length,
        builder: (_, i) {
          final isSelected = _minutes[i] == _selectedMinute;
          return Center(
            child: Text(
              _minutes[i].toString().padLeft(2, '0'),
              style: (isSelected
                  ? AppTextStyles.displayLarge
                  : AppTextStyles.bodyMedium)
                  .copyWith(
                color: isSelected ? colors.textPrimary : colors.textHint,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PrevButton extends StatelessWidget {
  const _PrevButton({this.onTap});

  /// embedded 모드에서 부모가 주는 이전 콜백. null 이면 기본 `Navigator.pop`.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap ?? () => Navigator.of(context).pop(),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.loginBtnOff,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        '이전',
        style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
      ),
    );
  }
}