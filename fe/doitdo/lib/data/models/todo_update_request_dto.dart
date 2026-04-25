import 'package:freezed_annotation/freezed_annotation.dart';

part 'todo_update_request_dto.freezed.dart';
part 'todo_update_request_dto.g.dart';

@freezed
class TodoUpdateRequestDto with _$TodoUpdateRequestDto {
  const factory TodoUpdateRequestDto({
    required String title,
    String? content,
    String? category,
    required String type, // NORMAL, RECURRING, PERIOD
    required String? startDate, // YYYY-MM-DD 형식
    String? endDate, // YYYY-MM-DD 형식
    Set<String>? daysOfWeek, // ✏️ period → daysOfWeek (서버 변경 반영)
    @JsonKey(name: 'alertTime') String? alarmTime,
    bool? clearAlertTime, // ✏️ 추가: true면 서버에서 alertTime null로 초기화
  }) = _TodoUpdateRequestDto;

  factory TodoUpdateRequestDto.fromJson(Map<String, dynamic> json) =>
      _$TodoUpdateRequestDtoFromJson(json);
}