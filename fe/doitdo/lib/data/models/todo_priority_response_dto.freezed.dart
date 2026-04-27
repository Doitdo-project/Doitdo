// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'todo_priority_response_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TodoPriorityResponseDto _$TodoPriorityResponseDtoFromJson(
  Map<String, dynamic> json,
) {
  return _TodoPriorityResponseDto.fromJson(json);
}

/// @nodoc
mixin _$TodoPriorityResponseDto {
  int get todoId => throw _privateConstructorUsedError;
  int get priority => throw _privateConstructorUsedError;
  String get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this TodoPriorityResponseDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TodoPriorityResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TodoPriorityResponseDtoCopyWith<TodoPriorityResponseDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TodoPriorityResponseDtoCopyWith<$Res> {
  factory $TodoPriorityResponseDtoCopyWith(
    TodoPriorityResponseDto value,
    $Res Function(TodoPriorityResponseDto) then,
  ) = _$TodoPriorityResponseDtoCopyWithImpl<$Res, TodoPriorityResponseDto>;
  @useResult
  $Res call({int todoId, int priority, String updatedAt});
}

/// @nodoc
class _$TodoPriorityResponseDtoCopyWithImpl<
  $Res,
  $Val extends TodoPriorityResponseDto
>
    implements $TodoPriorityResponseDtoCopyWith<$Res> {
  _$TodoPriorityResponseDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TodoPriorityResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? todoId = null,
    Object? priority = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            todoId: null == todoId
                ? _value.todoId
                : todoId // ignore: cast_nullable_to_non_nullable
                      as int,
            priority: null == priority
                ? _value.priority
                : priority // ignore: cast_nullable_to_non_nullable
                      as int,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TodoPriorityResponseDtoImplCopyWith<$Res>
    implements $TodoPriorityResponseDtoCopyWith<$Res> {
  factory _$$TodoPriorityResponseDtoImplCopyWith(
    _$TodoPriorityResponseDtoImpl value,
    $Res Function(_$TodoPriorityResponseDtoImpl) then,
  ) = __$$TodoPriorityResponseDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int todoId, int priority, String updatedAt});
}

/// @nodoc
class __$$TodoPriorityResponseDtoImplCopyWithImpl<$Res>
    extends
        _$TodoPriorityResponseDtoCopyWithImpl<
          $Res,
          _$TodoPriorityResponseDtoImpl
        >
    implements _$$TodoPriorityResponseDtoImplCopyWith<$Res> {
  __$$TodoPriorityResponseDtoImplCopyWithImpl(
    _$TodoPriorityResponseDtoImpl _value,
    $Res Function(_$TodoPriorityResponseDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TodoPriorityResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? todoId = null,
    Object? priority = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$TodoPriorityResponseDtoImpl(
        todoId: null == todoId
            ? _value.todoId
            : todoId // ignore: cast_nullable_to_non_nullable
                  as int,
        priority: null == priority
            ? _value.priority
            : priority // ignore: cast_nullable_to_non_nullable
                  as int,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TodoPriorityResponseDtoImpl implements _TodoPriorityResponseDto {
  const _$TodoPriorityResponseDtoImpl({
    required this.todoId,
    required this.priority,
    required this.updatedAt,
  });

  factory _$TodoPriorityResponseDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$TodoPriorityResponseDtoImplFromJson(json);

  @override
  final int todoId;
  @override
  final int priority;
  @override
  final String updatedAt;

  @override
  String toString() {
    return 'TodoPriorityResponseDto(todoId: $todoId, priority: $priority, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TodoPriorityResponseDtoImpl &&
            (identical(other.todoId, todoId) || other.todoId == todoId) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, todoId, priority, updatedAt);

  /// Create a copy of TodoPriorityResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TodoPriorityResponseDtoImplCopyWith<_$TodoPriorityResponseDtoImpl>
  get copyWith =>
      __$$TodoPriorityResponseDtoImplCopyWithImpl<
        _$TodoPriorityResponseDtoImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TodoPriorityResponseDtoImplToJson(this);
  }
}

abstract class _TodoPriorityResponseDto implements TodoPriorityResponseDto {
  const factory _TodoPriorityResponseDto({
    required final int todoId,
    required final int priority,
    required final String updatedAt,
  }) = _$TodoPriorityResponseDtoImpl;

  factory _TodoPriorityResponseDto.fromJson(Map<String, dynamic> json) =
      _$TodoPriorityResponseDtoImpl.fromJson;

  @override
  int get todoId;
  @override
  int get priority;
  @override
  String get updatedAt;

  /// Create a copy of TodoPriorityResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TodoPriorityResponseDtoImplCopyWith<_$TodoPriorityResponseDtoImpl>
  get copyWith => throw _privateConstructorUsedError;
}
