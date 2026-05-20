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
  colorHex: json['colorHex'] as String?,
  categoryId: (json['categoryId'] as num?)?.toInt(),
  type: json['type'] as String,
  priority: (json['priority'] as num).toInt(),
  startDate: json['startDate'] as String?,
  endDate: json['endDate'] as String?,
  daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  alarmTime: json['alertTime'] as String?,
  excludedDates:
      (json['excludedDates'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  masterTodoId: (json['masterTodoId'] as num?)?.toInt(),
  recurrenceGroupId: (json['recurrenceGroupId'] as num?)?.toInt(),
  earnedCoin: (json['earnedCoin'] as num?)?.toInt() ?? 0,
  rewarded: json['rewarded'] as bool? ?? false,
  walletBalance: (json['walletBalance'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$TodoDetailResponseDtoImplToJson(
  _$TodoDetailResponseDtoImpl instance,
) => <String, dynamic>{
  'todoId': instance.todoId,
  'title': instance.title,
  'content': instance.content,
  'status': instance.status,
  'category': instance.category,
  'colorHex': instance.colorHex,
  'categoryId': instance.categoryId,
  'type': instance.type,
  'priority': instance.priority,
  'startDate': instance.startDate,
  'endDate': instance.endDate,
  'daysOfWeek': instance.daysOfWeek,
  'alertTime': instance.alarmTime,
  'excludedDates': instance.excludedDates,
  'masterTodoId': instance.masterTodoId,
  'recurrenceGroupId': instance.recurrenceGroupId,
  'earnedCoin': instance.earnedCoin,
  'rewarded': instance.rewarded,
  'walletBalance': instance.walletBalance,
};
