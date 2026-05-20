// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'todo_update_request_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TodoUpdateRequestDto _$TodoUpdateRequestDtoFromJson(Map<String, dynamic> json) {
  return _TodoUpdateRequestDto.fromJson(json);
}

/// @nodoc
mixin _$TodoUpdateRequestDto {
  String get title => throw _privateConstructorUsedError;
  String? get content =>
      throw _privateConstructorUsedError; // 서버는 카테고리 이름(String)이 아닌 categoryId(int)를 요구 — T04-005 방지.
  // null 이면 JSON 에서 생략 → 서버 기존 카테고리 유지.
  @JsonKey(name: 'categoryId', includeIfNull: false)
  int? get categoryId => throw _privateConstructorUsedError;
  String get type =>
      throw _privateConstructorUsedError; // NORMAL, RECURRING, PERIOD
  String? get startDate => throw _privateConstructorUsedError; // YYYY-MM-DD 형식
  String? get endDate => throw _privateConstructorUsedError; // YYYY-MM-DD 형식
  @JsonKey(includeIfNull: false)
  Set<String>? get daysOfWeek => throw _privateConstructorUsedError;
  @JsonKey(name: 'alertTime')
  String? get alarmTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'clearAlertTime', includeIfNull: false)
  bool? get clearAlertTime => throw _privateConstructorUsedError;

  /// Serializes this TodoUpdateRequestDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TodoUpdateRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TodoUpdateRequestDtoCopyWith<TodoUpdateRequestDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TodoUpdateRequestDtoCopyWith<$Res> {
  factory $TodoUpdateRequestDtoCopyWith(
    TodoUpdateRequestDto value,
    $Res Function(TodoUpdateRequestDto) then,
  ) = _$TodoUpdateRequestDtoCopyWithImpl<$Res, TodoUpdateRequestDto>;
  @useResult
  $Res call({
    String title,
    String? content,
    @JsonKey(name: 'categoryId', includeIfNull: false) int? categoryId,
    String type,
    String? startDate,
    String? endDate,
    @JsonKey(includeIfNull: false) Set<String>? daysOfWeek,
    @JsonKey(name: 'alertTime') String? alarmTime,
    @JsonKey(name: 'clearAlertTime', includeIfNull: false) bool? clearAlertTime,
  });
}

/// @nodoc
class _$TodoUpdateRequestDtoCopyWithImpl<
  $Res,
  $Val extends TodoUpdateRequestDto
