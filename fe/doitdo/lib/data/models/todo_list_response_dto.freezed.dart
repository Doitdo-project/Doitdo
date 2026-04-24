// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'todo_list_response_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TodoListResponseDto _$TodoListResponseDtoFromJson(Map<String, dynamic> json) {
  return _TodoListResponseDto.fromJson(json);
}

/// @nodoc
mixin _$TodoListResponseDto {
  List<TodoListItemDto> get items => throw _privateConstructorUsedError;

  /// Serializes this TodoListResponseDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TodoListResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TodoListResponseDtoCopyWith<TodoListResponseDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TodoListResponseDtoCopyWith<$Res> {
  factory $TodoListResponseDtoCopyWith(
    TodoListResponseDto value,
    $Res Function(TodoListResponseDto) then,
  ) = _$TodoListResponseDtoCopyWithImpl<$Res, TodoListResponseDto>;
  @useResult
  $Res call({List<TodoListItemDto> items});
}

/// @nodoc
class _$TodoListResponseDtoCopyWithImpl<$Res, $Val extends TodoListResponseDto>
    implements $TodoListResponseDtoCopyWith<$Res> {
  _$TodoListResponseDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TodoListResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? items = null}) {
    return _then(
      _value.copyWith(
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<TodoListItemDto>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TodoListResponseDtoImplCopyWith<$Res>
    implements $TodoListResponseDtoCopyWith<$Res> {
  factory _$$TodoListResponseDtoImplCopyWith(
    _$TodoListResponseDtoImpl value,
    $Res Function(_$TodoListResponseDtoImpl) then,
  ) = __$$TodoListResponseDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<TodoListItemDto> items});
}

/// @nodoc
class __$$TodoListResponseDtoImplCopyWithImpl<$Res>
    extends _$TodoListResponseDtoCopyWithImpl<$Res, _$TodoListResponseDtoImpl>
    implements _$$TodoListResponseDtoImplCopyWith<$Res> {
  __$$TodoListResponseDtoImplCopyWithImpl(
    _$TodoListResponseDtoImpl _value,
    $Res Function(_$TodoListResponseDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TodoListResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? items = null}) {
    return _then(
      _$TodoListResponseDtoImpl(
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<TodoListItemDto>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TodoListResponseDtoImpl implements _TodoListResponseDto {
  const _$TodoListResponseDtoImpl({required final List<TodoListItemDto> items})
    : _items = items;

  factory _$TodoListResponseDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$TodoListResponseDtoImplFromJson(json);

  final List<TodoListItemDto> _items;
  @override
  List<TodoListItemDto> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'TodoListResponseDto(items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TodoListResponseDtoImpl &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_items));

  /// Create a copy of TodoListResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TodoListResponseDtoImplCopyWith<_$TodoListResponseDtoImpl> get copyWith =>
      __$$TodoListResponseDtoImplCopyWithImpl<_$TodoListResponseDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TodoListResponseDtoImplToJson(this);
  }
}

abstract class _TodoListResponseDto implements TodoListResponseDto {
  const factory _TodoListResponseDto({
    required final List<TodoListItemDto> items,
  }) = _$TodoListResponseDtoImpl;

  factory _TodoListResponseDto.fromJson(Map<String, dynamic> json) =
      _$TodoListResponseDtoImpl.fromJson;

  @override
  List<TodoListItemDto> get items;

  /// Create a copy of TodoListResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TodoListResponseDtoImplCopyWith<_$TodoListResponseDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TodoListItemDto _$TodoListItemDtoFromJson(Map<String, dynamic> json) {
  return _TodoListItemDto.fromJson(json);
}

/// @nodoc
mixin _$TodoListItemDto {
  int get todoId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  int? get priority => throw _privateConstructorUsedError;
  String? get category => throw _privateConstructorUsedError;
  String? get type => throw _privateConstructorUsedError;
  String? get startDate => throw _privateConstructorUsedError;
  String? get endDate => throw _privateConstructorUsedError;

  /// Serializes this TodoListItemDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TodoListItemDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TodoListItemDtoCopyWith<TodoListItemDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TodoListItemDtoCopyWith<$Res> {
  factory $TodoListItemDtoCopyWith(
    TodoListItemDto value,
    $Res Function(TodoListItemDto) then,
  ) = _$TodoListItemDtoCopyWithImpl<$Res, TodoListItemDto>;
  @useResult
  $Res call({
    int todoId,
    String title,
    String status,
    int? priority,
    String? category,
    String? type,
    String? startDate,
    String? endDate,
  });
}

/// @nodoc
class _$TodoListItemDtoCopyWithImpl<$Res, $Val extends TodoListItemDto>
    implements $TodoListItemDtoCopyWith<$Res> {
  _$TodoListItemDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TodoListItemDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? todoId = null,
    Object? title = null,
    Object? status = null,
    Object? priority = freezed,
    Object? category = freezed,
    Object? type = freezed,
    Object? startDate = freezed,
    Object? endDate = freezed,
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
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            priority: freezed == priority
                ? _value.priority
                : priority // ignore: cast_nullable_to_non_nullable
                      as int?,
            category: freezed == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String?,
            type: freezed == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String?,
            startDate: freezed == startDate
                ? _value.startDate
                : startDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            endDate: freezed == endDate
                ? _value.endDate
                : endDate // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TodoListItemDtoImplCopyWith<$Res>
    implements $TodoListItemDtoCopyWith<$Res> {
  factory _$$TodoListItemDtoImplCopyWith(
    _$TodoListItemDtoImpl value,
    $Res Function(_$TodoListItemDtoImpl) then,
  ) = __$$TodoListItemDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int todoId,
    String title,
    String status,
    int? priority,
    String? category,
    String? type,
    String? startDate,
    String? endDate,
  });
}

/// @nodoc
class __$$TodoListItemDtoImplCopyWithImpl<$Res>
    extends _$TodoListItemDtoCopyWithImpl<$Res, _$TodoListItemDtoImpl>
    implements _$$TodoListItemDtoImplCopyWith<$Res> {
  __$$TodoListItemDtoImplCopyWithImpl(
    _$TodoListItemDtoImpl _value,
    $Res Function(_$TodoListItemDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TodoListItemDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? todoId = null,
    Object? title = null,
    Object? status = null,
    Object? priority = freezed,
    Object? category = freezed,
    Object? type = freezed,
    Object? startDate = freezed,
    Object? endDate = freezed,
  }) {
    return _then(
      _$TodoListItemDtoImpl(
        todoId: null == todoId
            ? _value.todoId
            : todoId // ignore: cast_nullable_to_non_nullable
                  as int,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        priority: freezed == priority
            ? _value.priority
            : priority // ignore: cast_nullable_to_non_nullable
                  as int?,
        category: freezed == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String?,
        type: freezed == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String?,
        startDate: freezed == startDate
            ? _value.startDate
            : startDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        endDate: freezed == endDate
            ? _value.endDate
            : endDate // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TodoListItemDtoImpl implements _TodoListItemDto {
  const _$TodoListItemDtoImpl({
    required this.todoId,
    required this.title,
    required this.status,
    this.priority,
    this.category,
    this.type,
    this.startDate,
    this.endDate,
  });

  factory _$TodoListItemDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$TodoListItemDtoImplFromJson(json);

  @override
  final int todoId;
  @override
  final String title;
  @override
  final String status;
  @override
  final int? priority;
  @override
  final String? category;
  @override
  final String? type;
  @override
  final String? startDate;
  @override
  final String? endDate;

  @override
  String toString() {
    return 'TodoListItemDto(todoId: $todoId, title: $title, status: $status, priority: $priority, category: $category, type: $type, startDate: $startDate, endDate: $endDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TodoListItemDtoImpl &&
            (identical(other.todoId, todoId) || other.todoId == todoId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    todoId,
    title,
    status,
    priority,
    category,
    type,
    startDate,
    endDate,
  );

  /// Create a copy of TodoListItemDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TodoListItemDtoImplCopyWith<_$TodoListItemDtoImpl> get copyWith =>
      __$$TodoListItemDtoImplCopyWithImpl<_$TodoListItemDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TodoListItemDtoImplToJson(this);
  }
}

abstract class _TodoListItemDto implements TodoListItemDto {
  const factory _TodoListItemDto({
    required final int todoId,
    required final String title,
    required final String status,
    final int? priority,
    final String? category,
    final String? type,
    final String? startDate,
    final String? endDate,
  }) = _$TodoListItemDtoImpl;

  factory _TodoListItemDto.fromJson(Map<String, dynamic> json) =
      _$TodoListItemDtoImpl.fromJson;

  @override
  int get todoId;
  @override
  String get title;
  @override
  String get status;
  @override
  int? get priority;
  @override
  String? get category;
  @override
  String? get type;
  @override
  String? get startDate;
  @override
  String? get endDate;

  /// Create a copy of TodoListItemDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TodoListItemDtoImplCopyWith<_$TodoListItemDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
