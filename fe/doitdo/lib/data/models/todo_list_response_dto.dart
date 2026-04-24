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
    int? priority,
    String? category,
    String? type,
    String? startDate,
    String? endDate,
  }) = _TodoListItemDto;

  factory TodoListItemDto.fromJson(Map<String, dynamic> json) =>
      _$TodoListItemDtoFromJson(json);
}