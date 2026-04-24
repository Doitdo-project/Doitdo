import 'package:freezed_annotation/freezed_annotation.dart';

part 'todo_snooze_response_dto.freezed.dart';
part 'todo_snooze_response_dto.g.dart';

@freezed
class TodoSnoozeResponseDto with _$TodoSnoozeResponseDto {
  const factory TodoSnoozeResponseDto({
    required int todoId,
    required String title,
    String? content,
    String? category,
    required String type,
    int? priority,
    required String startDate,
    String? endDate,
    int? period,
    required String status,
    required String updatedAt,
    required int snoozedDays, // 누적 미루기 횟수
  }) = _TodoSnoozeResponseDto;

  factory TodoSnoozeResponseDto.fromJson(Map<String, dynamic> json) =>
      _$TodoSnoozeResponseDtoFromJson(json);
}