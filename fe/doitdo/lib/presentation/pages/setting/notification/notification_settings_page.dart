import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/utils/error_message_mapper.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/data/models/setting_dto.dart';
import 'package:doitdo/presentation/pages/setting/notification/notification_settings_view_model.dart';
import 'package:doitdo/presentation/pages/setting/notification/widgets/time_picker_sheet.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_top_bar.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_padding_layout.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_scaffold.dart';

/// 설정 > 알림 설정 화면.
///
/// 3개 섹션:
///   1) 일반 — 푸시알림 토글 (OS 알림 권한 상태 반영)
///   2) 알림 금지 시간 — dndEnabled + dndStartTime / dndEndTime
///   3) 리마인드 — morningReminder / eveningReminder
///
/// 시간/리마인드 토글은 낙관적 업데이트 후 PATCH. 실패 시 롤백 + SnackBar.
///
/// ### 푸시알림 토글 동작
/// 진실의 출처는 OS 알림 권한이다 (앱이 권한을 무시한 채 푸시를 띄울 수 없으므로).
/// 따라서 토글의 `value` 는 [Permission.notification] 의 상태를 그대로 반영하고,
/// 인앱에서 직접 끄거나 켤 수 없다. 탭 시 동작은 다음과 같다.
///   - 권한 허용 상태에서 탭(=끄려는 의도): OS 알림 설정 페이지로 이동
///   - 권한 미요청/거부 상태에서 탭(=켜려는 의도): 시스템 권한 다이얼로그 요청
///   - 영구 거부(permanentlyDenied)인 경우: OS 알림 설정 페이지로 이동
/// 앱이 다시 foreground 로 돌아오면 권한 상태를 다시 읽어 토글에 반영한다.
class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage>
    with WidgetsBindingObserver {
  /// OS 알림 권한 허용 여부. 페이지 진입 + 앱 resume 시점에 갱신된다.
  /// `provisional`(iOS 한정) 도 알림이 도달하므로 true 로 친다.
  bool _osNotificationGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshOsPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 사용자가 OS 설정에서 권한을 바꾸고 앱으로 돌아왔을 때 토글에 반영.
    if (state == AppLifecycleState.resumed) {
      _refreshOsPermission();
    }
  }

  Future<void> _refreshOsPermission() async {
    final status = await Permission.notification.status;
    if (!mounted) return;
    setState(() {
      _osNotificationGranted = status.isGranted || status.isProvisional;
    });
  }

  void _showError(Object e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mapErrorMessage(e))));
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay current) =>
      showTimePickerSheet(context: context, initial: current);

  /// 푸시알림 토글 탭 핸들러.
  /// 권한 상태에 따라 OS 설정으로 보내거나 권한 요청 다이얼로그를 띄운다.
  /// 자세한 분기는 [NotificationSettingsPage] 의 클래스 docstring 참조.
  Future<void> _onPushToggleTapped() async {
    try {
      final status = await Permission.notification.status;

      if (status.isGranted || status.isProvisional) {
        // 켜져 있는 상태에서의 탭 = 끄려는 의도. 앱에서 직접 끌 수 없으므로 OS 설정으로.
        await AppSettings.openAppSettings(type: AppSettingsType.notification);
        return;
      }

      if (status.isPermanentlyDenied || status.isRestricted) {
        // 시스템 다이얼로그를 다시 띄울 수 없는 상태 → OS 설정으로 직접 보냄.
        await AppSettings.openAppSettings(type: AppSettingsType.notification);
        return;
      }

      // denied / notDetermined → 시스템 권한 다이얼로그 요청.
      final newStatus = await Permission.notification.request();
      if (!mounted) return;
      setState(() {
        _osNotificationGranted =
            newStatus.isGranted || newStatus.isProvisional;
      });
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationSettingsViewModelProvider);
    final vm = ref.read(notificationSettingsViewModelProvider.notifier);

    return DoitdoScaffold(
      topBar: const DoitdoTopBar(title: '알림 설정'),
      body: DoitdoPaddingLayout(
        top: 16,
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mapErrorMessage(e),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => ref.invalidate(
                    notificationSettingsViewModelProvider,
                  ),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
          data: (setting) => _Body(
            setting: setting,
            pushGranted: _osNotificationGranted,
            onPushTap: _onPushToggleTapped,
            onDndChanged: (v) => _run(() => vm.setDndEnabled(v)),
            onDndStartTap: () async {
              final current = setting.dndStartTime?.toTimeOfDay() ??
                  const TimeOfDay(hour: 22, minute: 0);
              final picked = await _pickTime(current);
              if (picked != null) _run(() => vm.setDndStartTime(picked));
            },
            onDndEndTap: () async {
              final current = setting.dndEndTime?.toTimeOfDay() ??
                  const TimeOfDay(hour: 7, minute: 0);
              final picked = await _pickTime(current);
              if (picked != null) _run(() => vm.setDndEndTime(picked));
            },
            onMorningChanged: (v) => _run(() => vm.setMorningEnabled(v)),
            onMorningTimeTap: () async {
              final current = setting.morningReminderTime?.toTimeOfDay() ??
                  const TimeOfDay(hour: 8, minute: 0);
              final picked = await _pickTime(current);
              if (picked != null) _run(() => vm.setMorningTime(picked));
            },
            onEveningChanged: (v) => _run(() => vm.setEveningEnabled(v)),
            onEveningTimeTap: () async {
              final current = setting.eveningReminderTime?.toTimeOfDay() ??
                  const TimeOfDay(hour: 21, minute: 0);
              final picked = await _pickTime(current);
              if (picked != null) _run(() => vm.setEveningTime(picked));
            },
          ),
        ),
      ),
    );
  }
}

