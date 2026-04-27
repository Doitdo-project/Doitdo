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
  priority: (json['priority'] as num?)?.toInt(),
  category: json['category'] as String?,
  type: json['type'] as String?,
  startDate: json['startDate'] as String?,
  endDate: json['endDate'] as String?,
  alarmTime: json['alarmTime'] as String?,
  daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$$TodoListItemDtoImplToJson(
  _$TodoListItemDtoImpl instance,
) => <String, dynamic>{
  'todoId': instance.todoId,
  'title': instance.title,
  'status': instance.status,
  'priority': instance.priority,
  'category': instance.category,
  'type': instance.type,
  'startDate': instance.startDate,
  'endDate': instance.endDate,
  'alarmTime': instance.alarmTime,
  'daysOfWeek': instance.daysOfWeek,
};
