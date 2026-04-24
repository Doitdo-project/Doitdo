import 'package:freezed_annotation/freezed_annotation.dart';

part 'todo_priority_response_dto.freezed.dart';
part 'todo_priority_response_dto.g.dart';

@freezed
class TodoPriorityResponseDto with _$TodoPriorityResponseDto {
  const factory TodoPriorityResponseDto({
    required int todoId,
    required int priority,
    required String updatedAt,
  }) = _TodoPriorityResponseDto;

  factory TodoPriorityResponseDto.fromJson(Map<String, dynamic> json) =>
      _$TodoPriorityResponseDtoFromJson(json);
}