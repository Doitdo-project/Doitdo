// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_list_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TodoListResponseDtoImpl _$$TodoListResponseDtoImplFromJson(
  Map<String, dynamic> json,
) => _$TodoListResponseDtoImpl(
  items: (json['items'] as List<dynamic>)
      .map((e) => TodoListItemDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$TodoListResponseDtoImplToJson(
  _$TodoListResponseDtoImpl instance,
) => <String, dynamic>{'items': instance.items};

_$TodoListItemDtoImpl _$$TodoListItemDtoImplFromJson(
  Map<String, dynamic> json,
) => _$TodoListItemDtoImpl(
  todoId: (json['todoId'] as num).toInt(),
  title: json['title'] as String,
  status: json['status'] as String,
  content: json['content'] as String?,
  priority: (json['priority'] as num?)?.toInt(),
  categoryId: (json['categoryId'] as num?)?.toInt(),
  category: json['category'] as String?,
  colorHex: json['colorHex'] as String?,
  type: json['type'] as String?,
  startDate: json['startDate'] as String?,
  endDate: json['endDate'] as String?,
  alarmTime: json['alertTime'] as String?,
  daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  excludedDates:
      (json['excludedDates'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  masterTodoId: (json['masterTodoId'] as num?)?.toInt(),
  recurrenceGroupId: (json['recurrenceGroupId'] as num?)?.toInt(),
  occurrenceDate: json['occurrenceDate'] as String?,
);

Map<String, dynamic> _$$TodoListItemDtoImplToJson(
  _$TodoListItemDtoImpl instance,
) => <String, dynamic>{
  'todoId': instance.todoId,
  'title': instance.title,
  'status': instance.status,
  'content': instance.content,
  'priority': instance.priority,
  'categoryId': instance.categoryId,
  'category': instance.category,
  'colorHex': instance.colorHex,
  'type': instance.type,
  'startDate': instance.startDate,
  'endDate': instance.endDate,
  'alertTime': instance.alarmTime,
  'daysOfWeek': instance.daysOfWeek,
  'excludedDates': instance.excludedDates,
  'masterTodoId': instance.masterTodoId,
  'recurrenceGroupId': instance.recurrenceGroupId,
  'occurrenceDate': instance.occurrenceDate,
};
