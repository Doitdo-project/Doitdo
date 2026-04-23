import 'package:freezed_annotation/freezed_annotation.dart';

part 'todo_calendar_response_dto.freezed.dart';
part 'todo_calendar_response_dto.g.dart';

// 1. 최상위 응답 DTO
@freezed
class TodoCalendarResponseDto with _$TodoCalendarResponseDto {
  const factory TodoCalendarResponseDto({
    required List<CalendarSummaryDto> calendar,
    required List<CalendarTodoItemDto> selectedDateItems,
  }) = _TodoCalendarResponseDto;

  factory TodoCalendarResponseDto.fromJson(Map<String, dynamic> json) =>
      _$TodoCalendarResponseDtoFromJson(json);
}

// 2. 날짜별 요약 (달력에 점/카운트 표시용)
@freezed
class CalendarSummaryDto with _$CalendarSummaryDto {
  const factory CalendarSummaryDto({
    required String date,
    required int completedCount,
    required int totalCount,
  }) = _CalendarSummaryDto;

  factory CalendarSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$CalendarSummaryDtoFromJson(json);
}

// 3. 선택 날짜의 상세 TODO 목록
@freezed
class CalendarTodoItemDto with _$CalendarTodoItemDto {
  const factory CalendarTodoItemDto({
    required int todoId,
    required String title,
    required String status, // TODO, IN_PROGRESS, DONE
    bool? isVirtual,
    int? masterTodoId,
    String? occurrenceDate,
  }) = _CalendarTodoItemDto;

  factory CalendarTodoItemDto.fromJson(Map<String, dynamic> json) =>
      _$CalendarTodoItemDtoFromJson(json);
}