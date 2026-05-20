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
  categoryId: (json['categoryId'] as num?)?.toInt(),
  type: json['type'] as String,
  startDate: json['startDate'] as String?,
  endDate: json['endDate'] as String?,
  daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toSet(),
  alarmTime: json['alertTime'] as String?,
  clearAlertTime: json['clearAlertTime'] as bool?,
);

Map<String, dynamic> _$$TodoUpdateRequestDtoImplToJson(
  _$TodoUpdateRequestDtoImpl instance,
) => <String, dynamic>{
  'title': instance.title,
  'content': instance.content,
  if (instance.categoryId case final value?) 'categoryId': value,
  'type': instance.type,
  'startDate': instance.startDate,
  'endDate': instance.endDate,
  if (instance.daysOfWeek?.toList() case final value?) 'daysOfWeek': value,
  'alertTime': instance.alarmTime,
  if (instance.clearAlertTime case final value?) 'clearAlertTime': value,
};
