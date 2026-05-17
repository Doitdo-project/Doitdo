// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notice_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NoticeRespImpl _$$NoticeRespImplFromJson(Map<String, dynamic> json) =>
    _$NoticeRespImpl(
      noticeId: (json['noticeId'] as num).toInt(),
      title: json['title'] as String,
      content: json['content'] as String,
      startedAt: json['startedAt'] as String?,
      endedAt: json['endedAt'] as String?,
      createdAt: json['createdAt'] as String?,
    );

Map<String, dynamic> _$$NoticeRespImplToJson(_$NoticeRespImpl instance) =>
    <String, dynamic>{
      'noticeId': instance.noticeId,
      'title': instance.title,
      'content': instance.content,
      'startedAt': instance.startedAt,
      'endedAt': instance.endedAt,
      'createdAt': instance.createdAt,
    };

_$NoticeListRespImpl _$$NoticeListRespImplFromJson(Map<String, dynamic> json) =>
    _$NoticeListRespImpl(
      items: (json['items'] as List<dynamic>)
          .map((e) => NoticeResp.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$NoticeListRespImplToJson(
  _$NoticeListRespImpl instance,
) => <String, dynamic>{'items': instance.items};

_$LatestPopupRespImpl _$$LatestPopupRespImplFromJson(
  Map<String, dynamic> json,
) => _$LatestPopupRespImpl(
  show: json['show'] as bool,
  notice: json['notice'] == null
      ? null
      : NoticeResp.fromJson(json['notice'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$LatestPopupRespImplToJson(
  _$LatestPopupRespImpl instance,
) => <String, dynamic>{'show': instance.show, 'notice': instance.notice};
