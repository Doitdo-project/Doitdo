// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_update_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TodoUpdateRequestDtoImpl _$$TodoUpdateRequestDtoImplFromJson(
  Map<String, dynamic> json,
) => _$TodoUpdateRequestDtoImpl(
  title: json['title'] as String,
  content: json['content'] as String?,
  category: json['category'] as String?,
  type: json['type'] as String,
  startDate: json['startDate'] as String,
  endDate: json['endDate'] as String?,
  period: (json['period'] as num?)?.toInt(),
);

Map<String, dynamic> _$$TodoUpdateRequestDtoImplToJson(
  _$TodoUpdateRequestDtoImpl instance,
) => <String, dynamic>{
  'title': instance.title,
  'content': instance.content,
  'category': instance.category,
  'type': instance.type,
  'startDate': instance.startDate,
  'endDate': instance.endDate,
  'period': instance.period,
};