>
    implements $TodoUpdateRequestDtoCopyWith<$Res> {
  _$TodoUpdateRequestDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TodoUpdateRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? content = freezed,
    Object? categoryId = freezed,
    Object? type = null,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? daysOfWeek = freezed,
    Object? alarmTime = freezed,
    Object? clearAlertTime = freezed,
  }) {
    return _then(
      _value.copyWith(
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            content: freezed == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String?,
            categoryId: freezed == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
                      as int?,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            startDate: freezed == startDate
                ? _value.startDate
                : startDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            endDate: freezed == endDate
                ? _value.endDate
                : endDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            daysOfWeek: freezed == daysOfWeek
                ? _value.daysOfWeek
                : daysOfWeek // ignore: cast_nullable_to_non_nullable
                      as Set<String>?,
            alarmTime: freezed == alarmTime
                ? _value.alarmTime
                : alarmTime // ignore: cast_nullable_to_non_nullable
                      as String?,
            clearAlertTime: freezed == clearAlertTime
                ? _value.clearAlertTime
                : clearAlertTime // ignore: cast_nullable_to_non_nullable
                      as bool?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TodoUpdateRequestDtoImplCopyWith<$Res>
    implements $TodoUpdateRequestDtoCopyWith<$Res> {
  factory _$$TodoUpdateRequestDtoImplCopyWith(
    _$TodoUpdateRequestDtoImpl value,
    $Res Function(_$TodoUpdateRequestDtoImpl) then,
  ) = __$$TodoUpdateRequestDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String title,
    String? content,
    @JsonKey(name: 'categoryId', includeIfNull: false) int? categoryId,
    String type,
    String? startDate,
    String? endDate,
    @JsonKey(includeIfNull: false) Set<String>? daysOfWeek,
    @JsonKey(name: 'alertTime') String? alarmTime,
    @JsonKey(name: 'clearAlertTime', includeIfNull: false) bool? clearAlertTime,
  });
}

/// @nodoc
class __$$TodoUpdateRequestDtoImplCopyWithImpl<$Res>
    extends _$TodoUpdateRequestDtoCopyWithImpl<$Res, _$TodoUpdateRequestDtoImpl>
    implements _$$TodoUpdateRequestDtoImplCopyWith<$Res> {
  __$$TodoUpdateRequestDtoImplCopyWithImpl(
    _$TodoUpdateRequestDtoImpl _value,
    $Res Function(_$TodoUpdateRequestDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TodoUpdateRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? content = freezed,
    Object? categoryId = freezed,
    Object? type = null,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? daysOfWeek = freezed,
    Object? alarmTime = freezed,
    Object? clearAlertTime = freezed,
  }) {
    return _then(
      _$TodoUpdateRequestDtoImpl(
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        content: freezed == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String?,
        categoryId: freezed == categoryId
            ? _value.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as int?,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        startDate: freezed == startDate
            ? _value.startDate
            : startDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        endDate: freezed == endDate
            ? _value.endDate
            : endDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        daysOfWeek: freezed == daysOfWeek
            ? _value._daysOfWeek
            : daysOfWeek // ignore: cast_nullable_to_non_nullable
                  as Set<String>?,
        alarmTime: freezed == alarmTime
            ? _value.alarmTime
            : alarmTime // ignore: cast_nullable_to_non_nullable
                  as String?,
        clearAlertTime: freezed == clearAlertTime
            ? _value.clearAlertTime
            : clearAlertTime // ignore: cast_nullable_to_non_nullable
                  as bool?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TodoUpdateRequestDtoImpl implements _TodoUpdateRequestDto {
  const _$TodoUpdateRequestDtoImpl({
    required this.title,
    this.content,
    @JsonKey(name: 'categoryId', includeIfNull: false) this.categoryId,
    required this.type,
    required this.startDate,
    this.endDate,
    @JsonKey(includeIfNull: false) final Set<String>? daysOfWeek,
    @JsonKey(name: 'alertTime') this.alarmTime,
    @JsonKey(name: 'clearAlertTime', includeIfNull: false) this.clearAlertTime,
  }) : _daysOfWeek = daysOfWeek;

  factory _$TodoUpdateRequestDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$TodoUpdateRequestDtoImplFromJson(json);

  @override
  final String title;
  @override
  final String? content;
  // 서버는 카테고리 이름(String)이 아닌 categoryId(int)를 요구 — T04-005 방지.
  // null 이면 JSON 에서 생략 → 서버 기존 카테고리 유지.
  @override
  @JsonKey(name: 'categoryId', includeIfNull: false)
  final int? categoryId;
  @override
  final String type;
  // NORMAL, RECURRING, PERIOD
  @override
  final String? startDate;
  // YYYY-MM-DD 형식
  @override
  final String? endDate;
  // YYYY-MM-DD 형식
  final Set<String>? _daysOfWeek;
  // YYYY-MM-DD 형식
  @override
  @JsonKey(includeIfNull: false)
  Set<String>? get daysOfWeek {
    final value = _daysOfWeek;
    if (value == null) return null;
    if (_daysOfWeek is EqualUnmodifiableSetView) return _daysOfWeek;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(value);
  }

  @override
  @JsonKey(name: 'alertTime')
  final String? alarmTime;
  @override
  @JsonKey(name: 'clearAlertTime', includeIfNull: false)
  final bool? clearAlertTime;

  @override
  String toString() {
    return 'TodoUpdateRequestDto(title: $title, content: $content, categoryId: $categoryId, type: $type, startDate: $startDate, endDate: $endDate, daysOfWeek: $daysOfWeek, alarmTime: $alarmTime, clearAlertTime: $clearAlertTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TodoUpdateRequestDtoImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            const DeepCollectionEquality().equals(
              other._daysOfWeek,
              _daysOfWeek,
            ) &&
            (identical(other.alarmTime, alarmTime) ||
                other.alarmTime == alarmTime) &&
            (identical(other.clearAlertTime, clearAlertTime) ||
                other.clearAlertTime == clearAlertTime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    title,
    content,
    categoryId,
    type,
    startDate,
    endDate,
    const DeepCollectionEquality().hash(_daysOfWeek),
    alarmTime,
    clearAlertTime,
  );

  /// Create a copy of TodoUpdateRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TodoUpdateRequestDtoImplCopyWith<_$TodoUpdateRequestDtoImpl>
  get copyWith =>
      __$$TodoUpdateRequestDtoImplCopyWithImpl<_$TodoUpdateRequestDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TodoUpdateRequestDtoImplToJson(this);
  }
}

abstract class _TodoUpdateRequestDto implements TodoUpdateRequestDto {
  const factory _TodoUpdateRequestDto({
    required final String title,
    final String? content,
    @JsonKey(name: 'categoryId', includeIfNull: false) final int? categoryId,
    required final String type,
    required final String? startDate,
    final String? endDate,
    @JsonKey(includeIfNull: false) final Set<String>? daysOfWeek,
    @JsonKey(name: 'alertTime') final String? alarmTime,
    @JsonKey(name: 'clearAlertTime', includeIfNull: false)
    final bool? clearAlertTime,
  }) = _$TodoUpdateRequestDtoImpl;

  factory _TodoUpdateRequestDto.fromJson(Map<String, dynamic> json) =
      _$TodoUpdateRequestDtoImpl.fromJson;

  @override
  String get title;
  @override
  String? get content; // 서버는 카테고리 이름(String)이 아닌 categoryId(int)를 요구 — T04-005 방지.
  // null 이면 JSON 에서 생략 → 서버 기존 카테고리 유지.
  @override
  @JsonKey(name: 'categoryId', includeIfNull: false)
  int? get categoryId;
  @override
  String get type; // NORMAL, RECURRING, PERIOD
  @override
  String? get startDate; // YYYY-MM-DD 형식
  @override
  String? get endDate; // YYYY-MM-DD 형식
  @override
  @JsonKey(includeIfNull: false)
  Set<String>? get daysOfWeek;
  @override
  @JsonKey(name: 'alertTime')
  String? get alarmTime;
  @override
  @JsonKey(name: 'clearAlertTime', includeIfNull: false)
  bool? get clearAlertTime;

  /// Create a copy of TodoUpdateRequestDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TodoUpdateRequestDtoImplCopyWith<_$TodoUpdateRequestDtoImpl>
  get copyWith => throw _privateConstructorUsedError;
}
