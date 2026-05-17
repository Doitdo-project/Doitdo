// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notice_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

NoticeResp _$NoticeRespFromJson(Map<String, dynamic> json) {
  return _NoticeResp.fromJson(json);
}

/// @nodoc
mixin _$NoticeResp {
  int get noticeId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  String? get startedAt => throw _privateConstructorUsedError;
  String? get endedAt => throw _privateConstructorUsedError;
  String? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this NoticeResp to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NoticeResp
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NoticeRespCopyWith<NoticeResp> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NoticeRespCopyWith<$Res> {
  factory $NoticeRespCopyWith(
    NoticeResp value,
    $Res Function(NoticeResp) then,
  ) = _$NoticeRespCopyWithImpl<$Res, NoticeResp>;
  @useResult
  $Res call({
    int noticeId,
    String title,
    String content,
    String? startedAt,
    String? endedAt,
    String? createdAt,
  });
}

/// @nodoc
class _$NoticeRespCopyWithImpl<$Res, $Val extends NoticeResp>
    implements $NoticeRespCopyWith<$Res> {
  _$NoticeRespCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NoticeResp
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? noticeId = null,
    Object? title = null,
    Object? content = null,
    Object? startedAt = freezed,
    Object? endedAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            noticeId: null == noticeId
                ? _value.noticeId
                : noticeId // ignore: cast_nullable_to_non_nullable
                      as int,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            content: null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String,
            startedAt: freezed == startedAt
                ? _value.startedAt
                : startedAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            endedAt: freezed == endedAt
                ? _value.endedAt
                : endedAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NoticeRespImplCopyWith<$Res>
    implements $NoticeRespCopyWith<$Res> {
  factory _$$NoticeRespImplCopyWith(
    _$NoticeRespImpl value,
    $Res Function(_$NoticeRespImpl) then,
  ) = __$$NoticeRespImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int noticeId,
    String title,
    String content,
    String? startedAt,
    String? endedAt,
    String? createdAt,
  });
}

