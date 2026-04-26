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
    int? categoryId,          // ← 이 줄 추가
    required String type,
    required int priority,
    String? startDate,
    String? endDate,
    List<String>? daysOfWeek, // ✏️ period → daysOfWeek (서버 변경 반영)
    @JsonKey(name: 'alertTime') String? alarmTime,
  }) = _TodoDetailResponseDto;

  factory TodoDetailResponseDto.fromJson(Map<String, dynamic> json) =>
      _$TodoDetailResponseDtoFromJson(json);
}