// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_snooze_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TodoSnoozeResponseDtoImpl _$$TodoSnoozeResponseDtoImplFromJson(
  Map<String, dynamic> json,
) => _$TodoSnoozeResponseDtoImpl(
  todoId: (json['todoId'] as num).toInt(),
  title: json['title'] as String,
  content: json['content'] as String?,
  category: json['category'] as String?,
  type: json['type'] as String,
  priority: (json['priority'] as num?)?.toInt(),
  startDate: json['startDate'] as String,
  endDate: json['endDate'] as String?,
  period: (json['period'] as num?)?.toInt(),
  status: json['status'] as String,
  updatedAt: json['updatedAt'] as String,
  snoozedDays: (json['snoozedDays'] as num).toInt(),
);

Map<String, dynamic> _$$TodoSnoozeResponseDtoImplToJson(
  _$TodoSnoozeResponseDtoImpl instance,
) => <String, dynamic>{
  'todoId': instance.todoId,
  'title': instance.title,
  'content': instance.content,
  'category': instance.category,
  'type': instance.type,
  'priority': instance.priority,
  'startDate': instance.startDate,
  'endDate': instance.endDate,
  'period': instance.period,
  'status': instance.status,
  'updatedAt': instance.updatedAt,
  'snoozedDays': instance.snoozedDays,
};
