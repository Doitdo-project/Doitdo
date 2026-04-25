// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_calendar_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TodoCalendarResponseDtoImpl _$$TodoCalendarResponseDtoImplFromJson(
  Map<String, dynamic> json,
) => _$TodoCalendarResponseDtoImpl(
  items: (json['items'] as List<dynamic>)
      .map((e) => CalendarTodoItemDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$TodoCalendarResponseDtoImplToJson(
  _$TodoCalendarResponseDtoImpl instance,
) => <String, dynamic>{'items': instance.items};

_$CalendarSummaryDtoImpl _$$CalendarSummaryDtoImplFromJson(
  Map<String, dynamic> json,
) => _$CalendarSummaryDtoImpl(
  date: json['date'] as String,
  completedCount: (json['completedCount'] as num).toInt(),
  totalCount: (json['totalCount'] as num).toInt(),
);

Map<String, dynamic> _$$CalendarSummaryDtoImplToJson(
  _$CalendarSummaryDtoImpl instance,
) => <String, dynamic>{
  'date': instance.date,
  'completedCount': instance.completedCount,
  'totalCount': instance.totalCount,
};

_$CalendarTodoItemDtoImpl _$$CalendarTodoItemDtoImplFromJson(
  Map<String, dynamic> json,
) => _$CalendarTodoItemDtoImpl(
  todoId: (json['todoId'] as num?)?.toInt(),
  title: json['title'] as String,
  status: json['status'] as String,
  isVirtual: json['isVirtual'] as bool?,
  masterTodoId: (json['masterTodoId'] as num?)?.toInt(),
  occurrenceDate: json['occurrenceDate'] as String?,
);

Map<String, dynamic> _$$CalendarTodoItemDtoImplToJson(
  _$CalendarTodoItemDtoImpl instance,
) => <String, dynamic>{
  'todoId': instance.todoId,
  'title': instance.title,
  'status': instance.status,
  'isVirtual': instance.isVirtual,
  'masterTodoId': instance.masterTodoId,
  'occurrenceDate': instance.occurrenceDate,
};
