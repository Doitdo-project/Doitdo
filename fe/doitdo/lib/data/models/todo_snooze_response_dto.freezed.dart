// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'todo_snooze_response_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TodoSnoozeResponseDto _$TodoSnoozeResponseDtoFromJson(
  Map<String, dynamic> json,
) {
  return _TodoSnoozeResponseDto.fromJson(json);
}

/// @nodoc
mixin _$TodoSnoozeResponseDto {
  int get todoId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get content => throw _privateConstructorUsedError;
  String? get category => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  int? get priority => throw _privateConstructorUsedError;
  String get startDate => throw _privateConstructorUsedError;
  String? get endDate => throw _privateConstructorUsedError;
  int? get period => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get updatedAt => throw _privateConstructorUsedError;
  int get snoozedDays => throw _privateConstructorUsedError;

  /// Serializes this TodoSnoozeResponseDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TodoSnoozeResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TodoSnoozeResponseDtoCopyWith<TodoSnoozeResponseDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TodoSnoozeResponseDtoCopyWith<$Res> {
  factory $TodoSnoozeResponseDtoCopyWith(
    TodoSnoozeResponseDto value,
    $Res Function(TodoSnoozeResponseDto) then,
  ) = _$TodoSnoozeResponseDtoCopyWithImpl<$Res, TodoSnoozeResponseDto>;
  @useResult
  $Res call({
    int todoId,
    String title,
    String? content,
    String? category,
    String type,
    int? priority,
    String startDate,
    String? endDate,
    int? period,
    String status,
    String updatedAt,
    int snoozedDays,
  });
}

/// @nodoc
class _$TodoSnoozeResponseDtoCopyWithImpl<
  $Res,
  $Val extends TodoSnoozeResponseDto
