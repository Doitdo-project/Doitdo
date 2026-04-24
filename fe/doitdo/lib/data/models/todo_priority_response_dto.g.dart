// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_priority_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TodoPriorityResponseDtoImpl _$$TodoPriorityResponseDtoImplFromJson(
  Map<String, dynamic> json,
) => _$TodoPriorityResponseDtoImpl(
  todoId: (json['todoId'] as num).toInt(),
  priority: (json['priority'] as num).toInt(),
  updatedAt: json['updatedAt'] as String,
);

Map<String, dynamic> _$$TodoPriorityResponseDtoImplToJson(
  _$TodoPriorityResponseDtoImpl instance,
) => <String, dynamic>{
  'todoId': instance.todoId,
  'priority': instance.priority,
  'updatedAt': instance.updatedAt,
};
