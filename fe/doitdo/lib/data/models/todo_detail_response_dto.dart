import 'package:freezed_annotation/freezed_annotation.dart';

part 'todo_detail_response_dto.freezed.dart';
part 'todo_detail_response_dto.g.dart';

@freezed
class TodoDetailResponseDto with _$TodoDetailResponseDto {
  const factory TodoDetailResponseDto({
    required int todoId,
    required String title,
    String? content, // = memo
    required String status,
    String? category,
    required String type, // NORMAL, RECURRING, PERIOD
    required int priority,
    String? startDate, // 언제가 할 일 대응을 위해 Nullable로 지정
    String? endDate,
    int? period,
  }) = _TodoDetailResponseDto;

  factory TodoDetailResponseDto.fromJson(Map<String, dynamic> json) =>
      _$TodoDetailResponseDtoFromJson(json);
}