>
    implements $TodoSnoozeResponseDtoCopyWith<$Res> {
  _$TodoSnoozeResponseDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TodoSnoozeResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? todoId = null,
    Object? title = null,
    Object? content = freezed,
    Object? category = freezed,
    Object? type = null,
    Object? priority = freezed,
    Object? startDate = null,
    Object? endDate = freezed,
    Object? period = freezed,
    Object? status = null,
    Object? updatedAt = null,
    Object? snoozedDays = null,
  }) {
    return _then(
      _value.copyWith(
            todoId: null == todoId
                ? _value.todoId
                : todoId // ignore: cast_nullable_to_non_nullable
                      as int,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            content: freezed == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String?,
            category: freezed == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String?,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            priority: freezed == priority
                ? _value.priority
                : priority // ignore: cast_nullable_to_non_nullable
                      as int?,
            startDate: null == startDate
                ? _value.startDate
                : startDate // ignore: cast_nullable_to_non_nullable
                      as String,
            endDate: freezed == endDate
                ? _value.endDate
                : endDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            period: freezed == period
                ? _value.period
                : period // ignore: cast_nullable_to_non_nullable
                      as int?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as String,
            snoozedDays: null == snoozedDays
                ? _value.snoozedDays
                : snoozedDays // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TodoSnoozeResponseDtoImplCopyWith<$Res>
    implements $TodoSnoozeResponseDtoCopyWith<$Res> {
  factory _$$TodoSnoozeResponseDtoImplCopyWith(
    _$TodoSnoozeResponseDtoImpl value,
    $Res Function(_$TodoSnoozeResponseDtoImpl) then,
  ) = __$$TodoSnoozeResponseDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int todoId,
    String title,
    String? content,
    String? category,
    String type,
    int? priority,
    String startDate,
    String? endDate,
    int? period,
    String status,
    String updatedAt,
    int snoozedDays,
  });
}

/// @nodoc
class __$$TodoSnoozeResponseDtoImplCopyWithImpl<$Res>
    extends
        _$TodoSnoozeResponseDtoCopyWithImpl<$Res, _$TodoSnoozeResponseDtoImpl>
    implements _$$TodoSnoozeResponseDtoImplCopyWith<$Res> {
  __$$TodoSnoozeResponseDtoImplCopyWithImpl(
    _$TodoSnoozeResponseDtoImpl _value,
    $Res Function(_$TodoSnoozeResponseDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TodoSnoozeResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? todoId = null,
    Object? title = null,
    Object? content = freezed,
    Object? category = freezed,
    Object? type = null,
    Object? priority = freezed,
    Object? startDate = null,
    Object? endDate = freezed,
    Object? period = freezed,
    Object? status = null,
    Object? updatedAt = null,
    Object? snoozedDays = null,
  }) {
    return _then(
      _$TodoSnoozeResponseDtoImpl(
        todoId: null == todoId
            ? _value.todoId
            : todoId // ignore: cast_nullable_to_non_nullable
                  as int,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        content: freezed == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String?,
        category: freezed == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String?,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        priority: freezed == priority
            ? _value.priority
            : priority // ignore: cast_nullable_to_non_nullable
                  as int?,
        startDate: null == startDate
            ? _value.startDate
            : startDate // ignore: cast_nullable_to_non_nullable
                  as String,
        endDate: freezed == endDate
            ? _value.endDate
            : endDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        period: freezed == period
            ? _value.period
            : period // ignore: cast_nullable_to_non_nullable
                  as int?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as String,
        snoozedDays: null == snoozedDays
            ? _value.snoozedDays
            : snoozedDays // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TodoSnoozeResponseDtoImpl implements _TodoSnoozeResponseDto {
  const _$TodoSnoozeResponseDtoImpl({
    required this.todoId,
    required this.title,
    this.content,
    this.category,
    required this.type,
    this.priority,
    required this.startDate,
    this.endDate,
    this.period,
    required this.status,
    required this.updatedAt,
    required this.snoozedDays,
  });

  factory _$TodoSnoozeResponseDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$TodoSnoozeResponseDtoImplFromJson(json);

  @override
  final int todoId;
  @override
  final String title;
  @override
  final String? content;
  @override
  final String? category;
  @override
  final String type;
  @override
  final int? priority;
  @override
  final String startDate;
  @override
  final String? endDate;
  @override
  final int? period;
  @override
  final String status;
  @override
  final String updatedAt;
  @override
  final int snoozedDays;

  @override
  String toString() {
    return 'TodoSnoozeResponseDto(todoId: $todoId, title: $title, content: $content, category: $category, type: $type, priority: $priority, startDate: $startDate, endDate: $endDate, period: $period, status: $status, updatedAt: $updatedAt, snoozedDays: $snoozedDays)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TodoSnoozeResponseDtoImpl &&
            (identical(other.todoId, todoId) || other.todoId == todoId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.period, period) || other.period == period) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.snoozedDays, snoozedDays) ||
                other.snoozedDays == snoozedDays));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    todoId,
    title,
    content,
    category,
    type,
    priority,
    startDate,
    endDate,
    period,
    status,
    updatedAt,
    snoozedDays,
  );

  /// Create a copy of TodoSnoozeResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TodoSnoozeResponseDtoImplCopyWith<_$TodoSnoozeResponseDtoImpl>
  get copyWith =>
      __$$TodoSnoozeResponseDtoImplCopyWithImpl<_$TodoSnoozeResponseDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TodoSnoozeResponseDtoImplToJson(this);
  }
}

abstract class _TodoSnoozeResponseDto implements TodoSnoozeResponseDto {
  const factory _TodoSnoozeResponseDto({
    required final int todoId,
    required final String title,
    final String? content,
    final String? category,
    required final String type,
    final int? priority,
    required final String startDate,
    final String? endDate,
    final int? period,
    required final String status,
    required final String updatedAt,
    required final int snoozedDays,
  }) = _$TodoSnoozeResponseDtoImpl;

  factory _TodoSnoozeResponseDto.fromJson(Map<String, dynamic> json) =
      _$TodoSnoozeResponseDtoImpl.fromJson;

  @override
  int get todoId;
  @override
  String get title;
  @override
  String? get content;
  @override
  String? get category;
  @override
  String get type;
  @override
  int? get priority;
  @override
  String get startDate;
  @override
  String? get endDate;
  @override
  int? get period;
  @override
  String get status;
  @override
  String get updatedAt;
  @override
  int get snoozedDays;

  /// Create a copy of TodoSnoozeResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TodoSnoozeResponseDtoImplCopyWith<_$TodoSnoozeResponseDtoImpl>
  get copyWith => throw _privateConstructorUsedError;
}
