import 'package:flutter/material.dart';

/// 백엔드 LocalTime 타입.
///
/// ⚠️ Swagger 스펙상 `LocalTime` 은 `{hour, minute, second, nano}` 객체로
/// 정의돼 있지만, 실제 서버는 Jackson JavaTimeModule 기본 설정으로
/// **ISO 문자열**(`"HH:mm:ss"`) 을 내리고 받는다. 양쪽을 방어적으로 처리한다.
///
/// - 응답 파싱: [fromServerValue] 가 String / Map 모두 수용
/// - 요청 직렬화: [toJson] 은 `"HH:mm:ss"` 문자열을 반환
class LocalTimeDto {
  const LocalTimeDto({required this.hour, required this.minute});

  final int hour;
  final int minute;

  /// 서버 응답 값 파싱. `"HH:mm[:ss]"` 문자열과 `{hour,minute,...}` 객체 둘 다 지원.
  factory LocalTimeDto.fromServerValue(dynamic v) {
    if (v is String) {
      final parts = v.split(':');
      if (parts.length < 2) {
        throw FormatException('Unexpected LocalTime string: $v');
      }
      return LocalTimeDto(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
    if (v is Map) {
      final map = v.cast<String, dynamic>();
      return LocalTimeDto(
        hour: (map['hour'] as num).toInt(),
        minute: (map['minute'] as num).toInt(),
      );
    }
    throw FormatException('Unexpected LocalTime payload: $v');
  }

  /// 과거 호환용 — Map 전용 팩토리. 신규 코드는 [fromServerValue] 사용.
  factory LocalTimeDto.fromJson(Map<String, dynamic> json) =>
      LocalTimeDto.fromServerValue(json);

  factory LocalTimeDto.fromTimeOfDay(TimeOfDay t) =>
      LocalTimeDto(hour: t.hour, minute: t.minute);

  TimeOfDay toTimeOfDay() => TimeOfDay(hour: hour, minute: minute);

  /// 서버로 보낼 ISO LocalTime 문자열. second 는 0 고정.
  /// PATCH body 안에 `{'dndStartTime': dto.toJson()}` 형태로 끼워서 사용.
  String toJson() {
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm:00';
  }
}

/// GET /api/settings 응답 DTO.
class UserSettingResp {
  const UserSettingResp({
    required this.dndEnabled,
    this.dndStartTime,
    this.dndEndTime,
    required this.morningReminderEnabled,
    this.morningReminderTime,
    required this.eveningReminderEnabled,
    this.eveningReminderTime,
    required this.tamagotchiNotificationEnabled,
  });

  final bool dndEnabled;
  final LocalTimeDto? dndStartTime;
  final LocalTimeDto? dndEndTime;
  final bool morningReminderEnabled;
  final LocalTimeDto? morningReminderTime;
  final bool eveningReminderEnabled;
  final LocalTimeDto? eveningReminderTime;
  final bool tamagotchiNotificationEnabled;

  factory UserSettingResp.fromJson(Map<String, dynamic> json) {
    LocalTimeDto? _time(String key) {
      final v = json[key];
      if (v == null) return null;
      return LocalTimeDto.fromServerValue(v);
    }

    return UserSettingResp(
      dndEnabled: (json['dndEnabled'] as bool?) ?? false,
      dndStartTime: _time('dndStartTime'),
      dndEndTime: _time('dndEndTime'),
      morningReminderEnabled: (json['morningReminderEnabled'] as bool?) ?? false,
      morningReminderTime: _time('morningReminderTime'),
      eveningReminderEnabled: (json['eveningReminderEnabled'] as bool?) ?? false,
      eveningReminderTime: _time('eveningReminderTime'),
      tamagotchiNotificationEnabled:
          (json['tamagotchiNotificationEnabled'] as bool?) ?? false,
    );
  }

  /// 낙관적 업데이트용 — 변경할 필드만 덮어쓴 복사본 반환.
  UserSettingResp copyWith({
    bool? dndEnabled,
    LocalTimeDto? dndStartTime,
    LocalTimeDto? dndEndTime,
    bool? morningReminderEnabled,
    LocalTimeDto? morningReminderTime,
    bool? eveningReminderEnabled,
    LocalTimeDto? eveningReminderTime,
    bool? tamagotchiNotificationEnabled,
  }) =>
      UserSettingResp(
        dndEnabled: dndEnabled ?? this.dndEnabled,
        dndStartTime: dndStartTime ?? this.dndStartTime,
        dndEndTime: dndEndTime ?? this.dndEndTime,
        morningReminderEnabled:
            morningReminderEnabled ?? this.morningReminderEnabled,
        morningReminderTime: morningReminderTime ?? this.morningReminderTime,
        eveningReminderEnabled:
            eveningReminderEnabled ?? this.eveningReminderEnabled,
        eveningReminderTime: eveningReminderTime ?? this.eveningReminderTime,
        tamagotchiNotificationEnabled:
            tamagotchiNotificationEnabled ?? this.tamagotchiNotificationEnabled,
      );
}
