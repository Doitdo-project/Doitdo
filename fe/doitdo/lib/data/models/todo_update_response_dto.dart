import 'package:freezed_annotation/freezed_annotation.dart';

part 'todo_update_response_dto.freezed.dart';
part 'todo_update_response_dto.g.dart';

@freezed
class TodoUpdateResponseDto with _$TodoUpdateResponseDto {
  const factory TodoUpdateResponseDto({
    required int todoId,
    required String status,
    required String updatedAt,
  }) = _TodoUpdateResponseDto;

  factory TodoUpdateResponseDto.fromJson(Map<String, dynamic> json) =>
      _$TodoUpdateResponseDtoFromJson(json);
}