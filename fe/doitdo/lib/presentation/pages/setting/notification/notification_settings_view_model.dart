import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/data/models/setting_dto.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';

/// 설정 > 알림 설정 상태 및 서버 연동 로직.
///
/// 진입 시 GET /api/settings 로 현재 설정을 조회하고,
/// 토글·시간 변경 시 낙관적으로 state 를 먼저 바꾼 뒤 PATCH 를 날린다.
/// 서버 오류 시 이전 state 로 롤백하고 예외를 rethrow — View 에서 SnackBar 처리.
///
/// 참고: 푸시 수신 on/off 는 인앱 토글로 두지 않는다. OS 알림 권한이 진실의 출처라
/// NotificationSettingsPage 의 "푸시알림" 행은 시스템 설정으로 보내는 링크일 뿐.
/// 따라서 이 ViewModel 은 푸시 수신 여부를 직접 다루지 않는다.
class NotificationSettingsViewModel extends AsyncNotifier<UserSettingResp> {
  @override
  Future<UserSettingResp> build() =>
      ref.read(settingRepositoryProvider).getSetting();

  /// 낙관적 업데이트 + 서버 동기화.
  ///
  /// [optimistic] : 즉시 화면에 반영할 새 state.
  /// [body]       : PATCH /api/settings 에 보낼 부분 업데이트 맵.
  ///
  /// ### try/catch 이유 (가이드 §12.7 예외)
  /// 가이드는 "ViewModel 안에 try/catch 없다" 를 원칙으로 하지만,
  /// 낙관적 업데이트는 실패 시 이전 state 로 롤백해야 하므로
  /// AsyncValue.guard 만으로는 표현이 불가능하다.
  /// 에러를 숨기지 않고 반드시 rethrow 해서 View 의 SnackBar 까지 전달한다.
  Future<void> _patch(UserSettingResp optimistic, Map<String, dynamic> body) async {
    final previous = state;
    state = AsyncData(optimistic);
    try {
      final updated =
          await ref.read(settingRepositoryProvider).updateSetting(body);
      state = AsyncData(updated);
    } catch (e) {
      state = previous; // 서버 실패 시 이전 state 복원
      rethrow;          // View 의 _showError 까지 예외 전파
    }
  }

  /// 방해금지 on/off.
  ///
  /// 서버 검증: `dndEnabled = true` 이면 `dndStartTime` / `dndEndTime` 둘 다 필수
  /// (없으면 500 C00-003 "방해금지 사용 시 시작/종료 시간이 모두 필요합니다.").
  /// 따라서 켤 때 기존 값이 비어 있으면 화면 기본값(22:00 / 07:00) 을 함께 보낸다.
  /// 끌 때는 시간 검증이 없으므로 dndEnabled 만 전송.
  Future<void> setDndEnabled(bool v) {
    final current = state.requireValue;
    if (!v) {
      return _patch(
        current.copyWith(dndEnabled: v),
        {'dndEnabled': v},
      );
    }

    final startDto =
        current.dndStartTime ?? const LocalTimeDto(hour: 22, minute: 0);
    final endDto =
        current.dndEndTime ?? const LocalTimeDto(hour: 7, minute: 0);
    return _patch(
      current.copyWith(
        dndEnabled: v,
        dndStartTime: startDto,
        dndEndTime: endDto,
      ),
      {
        'dndEnabled': v,
        'dndStartTime': startDto.toJson(),
        'dndEndTime': endDto.toJson(),
      },
    );
  }

  Future<void> setDndStartTime(TimeOfDay t) {
    final current = state.requireValue;
    final dto = LocalTimeDto.fromTimeOfDay(t);
    return _patch(
      current.copyWith(dndStartTime: dto),
      {'dndStartTime': dto.toJson()},
    );
  }

  Future<void> setDndEndTime(TimeOfDay t) {
    final current = state.requireValue;
    final dto = LocalTimeDto.fromTimeOfDay(t);
    return _patch(
      current.copyWith(dndEndTime: dto),
      {'dndEndTime': dto.toJson()},
    );
  }

  /// 아침 리마인드 on/off.
  ///
  /// DND 와 마찬가지로 서버 스케줄러가 enabled=true 이면 시간을 함께
  /// 알아야 트리거가 잡힌다. 사용자가 시간을 한 번도 설정하지 않은 채
  /// 토글만 켜면 서버는 어떤 시각에 푸시할지 모르므로, 켤 때는 기본값(08:00)을
  /// 함께 PATCH 한다.
  Future<void> setMorningEnabled(bool v) {
    final current = state.requireValue;
    if (!v) {
      return _patch(
        current.copyWith(morningReminderEnabled: v),
        {'morningReminderEnabled': v},
      );
    }
    final timeDto =
        current.morningReminderTime ?? const LocalTimeDto(hour: 8, minute: 0);
    return _patch(
      current.copyWith(
        morningReminderEnabled: v,
        morningReminderTime: timeDto,
      ),
      {
        'morningReminderEnabled': v,
        'morningReminderTime': timeDto.toJson(),
      },
    );
  }

  Future<void> setMorningTime(TimeOfDay t) {
    final current = state.requireValue;
    final dto = LocalTimeDto.fromTimeOfDay(t);
    return _patch(
      current.copyWith(morningReminderTime: dto),
      {'morningReminderTime': dto.toJson()},
    );
  }

  /// 저녁 리마인드 on/off — 아침과 동일한 이유로 기본값(21:00) 동봉.
  Future<void> setEveningEnabled(bool v) {
    final current = state.requireValue;
    if (!v) {
      return _patch(
        current.copyWith(eveningReminderEnabled: v),
        {'eveningReminderEnabled': v},
      );
    }
    final timeDto =
        current.eveningReminderTime ?? const LocalTimeDto(hour: 21, minute: 0);
    return _patch(
      current.copyWith(
        eveningReminderEnabled: v,
        eveningReminderTime: timeDto,
      ),
      {
        'eveningReminderEnabled': v,
        'eveningReminderTime': timeDto.toJson(),
      },
    );
  }

  Future<void> setEveningTime(TimeOfDay t) {
    final current = state.requireValue;
    final dto = LocalTimeDto.fromTimeOfDay(t);
    return _patch(
      current.copyWith(eveningReminderTime: dto),
      {'eveningReminderTime': dto.toJson()},
    );
  }
}

final notificationSettingsViewModelProvider =
    AsyncNotifierProvider<NotificationSettingsViewModel, UserSettingResp>(
  NotificationSettingsViewModel.new,
);
