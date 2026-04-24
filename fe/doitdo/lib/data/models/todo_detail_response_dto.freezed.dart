// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'todo_detail_response_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TodoDetailResponseDto _$TodoDetailResponseDtoFromJson(
  Map<String, dynamic> json,
) {
  return _TodoDetailResponseDto.fromJson(json);
}

/// @nodoc
mixin _$TodoDetailResponseDto {
  int get todoId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get content => throw _privateConstructorUsedError; // = memo
  String get status => throw _privateConstructorUsedError;
  String? get category => throw _privateConstructorUsedError;
  String get type =>
      throw _privateConstructorUsedError; // NORMAL, RECURRING, PERIOD
  int get priority => throw _privateConstructorUsedError;
  String? get startDate =>
      throw _privateConstructorUsedError; // 언제가 할 일 대응을 위해 Nullable로 지정
  String? get endDate => throw _privateConstructorUsedError;
  int? get period => throw _privateConstructorUsedError;

  /// Serializes this TodoDetailResponseDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TodoDetailResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TodoDetailResponseDtoCopyWith<TodoDetailResponseDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TodoDetailResponseDtoCopyWith<$Res> {
  factory $TodoDetailResponseDtoCopyWith(
    TodoDetailResponseDto value,
    $Res Function(TodoDetailResponseDto) then,
  ) = _$TodoDetailResponseDtoCopyWithImpl<$Res, TodoDetailResponseDto>;
  @useResult
  $Res call({
    int todoId,
    String title,
    String? content,
    String status,
    String? category,
    String type,
    int priority,
    String? startDate,
    String? endDate,
    int? period,
  });
}

/// @nodoc
class _$TodoDetailResponseDtoCopyWithImpl<
  $Res,
  $Val extends TodoDetailResponseDto
>
    implements $TodoDetailResponseDtoCopyWith<$Res> {
  _$TodoDetailResponseDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TodoDetailResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? todoId = null,
    Object? title = null,
    Object? content = freezed,
    Object? status = null,
    Object? category = freezed,
    Object? type = null,
    Object? priority = null,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? period = freezed,
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
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            category: freezed == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String?,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            priority: null == priority
                ? _value.priority
                : priority // ignore: cast_nullable_to_non_nullable
                      as int,
            startDate: freezed == startDate
                ? _value.startDate
                : startDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            endDate: freezed == endDate
                ? _value.endDate
                : endDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            period: freezed == period
                ? _value.period
                : period // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TodoDetailResponseDtoImplCopyWith<$Res>
    implements $TodoDetailResponseDtoCopyWith<$Res> {
  factory _$$TodoDetailResponseDtoImplCopyWith(
    _$TodoDetailResponseDtoImpl value,
    $Res Function(_$TodoDetailResponseDtoImpl) then,
  ) = __$$TodoDetailResponseDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int todoId,
    String title,
    String? content,
    String status,
    String? category,
    String type,
    int priority,
    String? startDate,
    String? endDate,
    int? period,
  });
}

/// @nodoc
class __$$TodoDetailResponseDtoImplCopyWithImpl<$Res>
    extends
        _$TodoDetailResponseDtoCopyWithImpl<$Res, _$TodoDetailResponseDtoImpl>
    implements _$$TodoDetailResponseDtoImplCopyWith<$Res> {
  __$$TodoDetailResponseDtoImplCopyWithImpl(
    _$TodoDetailResponseDtoImpl _value,
    $Res Function(_$TodoDetailResponseDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TodoDetailResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? todoId = null,
    Object? title = null,
    Object? content = freezed,
    Object? status = null,
    Object? category = freezed,
    Object? type = null,
    Object? priority = null,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? period = freezed,
  }) {
    return _then(
      _$TodoDetailResponseDtoImpl(
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
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        category: freezed == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String?,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        priority: null == priority
            ? _value.priority
            : priority // ignore: cast_nullable_to_non_nullable
                  as int,
        startDate: freezed == startDate
            ? _value.startDate
            : startDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        endDate: freezed == endDate
            ? _value.endDate
            : endDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        period: freezed == period
            ? _value.period
            : period // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TodoDetailResponseDtoImpl implements _TodoDetailResponseDto {
  const _$TodoDetailResponseDtoImpl({
    required this.todoId,
    required this.title,
    this.content,
    required this.status,
    this.category,
    required this.type,
    required this.priority,
    this.startDate,
    this.endDate,
    this.period,
  });

  factory _$TodoDetailResponseDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$TodoDetailResponseDtoImplFromJson(json);

  @override
  final int todoId;
  @override
  final String title;
  @override
  final String? content;
  // = memo
  @override
  final String status;
  @override
  final String? category;
  @override
  final String type;
  // NORMAL, RECURRING, PERIOD
  @override
  final int priority;
  @override
  final String? startDate;
  // 언제가 할 일 대응을 위해 Nullable로 지정
  @override
  final String? endDate;
  @override
  final int? period;

  @override
  String toString() {
    return 'TodoDetailResponseDto(todoId: $todoId, title: $title, content: $content, status: $status, category: $category, type: $type, priority: $priority, startDate: $startDate, endDate: $endDate, period: $period)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TodoDetailResponseDtoImpl &&
            (identical(other.todoId, todoId) || other.todoId == todoId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.period, period) || other.period == period));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    todoId,
    title,
    content,
    status,
    category,
    type,
    priority,
    startDate,
    endDate,
    period,
  );

  /// Create a copy of TodoDetailResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TodoDetailResponseDtoImplCopyWith<_$TodoDetailResponseDtoImpl>
  get copyWith =>
      __$$TodoDetailResponseDtoImplCopyWithImpl<_$TodoDetailResponseDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TodoDetailResponseDtoImplToJson(this);
  }
}

abstract class _TodoDetailResponseDto implements TodoDetailResponseDto {
  const factory _TodoDetailResponseDto({
    required final int todoId,
    required final String title,
    final String? content,
    required final String status,
    final String? category,
    required final String type,
    required final int priority,
    final String? startDate,
    final String? endDate,
    final int? period,
  }) = _$TodoDetailResponseDtoImpl;

  factory _TodoDetailResponseDto.fromJson(Map<String, dynamic> json) =
      _$TodoDetailResponseDtoImpl.fromJson;

  @override
  int get todoId;
  @override
  String get title;
  @override
  String? get content; // = memo
  @override
  String get status;
  @override
  String? get category;
  @override
  String get type; // NORMAL, RECURRING, PERIOD
  @override
  int get priority;
  @override
  String? get startDate; // 언제가 할 일 대응을 위해 Nullable로 지정
  @override
  String? get endDate;
  @override
  int? get period;

  /// Create a copy of TodoDetailResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TodoDetailResponseDtoImplCopyWith<_$TodoDetailResponseDtoImpl>
  get copyWith => throw _privateConstructorUsedError;
}
