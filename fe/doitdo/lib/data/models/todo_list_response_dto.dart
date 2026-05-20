import 'package:freezed_annotation/freezed_annotation.dart';

part 'todo_list_response_dto.freezed.dart';
part 'todo_list_response_dto.g.dart';

@freezed
class TodoListResponseDto with _$TodoListResponseDto {
  const factory TodoListResponseDto({
    required List<TodoListItemDto> items,
  }) = _TodoListResponseDto;

  factory TodoListResponseDto.fromJson(Map<String, dynamic> json) =>
      _$TodoListResponseDtoFromJson(json);
}

@freezed
class TodoListItemDto with _$TodoListItemDto {
  const factory TodoListItemDto({
    required int todoId,
    required String title,
    required String status,
    String? content,
    int? priority,
    int? categoryId,
    String? category,
    String? colorHex,
    String? type,
    String? startDate,
    String? endDate,
    // 서버 JSON 키는 alertTime — @JsonKey 로 매핑
    @JsonKey(name: 'alertTime') String? alarmTime,
    List<String>? daysOfWeek,
    // BE MR !281: scope=only 로 삭제된 RECURRING occurrence 날짜 배열.
    // RECURRING 마스터: ["2026-05-14", ...] (오름차순), 그 외 타입: 항상 [].
    // BE 미배포 환경에서도 안전하도록 @Default 로 빈 리스트 처리.
    @Default(<String>[]) List<String> excludedDates,
    // NORMAL 파생 인스턴스(scope=only 수정/완료): 원본 마스터 ID + 발생일.
    // RECURRING 마스터 / 그 외 타입은 null.
    int? masterTodoId,
    // 같은 반복 흐름임을 식별하는 group id.
    // - RECURRING 마스터: 자기 todoId (group head)
    // - scope=from 으로 잘려나간 새 RECURRING 마스터: 원본 마스터의 group_id 상속
    // - scope=only 로 materialize 된 NORMAL 인스턴스: 마스터의 group_id 상속
    // - 일반 NORMAL/PERIOD/SOMEDAY: null
    // - 백필 안 된 레거시 RECURRING: null (자연 폴백)
    int? recurrenceGroupId,
    String? occurrenceDate,
  }) = _TodoListItemDto;

  factory TodoListItemDto.fromJson(Map<String, dynamic> json) =>
      _$TodoListItemDtoFromJson(json);
}