/// @nodoc
class __$$NoticeRespImplCopyWithImpl<$Res>
    extends _$NoticeRespCopyWithImpl<$Res, _$NoticeRespImpl>
    implements _$$NoticeRespImplCopyWith<$Res> {
  __$$NoticeRespImplCopyWithImpl(
    _$NoticeRespImpl _value,
    $Res Function(_$NoticeRespImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NoticeResp
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? noticeId = null,
    Object? title = null,
    Object? content = null,
    Object? startedAt = freezed,
    Object? endedAt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$NoticeRespImpl(
        noticeId: null == noticeId
            ? _value.noticeId
            : noticeId // ignore: cast_nullable_to_non_nullable
                  as int,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
        startedAt: freezed == startedAt
            ? _value.startedAt
            : startedAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        endedAt: freezed == endedAt
            ? _value.endedAt
            : endedAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NoticeRespImpl implements _NoticeResp {
  const _$NoticeRespImpl({
    required this.noticeId,
    required this.title,
    required this.content,
    this.startedAt,
    this.endedAt,
    this.createdAt,
  });

  factory _$NoticeRespImpl.fromJson(Map<String, dynamic> json) =>
      _$$NoticeRespImplFromJson(json);

  @override
  final int noticeId;
  @override
  final String title;
  @override
  final String content;
  @override
  final String? startedAt;
  @override
  final String? endedAt;
  @override
  final String? createdAt;

  @override
  String toString() {
    return 'NoticeResp(noticeId: $noticeId, title: $title, content: $content, startedAt: $startedAt, endedAt: $endedAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NoticeRespImpl &&
            (identical(other.noticeId, noticeId) ||
                other.noticeId == noticeId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.endedAt, endedAt) || other.endedAt == endedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    noticeId,
    title,
    content,
    startedAt,
    endedAt,
    createdAt,
  );

  /// Create a copy of NoticeResp
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NoticeRespImplCopyWith<_$NoticeRespImpl> get copyWith =>
      __$$NoticeRespImplCopyWithImpl<_$NoticeRespImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NoticeRespImplToJson(this);
  }
}

abstract class _NoticeResp implements NoticeResp {
  const factory _NoticeResp({
    required final int noticeId,
    required final String title,
    required final String content,
    final String? startedAt,
    final String? endedAt,
    final String? createdAt,
  }) = _$NoticeRespImpl;

  factory _NoticeResp.fromJson(Map<String, dynamic> json) =
      _$NoticeRespImpl.fromJson;

  @override
  int get noticeId;
  @override
  String get title;
  @override
  String get content;
  @override
  String? get startedAt;
  @override
  String? get endedAt;
  @override
  String? get createdAt;

  /// Create a copy of NoticeResp
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NoticeRespImplCopyWith<_$NoticeRespImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

NoticeListResp _$NoticeListRespFromJson(Map<String, dynamic> json) {
  return _NoticeListResp.fromJson(json);
}

/// @nodoc
mixin _$NoticeListResp {
  List<NoticeResp> get items => throw _privateConstructorUsedError;

  /// Serializes this NoticeListResp to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NoticeListResp
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NoticeListRespCopyWith<NoticeListResp> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NoticeListRespCopyWith<$Res> {
  factory $NoticeListRespCopyWith(
    NoticeListResp value,
    $Res Function(NoticeListResp) then,
  ) = _$NoticeListRespCopyWithImpl<$Res, NoticeListResp>;
  @useResult
  $Res call({List<NoticeResp> items});
}

/// @nodoc
class _$NoticeListRespCopyWithImpl<$Res, $Val extends NoticeListResp>
    implements $NoticeListRespCopyWith<$Res> {
  _$NoticeListRespCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NoticeListResp
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? items = null}) {
    return _then(
      _value.copyWith(
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<NoticeResp>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NoticeListRespImplCopyWith<$Res>
    implements $NoticeListRespCopyWith<$Res> {
  factory _$$NoticeListRespImplCopyWith(
    _$NoticeListRespImpl value,
    $Res Function(_$NoticeListRespImpl) then,
  ) = __$$NoticeListRespImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<NoticeResp> items});
}

/// @nodoc
class __$$NoticeListRespImplCopyWithImpl<$Res>
    extends _$NoticeListRespCopyWithImpl<$Res, _$NoticeListRespImpl>
    implements _$$NoticeListRespImplCopyWith<$Res> {
  __$$NoticeListRespImplCopyWithImpl(
    _$NoticeListRespImpl _value,
    $Res Function(_$NoticeListRespImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NoticeListResp
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? items = null}) {
    return _then(
      _$NoticeListRespImpl(
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<NoticeResp>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NoticeListRespImpl implements _NoticeListResp {
  const _$NoticeListRespImpl({required final List<NoticeResp> items})
    : _items = items;

  factory _$NoticeListRespImpl.fromJson(Map<String, dynamic> json) =>
      _$$NoticeListRespImplFromJson(json);

  final List<NoticeResp> _items;
  @override
  List<NoticeResp> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'NoticeListResp(items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NoticeListRespImpl &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_items));

  /// Create a copy of NoticeListResp
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NoticeListRespImplCopyWith<_$NoticeListRespImpl> get copyWith =>
      __$$NoticeListRespImplCopyWithImpl<_$NoticeListRespImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$NoticeListRespImplToJson(this);
  }
}

abstract class _NoticeListResp implements NoticeListResp {
  const factory _NoticeListResp({required final List<NoticeResp> items}) =
      _$NoticeListRespImpl;

  factory _NoticeListResp.fromJson(Map<String, dynamic> json) =
      _$NoticeListRespImpl.fromJson;

  @override
  List<NoticeResp> get items;

  /// Create a copy of NoticeListResp
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NoticeListRespImplCopyWith<_$NoticeListRespImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LatestPopupResp _$LatestPopupRespFromJson(Map<String, dynamic> json) {
  return _LatestPopupResp.fromJson(json);
}

/// @nodoc
mixin _$LatestPopupResp {
  bool get show => throw _privateConstructorUsedError;
  NoticeResp? get notice => throw _privateConstructorUsedError;

  /// Serializes this LatestPopupResp to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LatestPopupResp
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LatestPopupRespCopyWith<LatestPopupResp> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LatestPopupRespCopyWith<$Res> {
  factory $LatestPopupRespCopyWith(
    LatestPopupResp value,
    $Res Function(LatestPopupResp) then,
  ) = _$LatestPopupRespCopyWithImpl<$Res, LatestPopupResp>;
  @useResult
  $Res call({bool show, NoticeResp? notice});

  $NoticeRespCopyWith<$Res>? get notice;
}

/// @nodoc
class _$LatestPopupRespCopyWithImpl<$Res, $Val extends LatestPopupResp>
    implements $LatestPopupRespCopyWith<$Res> {
  _$LatestPopupRespCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LatestPopupResp
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? show = null, Object? notice = freezed}) {
    return _then(
      _value.copyWith(
            show: null == show
                ? _value.show
                : show // ignore: cast_nullable_to_non_nullable
                      as bool,
            notice: freezed == notice
                ? _value.notice
                : notice // ignore: cast_nullable_to_non_nullable
                      as NoticeResp?,
          )
          as $Val,
    );
  }

  /// Create a copy of LatestPopupResp
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NoticeRespCopyWith<$Res>? get notice {
    if (_value.notice == null) {
      return null;
    }

    return $NoticeRespCopyWith<$Res>(_value.notice!, (value) {
      return _then(_value.copyWith(notice: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$LatestPopupRespImplCopyWith<$Res>
    implements $LatestPopupRespCopyWith<$Res> {
  factory _$$LatestPopupRespImplCopyWith(
    _$LatestPopupRespImpl value,
    $Res Function(_$LatestPopupRespImpl) then,
  ) = __$$LatestPopupRespImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool show, NoticeResp? notice});

  @override
  $NoticeRespCopyWith<$Res>? get notice;
}

/// @nodoc
class __$$LatestPopupRespImplCopyWithImpl<$Res>
    extends _$LatestPopupRespCopyWithImpl<$Res, _$LatestPopupRespImpl>
    implements _$$LatestPopupRespImplCopyWith<$Res> {
  __$$LatestPopupRespImplCopyWithImpl(
    _$LatestPopupRespImpl _value,
    $Res Function(_$LatestPopupRespImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LatestPopupResp
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? show = null, Object? notice = freezed}) {
    return _then(
      _$LatestPopupRespImpl(
        show: null == show
            ? _value.show
            : show // ignore: cast_nullable_to_non_nullable
                  as bool,
        notice: freezed == notice
            ? _value.notice
            : notice // ignore: cast_nullable_to_non_nullable
                  as NoticeResp?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LatestPopupRespImpl implements _LatestPopupResp {
  const _$LatestPopupRespImpl({required this.show, this.notice});

  factory _$LatestPopupRespImpl.fromJson(Map<String, dynamic> json) =>
      _$$LatestPopupRespImplFromJson(json);

  @override
  final bool show;
  @override
  final NoticeResp? notice;

  @override
  String toString() {
    return 'LatestPopupResp(show: $show, notice: $notice)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LatestPopupRespImpl &&
            (identical(other.show, show) || other.show == show) &&
            (identical(other.notice, notice) || other.notice == notice));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, show, notice);

  /// Create a copy of LatestPopupResp
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LatestPopupRespImplCopyWith<_$LatestPopupRespImpl> get copyWith =>
      __$$LatestPopupRespImplCopyWithImpl<_$LatestPopupRespImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$LatestPopupRespImplToJson(this);
  }
}

abstract class _LatestPopupResp implements LatestPopupResp {
  const factory _LatestPopupResp({
    required final bool show,
    final NoticeResp? notice,
  }) = _$LatestPopupRespImpl;

  factory _LatestPopupResp.fromJson(Map<String, dynamic> json) =
      _$LatestPopupRespImpl.fromJson;

  @override
  bool get show;
  @override
  NoticeResp? get notice;

  /// Create a copy of LatestPopupResp
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LatestPopupRespImplCopyWith<_$LatestPopupRespImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
