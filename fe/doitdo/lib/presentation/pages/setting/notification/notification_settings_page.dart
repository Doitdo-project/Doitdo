import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/pages/setting/notification/widgets/time_picker_sheet.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_top_bar.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_padding_layout.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_scaffold.dart';

/// 설정 > 알림 설정 화면.
///
/// 3개 섹션:
///   1) 일반 — 푸시 알림 수신 on/off
///   2) 알림 금지 시간 — 활성화 토글 + 시작/종료 시간 선택
///   3) 리마인드 — 아침 / 저녁 리마인드 각각 활성화 + 시간 선택
///
/// 상태는 현재 로컬 (setState). 추후 NotificationSettingsViewModel + provider
/// 로 승격해 SharedPreferences / 서버와 동기화 예정.
class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  bool _pushEnabled = true;
  bool _quietEnabled = false;
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 7, minute: 0);
  bool _morningEnabled = false;
  TimeOfDay _morningTime = const TimeOfDay(hour: 22, minute: 0);
  bool _eveningEnabled = false;
  TimeOfDay _eveningTime = const TimeOfDay(hour: 22, minute: 0);

  Future<TimeOfDay?> _pickTime(TimeOfDay current) {
    return showTimePickerSheet(context: context, initial: current);
  }

  @override
  Widget build(BuildContext context) {
    return DoitdoScaffold(
      topBar: const DoitdoTopBar(title: '알림 설정'),
      body: DoitdoPaddingLayout(
        top: 16,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ── 일반 ──────────────────────────
            const _SectionLabel('일반'),
            const SizedBox(height: 8),
            _SettingsCard(
              child: _ToggleRow(
                icon: Icons.notifications_none_outlined,
                title: '푸시알림',
                description: '두잇뚜로부터 알림을 수신합니다.',
                value: _pushEnabled,
                onChanged: (v) => setState(() => _pushEnabled = v),
              ),
            ),

            const SizedBox(height: 24),
            // ── 알림 금지 시간 ──────────────────
            const _SectionLabel('알림 금지 시간'),
            const SizedBox(height: 8),
            _SettingsCard(
              child: Column(
                children: [
                  _ToggleRow(
                    icon: Icons.bedtime_outlined,
                    title: '금지 시간 활성화',
                    description: '설정한 시간에는 알림이 울리지 않습니다.',
                    value: _quietEnabled,
                    onChanged: (v) => setState(() => _quietEnabled = v),
                  ),
                  const SizedBox(height: 14),
                  _TimeRangeBlock(
                    start: _quietStart,
                    end: _quietEnd,
                    enabled: _quietEnabled,
                    onTapStart: () async {
                      final picked = await _pickTime(_quietStart);
                      if (picked != null) {
                        setState(() => _quietStart = picked);
                      }
                    },
                    onTapEnd: () async {
                      final picked = await _pickTime(_quietEnd);
                      if (picked != null) {
                        setState(() => _quietEnd = picked);
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            // ── 리마인드 ───────────────────────
            const _SectionLabel('리마인드'),
            const SizedBox(height: 8),
            _SettingsCard(
              child: Column(
                children: [
                  _ToggleRow(
                    icon: Icons.alarm_outlined,
                    title: '아침 리마인드',
                    description: '하루의 시작을 돕는 알림',
                    value: _morningEnabled,
                    onChanged: (v) => setState(() => _morningEnabled = v),
                  ),
                  const SizedBox(height: 14),
                  _SingleTimeBlock(
                    time: _morningTime,
                    enabled: _morningEnabled,
                    onTap: () async {
                      final picked = await _pickTime(_morningTime);
                      if (picked != null) {
                        setState(() => _morningTime = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SettingsCard(
              child: Column(
                children: [
                  _ToggleRow(
                    icon: Icons.calendar_today_outlined,
                    title: '저녁 리마인드',
                    description: '내일을 위한 기록 리마인드',
                    value: _eveningEnabled,
                    onChanged: (v) => setState(() => _eveningEnabled = v),
                  ),
                  const SizedBox(height: 14),
                  _SingleTimeBlock(
                    time: _eveningTime,
                    enabled: _eveningEnabled,
                    onTap: () async {
                      final picked = await _pickTime(_eveningTime);
                      if (picked != null) {
                        setState(() => _eveningTime = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// 24시간 "HH:mm" 포맷.
String _formatTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: AppTextStyles.labelMedium.copyWith(
          color: context.colors.textHint,
        ),
      ),
    );
  }
}

/// 흰색 라운드 카드 컨테이너 (rx=24). 내부에 토글 로우 + 선택적 시간 블록.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

/// 아이콘 + 제목 + 설명 + Switch 한 행.
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(icon, color: colors.primary, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // 기본 터치 영역이 커서 Row 가 부풀어오르는 걸 막기 위해 사이즈 축소.
        Transform.scale(
          scale: 0.9,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: colors.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: colors.border,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}

/// "시작 22:00  —  종료 07:00" 두 칸 시간 블록.
class _TimeRangeBlock extends StatelessWidget {
  const _TimeRangeBlock({
    required this.start,
    required this.end,
    required this.enabled,
    required this.onTapStart,
    required this.onTapEnd,
  });

  final TimeOfDay start;
  final TimeOfDay end;
  final bool enabled;
  final VoidCallback onTapStart;
  final VoidCallback onTapEnd;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, color: colors.textHint, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: _TimeEntry(
              label: '시작',
              time: start,
              enabled: enabled,
              onTap: enabled ? onTapStart : null,
            ),
          ),
          Text(
            '—',
            style: AppTextStyles.bodyLarge.copyWith(color: colors.textHint),
          ),
          Expanded(
            child: _TimeEntry(
              label: '종료',
              time: end,
              enabled: enabled,
              onTap: enabled ? onTapEnd : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeEntry extends StatelessWidget {
  const _TimeEntry({
    required this.label,
    required this.time,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final TimeOfDay time;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: colors.textHint),
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(time),
            style: AppTextStyles.titleMedium.copyWith(
              // 비활성 시 약하게 페이드.
              color: enabled
                  ? colors.primary
                  : colors.primary.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// 단일 시간 블록 ("22:00" 중앙 정렬) — 리마인드 카드용.
class _SingleTimeBlock extends StatelessWidget {
  const _SingleTimeBlock({
    required this.time,
    required this.enabled,
    required this.onTap,
  });

  final TimeOfDay time;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          _formatTime(time),
          style: AppTextStyles.titleMedium.copyWith(
            color: enabled
                ? colors.primary
                : colors.primary.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}
