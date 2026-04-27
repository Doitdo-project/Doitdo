// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'todo_calendar_response_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TodoCalendarResponseDto _$TodoCalendarResponseDtoFromJson(
  Map<String, dynamic> json,
) {
  return _TodoCalendarResponseDto.fromJson(json);
}

/// @nodoc
mixin _$TodoCalendarResponseDto {
  // ✅ 서버 로그에 맞춰 selectedDateItems 대신 items로 변경
  List<CalendarTodoItemDto> get items => throw _privateConstructorUsedError;

  /// Serializes this TodoCalendarResponseDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TodoCalendarResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TodoCalendarResponseDtoCopyWith<TodoCalendarResponseDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TodoCalendarResponseDtoCopyWith<$Res> {
  factory $TodoCalendarResponseDtoCopyWith(
    TodoCalendarResponseDto value,
    $Res Function(TodoCalendarResponseDto) then,
  ) = _$TodoCalendarResponseDtoCopyWithImpl<$Res, TodoCalendarResponseDto>;
  @useResult
  $Res call({List<CalendarTodoItemDto> items});
}

/// @nodoc
class _$TodoCalendarResponseDtoCopyWithImpl<
  $Res,
  $Val extends TodoCalendarResponseDto
>
    implements $TodoCalendarResponseDtoCopyWith<$Res> {
  _$TodoCalendarResponseDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TodoCalendarResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? items = null}) {
    return _then(
      _value.copyWith(
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<CalendarTodoItemDto>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TodoCalendarResponseDtoImplCopyWith<$Res>
    implements $TodoCalendarResponseDtoCopyWith<$Res> {
  factory _$$TodoCalendarResponseDtoImplCopyWith(
    _$TodoCalendarResponseDtoImpl value,
    $Res Function(_$TodoCalendarResponseDtoImpl) then,
  ) = __$$TodoCalendarResponseDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<CalendarTodoItemDto> items});
}

/// @nodoc
class __$$TodoCalendarResponseDtoImplCopyWithImpl<$Res>
    extends
        _$TodoCalendarResponseDtoCopyWithImpl<
          $Res,
          _$TodoCalendarResponseDtoImpl
        >
    implements _$$TodoCalendarResponseDtoImplCopyWith<$Res> {
  __$$TodoCalendarResponseDtoImplCopyWithImpl(
    _$TodoCalendarResponseDtoImpl _value,
    $Res Function(_$TodoCalendarResponseDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TodoCalendarResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? items = null}) {
    return _then(
      _$TodoCalendarResponseDtoImpl(
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<CalendarTodoItemDto>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TodoCalendarResponseDtoImpl implements _TodoCalendarResponseDto {
  const _$TodoCalendarResponseDtoImpl({
    required final List<CalendarTodoItemDto> items,
  }) : _items = items;

  factory _$TodoCalendarResponseDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$TodoCalendarResponseDtoImplFromJson(json);

  // ✅ 서버 로그에 맞춰 selectedDateItems 대신 items로 변경
  final List<CalendarTodoItemDto> _items;
  // ✅ 서버 로그에 맞춰 selectedDateItems 대신 items로 변경
  @override
  List<CalendarTodoItemDto> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'TodoCalendarResponseDto(items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TodoCalendarResponseDtoImpl &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_items));

  /// Create a copy of TodoCalendarResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TodoCalendarResponseDtoImplCopyWith<_$TodoCalendarResponseDtoImpl>
  get copyWith =>
      __$$TodoCalendarResponseDtoImplCopyWithImpl<
        _$TodoCalendarResponseDtoImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TodoCalendarResponseDtoImplToJson(this);
  }
}

abstract class _TodoCalendarResponseDto implements TodoCalendarResponseDto {
  const factory _TodoCalendarResponseDto({
    required final List<CalendarTodoItemDto> items,
  }) = _$TodoCalendarResponseDtoImpl;

  factory _TodoCalendarResponseDto.fromJson(Map<String, dynamic> json) =
      _$TodoCalendarResponseDtoImpl.fromJson;

  // ✅ 서버 로그에 맞춰 selectedDateItems 대신 items로 변경
  @override
  List<CalendarTodoItemDto> get items;

  /// Create a copy of TodoCalendarResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TodoCalendarResponseDtoImplCopyWith<_$TodoCalendarResponseDtoImpl>
  get copyWith => throw _privateConstructorUsedError;
}

CalendarSummaryDto _$CalendarSummaryDtoFromJson(Map<String, dynamic> json) {
  return _CalendarSummaryDto.fromJson(json);
}

/// @nodoc
mixin _$CalendarSummaryDto {
  String get date => throw _privateConstructorUsedError;
  int get completedCount => throw _privateConstructorUsedError;
  int get totalCount => throw _privateConstructorUsedError;

  /// Serializes this CalendarSummaryDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CalendarSummaryDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CalendarSummaryDtoCopyWith<CalendarSummaryDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CalendarSummaryDtoCopyWith<$Res> {
  factory $CalendarSummaryDtoCopyWith(
    CalendarSummaryDto value,
    $Res Function(CalendarSummaryDto) then,
  ) = _$CalendarSummaryDtoCopyWithImpl<$Res, CalendarSummaryDto>;
  @useResult
  $Res call({String date, int completedCount, int totalCount});
}

/// @nodoc
class _$CalendarSummaryDtoCopyWithImpl<$Res, $Val extends CalendarSummaryDto>
    implements $CalendarSummaryDtoCopyWith<$Res> {
  _$CalendarSummaryDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CalendarSummaryDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? completedCount = null,
    Object? totalCount = null,
  }) {
    return _then(
      _value.copyWith(
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as String,
            completedCount: null == completedCount
                ? _value.completedCount
                : completedCount // ignore: cast_nullable_to_non_nullable
                      as int,
            totalCount: null == totalCount
                ? _value.totalCount
                : totalCount // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CalendarSummaryDtoImplCopyWith<$Res>
    implements $CalendarSummaryDtoCopyWith<$Res> {
  factory _$$CalendarSummaryDtoImplCopyWith(
    _$CalendarSummaryDtoImpl value,
    $Res Function(_$CalendarSummaryDtoImpl) then,
  ) = __$$CalendarSummaryDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String date, int completedCount, int totalCount});
}

/// @nodoc
class __$$CalendarSummaryDtoImplCopyWithImpl<$Res>
    extends _$CalendarSummaryDtoCopyWithImpl<$Res, _$CalendarSummaryDtoImpl>
    implements _$$CalendarSummaryDtoImplCopyWith<$Res> {
  __$$CalendarSummaryDtoImplCopyWithImpl(
    _$CalendarSummaryDtoImpl _value,
    $Res Function(_$CalendarSummaryDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CalendarSummaryDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? completedCount = null,
    Object? totalCount = null,
  }) {
    return _then(
      _$CalendarSummaryDtoImpl(
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as String,
        completedCount: null == completedCount
            ? _value.completedCount
            : completedCount // ignore: cast_nullable_to_non_nullable
                  as int,
        totalCount: null == totalCount
            ? _value.totalCount
            : totalCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CalendarSummaryDtoImpl implements _CalendarSummaryDto {
  const _$CalendarSummaryDtoImpl({
    required this.date,
    required this.completedCount,
    required this.totalCount,
  });

  factory _$CalendarSummaryDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CalendarSummaryDtoImplFromJson(json);

  @override
  final String date;
  @override
  final int completedCount;
  @override
  final int totalCount;

  @override
  String toString() {
    return 'CalendarSummaryDto(date: $date, completedCount: $completedCount, totalCount: $totalCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CalendarSummaryDtoImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.completedCount, completedCount) ||
                other.completedCount == completedCount) &&
            (identical(other.totalCount, totalCount) ||
                other.totalCount == totalCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, date, completedCount, totalCount);

  /// Create a copy of CalendarSummaryDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CalendarSummaryDtoImplCopyWith<_$CalendarSummaryDtoImpl> get copyWith =>
      __$$CalendarSummaryDtoImplCopyWithImpl<_$CalendarSummaryDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CalendarSummaryDtoImplToJson(this);
  }
}

abstract class _CalendarSummaryDto implements CalendarSummaryDto {
  const factory _CalendarSummaryDto({
    required final String date,
    required final int completedCount,
    required final int totalCount,
  }) = _$CalendarSummaryDtoImpl;

  factory _CalendarSummaryDto.fromJson(Map<String, dynamic> json) =
      _$CalendarSummaryDtoImpl.fromJson;

  @override
  String get date;
  @override
  int get completedCount;
  @override
  int get totalCount;

  /// Create a copy of CalendarSummaryDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CalendarSummaryDtoImplCopyWith<_$CalendarSummaryDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CalendarTodoItemDto _$CalendarTodoItemDtoFromJson(Map<String, dynamic> json) {
  return _CalendarTodoItemDto.fromJson(json);
}

/// @nodoc
mixin _$CalendarTodoItemDto {
  int? get todoId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get status =>
      throw _privateConstructorUsedError; // TODO, IN_PROGRESS, DONE
  bool? get isVirtual => throw _privateConstructorUsedError;
  int? get masterTodoId => throw _privateConstructorUsedError;
  String? get occurrenceDate => throw _privateConstructorUsedError;

  /// Serializes this CalendarTodoItemDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CalendarTodoItemDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CalendarTodoItemDtoCopyWith<CalendarTodoItemDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CalendarTodoItemDtoCopyWith<$Res> {
  factory $CalendarTodoItemDtoCopyWith(
    CalendarTodoItemDto value,
    $Res Function(CalendarTodoItemDto) then,
  ) = _$CalendarTodoItemDtoCopyWithImpl<$Res, CalendarTodoItemDto>;
  @useResult
  $Res call({
    int? todoId,
    String title,
    String status,
    bool? isVirtual,
    int? masterTodoId,
    String? occurrenceDate,
  });
}

/// @nodoc
class _$CalendarTodoItemDtoCopyWithImpl<$Res, $Val extends CalendarTodoItemDto>
    implements $CalendarTodoItemDtoCopyWith<$Res> {
  _$CalendarTodoItemDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CalendarTodoItemDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? todoId = freezed,
    Object? title = null,
    Object? status = null,
    Object? isVirtual = freezed,
    Object? masterTodoId = freezed,
    Object? occurrenceDate = freezed,
  }) {
    return _then(
      _value.copyWith(
            todoId: freezed == todoId
                ? _value.todoId
                : todoId // ignore: cast_nullable_to_non_nullable
                      as int?,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            isVirtual: freezed == isVirtual
                ? _value.isVirtual
                : isVirtual // ignore: cast_nullable_to_non_nullable
                      as bool?,
            masterTodoId: freezed == masterTodoId
                ? _value.masterTodoId
                : masterTodoId // ignore: cast_nullable_to_non_nullable
                      as int?,
            occurrenceDate: freezed == occurrenceDate
                ? _value.occurrenceDate
                : occurrenceDate // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CalendarTodoItemDtoImplCopyWith<$Res>
    implements $CalendarTodoItemDtoCopyWith<$Res> {
  factory _$$CalendarTodoItemDtoImplCopyWith(
    _$CalendarTodoItemDtoImpl value,
    $Res Function(_$CalendarTodoItemDtoImpl) then,
  ) = __$$CalendarTodoItemDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int? todoId,
    String title,
    String status,
    bool? isVirtual,
    int? masterTodoId,
    String? occurrenceDate,
  });
}

/// @nodoc
class __$$CalendarTodoItemDtoImplCopyWithImpl<$Res>
    extends _$CalendarTodoItemDtoCopyWithImpl<$Res, _$CalendarTodoItemDtoImpl>
    implements _$$CalendarTodoItemDtoImplCopyWith<$Res> {
  __$$CalendarTodoItemDtoImplCopyWithImpl(
    _$CalendarTodoItemDtoImpl _value,
    $Res Function(_$CalendarTodoItemDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CalendarTodoItemDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? todoId = freezed,
    Object? title = null,
    Object? status = null,
    Object? isVirtual = freezed,
    Object? masterTodoId = freezed,
    Object? occurrenceDate = freezed,
  }) {
    return _then(
      _$CalendarTodoItemDtoImpl(
        todoId: freezed == todoId
            ? _value.todoId
            : todoId // ignore: cast_nullable_to_non_nullable
                  as int?,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        isVirtual: freezed == isVirtual
            ? _value.isVirtual
            : isVirtual // ignore: cast_nullable_to_non_nullable
                  as bool?,
        masterTodoId: freezed == masterTodoId
            ? _value.masterTodoId
            : masterTodoId // ignore: cast_nullable_to_non_nullable
                  as int?,
        occurrenceDate: freezed == occurrenceDate
            ? _value.occurrenceDate
            : occurrenceDate // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CalendarTodoItemDtoImpl implements _CalendarTodoItemDto {
  const _$CalendarTodoItemDtoImpl({
    this.todoId,
    required this.title,
    required this.status,
    this.isVirtual,
    this.masterTodoId,
    this.occurrenceDate,
  });

  factory _$CalendarTodoItemDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CalendarTodoItemDtoImplFromJson(json);

  @override
  final int? todoId;
  @override
  final String title;
  @override
  final String status;
  // TODO, IN_PROGRESS, DONE
  @override
  final bool? isVirtual;
  @override
  final int? masterTodoId;
  @override
  final String? occurrenceDate;

  @override
  String toString() {
    return 'CalendarTodoItemDto(todoId: $todoId, title: $title, status: $status, isVirtual: $isVirtual, masterTodoId: $masterTodoId, occurrenceDate: $occurrenceDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CalendarTodoItemDtoImpl &&
            (identical(other.todoId, todoId) || other.todoId == todoId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.isVirtual, isVirtual) ||
                other.isVirtual == isVirtual) &&
            (identical(other.masterTodoId, masterTodoId) ||
                other.masterTodoId == masterTodoId) &&
            (identical(other.occurrenceDate, occurrenceDate) ||
                other.occurrenceDate == occurrenceDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    todoId,
    title,
    status,
    isVirtual,
    masterTodoId,
    occurrenceDate,
  );

  /// Create a copy of CalendarTodoItemDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CalendarTodoItemDtoImplCopyWith<_$CalendarTodoItemDtoImpl> get copyWith =>
      __$$CalendarTodoItemDtoImplCopyWithImpl<_$CalendarTodoItemDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CalendarTodoItemDtoImplToJson(this);
  }
}

abstract class _CalendarTodoItemDto implements CalendarTodoItemDto {
  const factory _CalendarTodoItemDto({
    final int? todoId,
    required final String title,
    required final String status,
    final bool? isVirtual,
    final int? masterTodoId,
    final String? occurrenceDate,
  }) = _$CalendarTodoItemDtoImpl;

  factory _CalendarTodoItemDto.fromJson(Map<String, dynamic> json) =
      _$CalendarTodoItemDtoImpl.fromJson;

  @override
  int? get todoId;
  @override
  String get title;
  @override
  String get status; // TODO, IN_PROGRESS, DONE
  @override
  bool? get isVirtual;
  @override
  int? get masterTodoId;
  @override
  String? get occurrenceDate;

  /// Create a copy of CalendarTodoItemDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CalendarTodoItemDtoImplCopyWith<_$CalendarTodoItemDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
