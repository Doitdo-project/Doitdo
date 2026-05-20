// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'todo_detail_response_dto.freezed.dart';
part 'todo_detail_response_dto.g.dart';

@freezed
class TodoDetailResponseDto with _$TodoDetailResponseDto {
  const factory TodoDetailResponseDto({
    required int todoId,
    required String title,
    String? content,
    required String status,
    String? category,
    String? colorHex,
    int? categoryId, // ← 이 줄 추가
    required String type,
    required int priority,
    String? startDate,
    String? endDate,
    List<String>? daysOfWeek, // ✏️ period → daysOfWeek (서버 변경 반영)
    @JsonKey(name: 'alertTime') String? alarmTime,
    // BE MR !281: scope=only 로 삭제된 RECURRING occurrence 날짜 배열.
    // RECURRING 마스터: ["2026-05-14", ...] (오름차순), 그 외 타입: 항상 [].
    @Default(<String>[]) List<String> excludedDates,
    // NORMAL 파생 인스턴스(scope=only 수정/완료): 원본 마스터 ID.
    // RECURRING 마스터 / 그 외 타입은 null.
    int? masterTodoId,
    // 같은 반복 흐름임을 식별하는 group id.
    // - RECURRING 마스터: 자기 todoId (group head)
    // - scope=from 으로 잘려나간 새 RECURRING 마스터: 원본 마스터의 group_id 상속
    // - scope=only 로 materialize 된 NORMAL 인스턴스: 마스터의 group_id 상속
    // - 일반 NORMAL/PERIOD/SOMEDAY: null
    // - 백필 안 된 레거시 RECURRING: null (자연 폴백)
    int? recurrenceGroupId,
    @Default(0) int earnedCoin,
    @Default(false) bool rewarded,
    @Default(0) int walletBalance,
  }) = _TodoDetailResponseDto;

  factory TodoDetailResponseDto.fromJson(Map<String, dynamic> json) =>
      _$TodoDetailResponseDtoFromJson(json);
}