/// 실제 콘텐츠 — state.when(data:) 안에서만 렌더링.
class _Body extends StatelessWidget {
  const _Body({
    required this.setting,
    required this.pushGranted,
    required this.onPushTap,
    required this.onDndChanged,
    required this.onDndStartTap,
    required this.onDndEndTap,
    required this.onMorningChanged,
    required this.onMorningTimeTap,
    required this.onEveningChanged,
    required this.onEveningTimeTap,
  });

  final UserSettingResp setting;
  final bool pushGranted;
  final VoidCallback onPushTap;
  final ValueChanged<bool> onDndChanged;
  final VoidCallback onDndStartTap;
  final VoidCallback onDndEndTap;
  final ValueChanged<bool> onMorningChanged;
  final VoidCallback onMorningTimeTap;
  final ValueChanged<bool> onEveningChanged;
  final VoidCallback onEveningTimeTap;

  @override
  Widget build(BuildContext context) {
    final dndStart = setting.dndStartTime?.toTimeOfDay() ??
        const TimeOfDay(hour: 22, minute: 0);
    final dndEnd = setting.dndEndTime?.toTimeOfDay() ??
        const TimeOfDay(hour: 7, minute: 0);
    final morningTime = setting.morningReminderTime?.toTimeOfDay() ??
        const TimeOfDay(hour: 8, minute: 0);
    final eveningTime = setting.eveningReminderTime?.toTimeOfDay() ??
        const TimeOfDay(hour: 21, minute: 0);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // ── 일반 ──────────────────────────
        // 토글은 OS 알림 권한 상태를 그대로 표시한다.
        // 탭 이벤트는 _PushToggleRow 안의 GestureDetector 가 받아 _onPushToggleTapped 로 위임.
        const _SectionLabel('일반'),
        const SizedBox(height: 8),
        _SettingsCard(
          child: _PushToggleRow(
            granted: pushGranted,
            onTap: onPushTap,
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
                value: setting.dndEnabled,
                onChanged: onDndChanged,
              ),
              const SizedBox(height: 14),
              _TimeRangeBlock(
                start: dndStart,
                end: dndEnd,
                enabled: setting.dndEnabled,
                onTapStart: onDndStartTap,
                onTapEnd: onDndEndTap,
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
                value: setting.morningReminderEnabled,
                onChanged: onMorningChanged,
              ),
              const SizedBox(height: 14),
              _SingleTimeBlock(
                time: morningTime,
                enabled: setting.morningReminderEnabled,
                onTap: onMorningTimeTap,
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
                value: setting.eveningReminderEnabled,
                onChanged: onEveningChanged,
              ),
              const SizedBox(height: 14),
              _SingleTimeBlock(
                time: eveningTime,
                enabled: setting.eveningReminderEnabled,
                onTap: onEveningTimeTap,
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
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

/// 푸시알림 행. 비주얼은 일반 토글과 동일하지만 동작이 다르다.
///
/// - [granted] 는 OS 알림 권한 상태. Switch 의 value 로 그대로 들어간다.
/// - 행 전체를 GestureDetector 로 받아 [onTap] 으로 위임한다 (Switch 자체는 [IgnorePointer]
///   로 인터랙션을 막아 사용자가 토글을 직접 켜고 끄는 것처럼 보이지 않도록 한다 —
///   실제 권한 변경은 OS 설정 / 권한 다이얼로그를 거쳐야 한다).
class _PushToggleRow extends StatelessWidget {
  const _PushToggleRow({
    required this.granted,
    required this.onTap,
  });

  final bool granted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(Icons.notifications_none_outlined,
              color: colors.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '푸시알림',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '두잇뚜로부터 알림을 수신합니다.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Switch 는 비주얼 전용. 실제 탭은 바깥 GestureDetector 가 처리.
          IgnorePointer(
            child: Transform.scale(
              scale: 0.9,
              child: Switch(
                value: granted,
                onChanged: (_) {},
                activeColor: Colors.white,
                activeTrackColor: colors.primary,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: colors.border,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
