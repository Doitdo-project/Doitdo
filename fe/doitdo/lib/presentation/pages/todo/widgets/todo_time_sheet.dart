import 'package:flutter/material.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_primary_button.dart';

/// 알림 시간 설정 바텀시트.
class TodoTimeSheet extends StatefulWidget {
  const TodoTimeSheet({super.key, this.initialTime});

  final TimeOfDay? initialTime;

  @override
  State<TodoTimeSheet> createState() => _TodoTimeSheetState();
}

class _TodoTimeSheetState extends State<TodoTimeSheet> {
  late int _selectedHour;
  late int _selectedMinute;
  bool _isAm = false;
  bool _alarmEnabled = true;

  final List<int> _hours = List.generate(12, (i) => i + 1);
  final List<int> _minutes = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];

  @override
  void initState() {
    super.initState();
    final time = widget.initialTime ?? const TimeOfDay(hour: 19, minute: 30);
    _isAm = time.hour < 12;
    _selectedHour =
    time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    _selectedMinute = time.minute;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 드래그 핸들 ──
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

          // ── 마스코트 + 안내 문구 + 알림 토글 ──
          Row(
            children: [
              const _MascotIcon(),
              const SizedBox(width: 8),
              Text(
                '몇시에 알려줄까?',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: colors.textPrimary),
              ),
              const Spacer(),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: _alarmEnabled,
                  onChanged: (v) => setState(() => _alarmEnabled = v),
                  activeColor: Colors.white,
                  activeTrackColor: AppColors.calendarPoint,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: AppColors.toggleOff,
                  trackOutlineColor:
                  WidgetStateProperty.all(Colors.transparent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── 시간 피커 ──
          AnimatedOpacity(
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
          ),
          const SizedBox(height: 24),

          // ── 이전 / 확인 버튼 ──
          Row(
            children: [
              const Expanded(child: _PrevButton()),
              const SizedBox(width: 8),
              Expanded(
                child: DoitdoPrimaryButton(
                  label: '확인',
                  onPressed: () {
                    final hour = _isAm
                        ? (_selectedHour == 12 ? 0 : _selectedHour)
                        : (_selectedHour == 12 ? 12 : _selectedHour + 12);
                    Navigator.of(context)
                        .pop(TimeOfDay(hour: hour, minute: _selectedMinute));
                  },
                ),
              ),
            ],
          ),
        ],
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

// ─────────────────────────────────────────────
// 마스코트 아이콘 플레이스홀더
// ─────────────────────────────────────────────
class _MascotIcon extends StatelessWidget {
  const _MascotIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: AppColors.calendarPoint,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.sentiment_satisfied_alt_rounded,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 이전 버튼 (회색 — AppColors.loginBtnOff = 0xFFC5C5C5)
// ─────────────────────────────────────────────
class _PrevButton extends StatelessWidget {
  const _PrevButton();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => Navigator.of(context).pop(),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.loginBtnOff,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(
        '이전',
        style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
      ),
    );
  }
}