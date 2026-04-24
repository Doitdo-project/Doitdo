// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_detail_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TodoDetailResponseDtoImpl _$$TodoDetailResponseDtoImplFromJson(
  Map<String, dynamic> json,
) => _$TodoDetailResponseDtoImpl(
  todoId: (json['todoId'] as num).toInt(),
  title: json['title'] as String,
  content: json['content'] as String?,
  status: json['status'] as String,
  category: json['category'] as String?,
  type: json['type'] as String,
  priority: (json['priority'] as num).toInt(),
  startDate: json['startDate'] as String?,
  endDate: json['endDate'] as String?,
  period: (json['period'] as num?)?.toInt(),
);

Map<String, dynamic> _$$TodoDetailResponseDtoImplToJson(
  _$TodoDetailResponseDtoImpl instance,
) => <String, dynamic>{
  'todoId': instance.todoId,
  'title': instance.title,
  'content': instance.content,
  'status': instance.status,
  'category': instance.category,
  'type': instance.type,
  'priority': instance.priority,
  'startDate': instance.startDate,
  'endDate': instance.endDate,
  'period': instance.period,
};
