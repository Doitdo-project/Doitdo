// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'todo_update_response_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TodoUpdateResponseDto _$TodoUpdateResponseDtoFromJson(
  Map<String, dynamic> json,
) {
  return _TodoUpdateResponseDto.fromJson(json);
}

/// @nodoc
mixin _$TodoUpdateResponseDto {
  int get todoId => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this TodoUpdateResponseDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TodoUpdateResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TodoUpdateResponseDtoCopyWith<TodoUpdateResponseDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TodoUpdateResponseDtoCopyWith<$Res> {
  factory $TodoUpdateResponseDtoCopyWith(
    TodoUpdateResponseDto value,
    $Res Function(TodoUpdateResponseDto) then,
  ) = _$TodoUpdateResponseDtoCopyWithImpl<$Res, TodoUpdateResponseDto>;
  @useResult
  $Res call({int todoId, String status, String updatedAt});
}

/// @nodoc
class _$TodoUpdateResponseDtoCopyWithImpl<
  $Res,
  $Val extends TodoUpdateResponseDto
>
    implements $TodoUpdateResponseDtoCopyWith<$Res> {
  _$TodoUpdateResponseDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TodoUpdateResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? todoId = null,
    Object? status = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            todoId: null == todoId
                ? _value.todoId
                : todoId // ignore: cast_nullable_to_non_nullable
                      as int,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
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
abstract class _$$TodoUpdateResponseDtoImplCopyWith<$Res>
    implements $TodoUpdateResponseDtoCopyWith<$Res> {
  factory _$$TodoUpdateResponseDtoImplCopyWith(
    _$TodoUpdateResponseDtoImpl value,
    $Res Function(_$TodoUpdateResponseDtoImpl) then,
  ) = __$$TodoUpdateResponseDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int todoId, String status, String updatedAt});
}

/// @nodoc
class __$$TodoUpdateResponseDtoImplCopyWithImpl<$Res>
    extends
        _$TodoUpdateResponseDtoCopyWithImpl<$Res, _$TodoUpdateResponseDtoImpl>
    implements _$$TodoUpdateResponseDtoImplCopyWith<$Res> {
  __$$TodoUpdateResponseDtoImplCopyWithImpl(
    _$TodoUpdateResponseDtoImpl _value,
    $Res Function(_$TodoUpdateResponseDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TodoUpdateResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? todoId = null,
    Object? status = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$TodoUpdateResponseDtoImpl(
        todoId: null == todoId
            ? _value.todoId
            : todoId // ignore: cast_nullable_to_non_nullable
                  as int,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
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
class _$TodoUpdateResponseDtoImpl implements _TodoUpdateResponseDto {
  const _$TodoUpdateResponseDtoImpl({
    required this.todoId,
    required this.status,
    required this.updatedAt,
  });

  factory _$TodoUpdateResponseDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$TodoUpdateResponseDtoImplFromJson(json);

  @override
  final int todoId;
  @override
  final String status;
  @override
  final String updatedAt;

  @override
  String toString() {
    return 'TodoUpdateResponseDto(todoId: $todoId, status: $status, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TodoUpdateResponseDtoImpl &&
            (identical(other.todoId, todoId) || other.todoId == todoId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, todoId, status, updatedAt);

  /// Create a copy of TodoUpdateResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TodoUpdateResponseDtoImplCopyWith<_$TodoUpdateResponseDtoImpl>
  get copyWith =>
      __$$TodoUpdateResponseDtoImplCopyWithImpl<_$TodoUpdateResponseDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TodoUpdateResponseDtoImplToJson(this);
  }
}

abstract class _TodoUpdateResponseDto implements TodoUpdateResponseDto {
  const factory _TodoUpdateResponseDto({
    required final int todoId,
    required final String status,
    required final String updatedAt,
  }) = _$TodoUpdateResponseDtoImpl;

  factory _TodoUpdateResponseDto.fromJson(Map<String, dynamic> json) =
      _$TodoUpdateResponseDtoImpl.fromJson;

  @override
  int get todoId;
  @override
  String get status;
  @override
  String get updatedAt;

  /// Create a copy of TodoUpdateResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TodoUpdateResponseDtoImplCopyWith<_$TodoUpdateResponseDtoImpl>
  get copyWith => throw _privateConstructorUsedError;
}
