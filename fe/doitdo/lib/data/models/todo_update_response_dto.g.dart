// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_update_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TodoUpdateResponseDtoImpl _$$TodoUpdateResponseDtoImplFromJson(
  Map<String, dynamic> json,
) => _$TodoUpdateResponseDtoImpl(
  todoId: (json['todoId'] as num).toInt(),
  status: json['status'] as String,
  updatedAt: json['updatedAt'] as String,
);

Map<String, dynamic> _$$TodoUpdateResponseDtoImplToJson(
  _$TodoUpdateResponseDtoImpl instance,
) => <String, dynamic>{
  'todoId': instance.todoId,
  'status': instance.status,
  'updatedAt': instance.updatedAt,
};
