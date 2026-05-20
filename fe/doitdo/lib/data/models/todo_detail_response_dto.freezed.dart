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
  String? get content => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get category => throw _privateConstructorUsedError;
  String? get colorHex => throw _privateConstructorUsedError;
  int? get categoryId => throw _privateConstructorUsedError; // ← 이 줄 추가
  String get type => throw _privateConstructorUsedError;
  int get priority => throw _privateConstructorUsedError;
  String? get startDate => throw _privateConstructorUsedError;
  String? get endDate => throw _privateConstructorUsedError;
  List<String>? get daysOfWeek =>
      throw _privateConstructorUsedError; // ✏️ period → daysOfWeek (서버 변경 반영)
  @JsonKey(name: 'alertTime')
  String? get alarmTime => throw _privateConstructorUsedError; // BE MR !281: scope=only 로 삭제된 RECURRING occurrence 날짜 배열.
  // RECURRING 마스터: ["2026-05-14", ...] (오름차순), 그 외 타입: 항상 [].
  List<String> get excludedDates =>
      throw _privateConstructorUsedError; // NORMAL 파생 인스턴스(scope=only 수정/완료): 원본 마스터 ID.
  // RECURRING 마스터 / 그 외 타입은 null.
  int? get masterTodoId =>
      throw _privateConstructorUsedError; // 같은 반복 흐름임을 식별하는 group id.
  // - RECURRING 마스터: 자기 todoId (group head)
  // - scope=from 으로 잘려나간 새 RECURRING 마스터: 원본 마스터의 group_id 상속
  // - scope=only 로 materialize 된 NORMAL 인스턴스: 마스터의 group_id 상속
  // - 일반 NORMAL/PERIOD/SOMEDAY: null
  // - 백필 안 된 레거시 RECURRING: null (자연 폴백)
  int? get recurrenceGroupId => throw _privateConstructorUsedError;
  int get earnedCoin => throw _privateConstructorUsedError;
  bool get rewarded => throw _privateConstructorUsedError;
  int get walletBalance => throw _privateConstructorUsedError;

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
    String? colorHex,
    int? categoryId,
    String type,
    int priority,
    String? startDate,
    String? endDate,
    List<String>? daysOfWeek,
    @JsonKey(name: 'alertTime') String? alarmTime,
    List<String> excludedDates,
    int? masterTodoId,
    int? recurrenceGroupId,
    int earnedCoin,
    bool rewarded,
    int walletBalance,
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
    Object? colorHex = freezed,
    Object? categoryId = freezed,
    Object? type = null,
    Object? priority = null,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? daysOfWeek = freezed,
    Object? alarmTime = freezed,
    Object? excludedDates = null,
    Object? masterTodoId = freezed,
    Object? recurrenceGroupId = freezed,
    Object? earnedCoin = null,
    Object? rewarded = null,
    Object? walletBalance = null,
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
            colorHex: freezed == colorHex
                ? _value.colorHex
                : colorHex // ignore: cast_nullable_to_non_nullable
                      as String?,
            categoryId: freezed == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
                      as int?,
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
            daysOfWeek: freezed == daysOfWeek
                ? _value.daysOfWeek
                : daysOfWeek // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            alarmTime: freezed == alarmTime
                ? _value.alarmTime
                : alarmTime // ignore: cast_nullable_to_non_nullable
                      as String?,
            excludedDates: null == excludedDates
                ? _value.excludedDates
                : excludedDates // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            masterTodoId: freezed == masterTodoId
                ? _value.masterTodoId
                : masterTodoId // ignore: cast_nullable_to_non_nullable
                      as int?,
            recurrenceGroupId: freezed == recurrenceGroupId
                ? _value.recurrenceGroupId
                : recurrenceGroupId // ignore: cast_nullable_to_non_nullable
                      as int?,
            earnedCoin: null == earnedCoin
                ? _value.earnedCoin
                : earnedCoin // ignore: cast_nullable_to_non_nullable
                      as int,
            rewarded: null == rewarded
                ? _value.rewarded
                : rewarded // ignore: cast_nullable_to_non_nullable
                      as bool,
            walletBalance: null == walletBalance
                ? _value.walletBalance
                : walletBalance // ignore: cast_nullable_to_non_nullable
                      as int,
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
    String? colorHex,
    int? categoryId,
    String type,
    int priority,
    String? startDate,
    String? endDate,
    List<String>? daysOfWeek,
    @JsonKey(name: 'alertTime') String? alarmTime,
    List<String> excludedDates,
    int? masterTodoId,
    int? recurrenceGroupId,
    int earnedCoin,
    bool rewarded,
    int walletBalance,
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
    Object? colorHex = freezed,
    Object? categoryId = freezed,
    Object? type = null,
    Object? priority = null,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? daysOfWeek = freezed,
    Object? alarmTime = freezed,
    Object? excludedDates = null,
    Object? masterTodoId = freezed,
    Object? recurrenceGroupId = freezed,
    Object? earnedCoin = null,
    Object? rewarded = null,
    Object? walletBalance = null,
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
        colorHex: freezed == colorHex
            ? _value.colorHex
            : colorHex // ignore: cast_nullable_to_non_nullable
                  as String?,
        categoryId: freezed == categoryId
            ? _value.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as int?,
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
        daysOfWeek: freezed == daysOfWeek
            ? _value._daysOfWeek
            : daysOfWeek // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        alarmTime: freezed == alarmTime
            ? _value.alarmTime
            : alarmTime // ignore: cast_nullable_to_non_nullable
                  as String?,
        excludedDates: null == excludedDates
            ? _value._excludedDates
            : excludedDates // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        masterTodoId: freezed == masterTodoId
            ? _value.masterTodoId
            : masterTodoId // ignore: cast_nullable_to_non_nullable
                  as int?,
        recurrenceGroupId: freezed == recurrenceGroupId
            ? _value.recurrenceGroupId
            : recurrenceGroupId // ignore: cast_nullable_to_non_nullable
                  as int?,
        earnedCoin: null == earnedCoin
            ? _value.earnedCoin
            : earnedCoin // ignore: cast_nullable_to_non_nullable
                  as int,
        rewarded: null == rewarded
            ? _value.rewarded
            : rewarded // ignore: cast_nullable_to_non_nullable
                  as bool,
        walletBalance: null == walletBalance
            ? _value.walletBalance
            : walletBalance // ignore: cast_nullable_to_non_nullable
                  as int,
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
    this.colorHex,
    this.categoryId,
    required this.type,
    required this.priority,
    this.startDate,
    this.endDate,
    final List<String>? daysOfWeek,
    @JsonKey(name: 'alertTime') this.alarmTime,
    final List<String> excludedDates = const <String>[],
    this.masterTodoId,
    this.recurrenceGroupId,
    this.earnedCoin = 0,
    this.rewarded = false,
    this.walletBalance = 0,
  }) : _daysOfWeek = daysOfWeek,
       _excludedDates = excludedDates;

  factory _$TodoDetailResponseDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$TodoDetailResponseDtoImplFromJson(json);

  @override
  final int todoId;
  @override
  final String title;
  @override
  final String? content;
  @override
  final String status;
  @override
  final String? category;
  @override
  final String? colorHex;
  @override
  final int? categoryId;
  // ← 이 줄 추가
  @override
  final String type;
  @override
  final int priority;
  @override
  final String? startDate;
  @override
  final String? endDate;
  final List<String>? _daysOfWeek;
  @override
  List<String>? get daysOfWeek {
    final value = _daysOfWeek;
    if (value == null) return null;
    if (_daysOfWeek is EqualUnmodifiableListView) return _daysOfWeek;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  // ✏️ period → daysOfWeek (서버 변경 반영)
  @override
  @JsonKey(name: 'alertTime')
  final String? alarmTime;
  // BE MR !281: scope=only 로 삭제된 RECURRING occurrence 날짜 배열.
  // RECURRING 마스터: ["2026-05-14", ...] (오름차순), 그 외 타입: 항상 [].
  final List<String> _excludedDates;
  // BE MR !281: scope=only 로 삭제된 RECURRING occurrence 날짜 배열.
  // RECURRING 마스터: ["2026-05-14", ...] (오름차순), 그 외 타입: 항상 [].
  @override
  @JsonKey()
  List<String> get excludedDates {
    if (_excludedDates is EqualUnmodifiableListView) return _excludedDates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_excludedDates);
  }

  // NORMAL 파생 인스턴스(scope=only 수정/완료): 원본 마스터 ID.
  // RECURRING 마스터 / 그 외 타입은 null.
  @override
  final int? masterTodoId;
  // 같은 반복 흐름임을 식별하는 group id.
  // - RECURRING 마스터: 자기 todoId (group head)
  // - scope=from 으로 잘려나간 새 RECURRING 마스터: 원본 마스터의 group_id 상속
  // - scope=only 로 materialize 된 NORMAL 인스턴스: 마스터의 group_id 상속
  // - 일반 NORMAL/PERIOD/SOMEDAY: null
  // - 백필 안 된 레거시 RECURRING: null (자연 폴백)
  @override
  final int? recurrenceGroupId;
  @override
  @JsonKey()
  final int earnedCoin;
  @override
  @JsonKey()
  final bool rewarded;
  @override
  @JsonKey()
  final int walletBalance;

  @override
  String toString() {
    return 'TodoDetailResponseDto(todoId: $todoId, title: $title, content: $content, status: $status, category: $category, colorHex: $colorHex, categoryId: $categoryId, type: $type, priority: $priority, startDate: $startDate, endDate: $endDate, daysOfWeek: $daysOfWeek, alarmTime: $alarmTime, excludedDates: $excludedDates, masterTodoId: $masterTodoId, recurrenceGroupId: $recurrenceGroupId, earnedCoin: $earnedCoin, rewarded: $rewarded, walletBalance: $walletBalance)';
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
            (identical(other.colorHex, colorHex) ||
                other.colorHex == colorHex) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            const DeepCollectionEquality().equals(
              other._daysOfWeek,
              _daysOfWeek,
            ) &&
            (identical(other.alarmTime, alarmTime) ||
                other.alarmTime == alarmTime) &&
            const DeepCollectionEquality().equals(
              other._excludedDates,
              _excludedDates,
            ) &&
            (identical(other.masterTodoId, masterTodoId) ||
                other.masterTodoId == masterTodoId) &&
            (identical(other.recurrenceGroupId, recurrenceGroupId) ||
                other.recurrenceGroupId == recurrenceGroupId) &&
            (identical(other.earnedCoin, earnedCoin) ||
                other.earnedCoin == earnedCoin) &&
            (identical(other.rewarded, rewarded) ||
                other.rewarded == rewarded) &&
            (identical(other.walletBalance, walletBalance) ||
                other.walletBalance == walletBalance));
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
    colorHex,
    categoryId,
    type,
    priority,
    startDate,
    endDate,
    const DeepCollectionEquality().hash(_daysOfWeek),
    alarmTime,
    const DeepCollectionEquality().hash(_excludedDates),
    masterTodoId,
    recurrenceGroupId,
    earnedCoin,
    rewarded,
    walletBalance,
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
    final String? colorHex,
    final int? categoryId,
    required final String type,
    required final int priority,
    final String? startDate,
    final String? endDate,
    final List<String>? daysOfWeek,
    @JsonKey(name: 'alertTime') final String? alarmTime,
    final List<String> excludedDates,
    final int? masterTodoId,
    final int? recurrenceGroupId,
    final int earnedCoin,
    final bool rewarded,
    final int walletBalance,
  }) = _$TodoDetailResponseDtoImpl;

  factory _TodoDetailResponseDto.fromJson(Map<String, dynamic> json) =
      _$TodoDetailResponseDtoImpl.fromJson;

  @override
  int get todoId;
  @override
  String get title;
  @override
  String? get content;
  @override
  String get status;
  @override
  String? get category;
  @override
  String? get colorHex;
  @override
  int? get categoryId; // ← 이 줄 추가
  @override
  String get type;
  @override
  int get priority;
  @override
  String? get startDate;
  @override
  String? get endDate;
  @override
  List<String>? get daysOfWeek; // ✏️ period → daysOfWeek (서버 변경 반영)
  @override
  @JsonKey(name: 'alertTime')
  String? get alarmTime; // BE MR !281: scope=only 로 삭제된 RECURRING occurrence 날짜 배열.
  // RECURRING 마스터: ["2026-05-14", ...] (오름차순), 그 외 타입: 항상 [].
  @override
  List<String> get excludedDates; // NORMAL 파생 인스턴스(scope=only 수정/완료): 원본 마스터 ID.
  // RECURRING 마스터 / 그 외 타입은 null.
  @override
  int? get masterTodoId; // 같은 반복 흐름임을 식별하는 group id.
  // - RECURRING 마스터: 자기 todoId (group head)
  // - scope=from 으로 잘려나간 새 RECURRING 마스터: 원본 마스터의 group_id 상속
  // - scope=only 로 materialize 된 NORMAL 인스턴스: 마스터의 group_id 상속
  // - 일반 NORMAL/PERIOD/SOMEDAY: null
  // - 백필 안 된 레거시 RECURRING: null (자연 폴백)
  @override
  int? get recurrenceGroupId;
  @override
  int get earnedCoin;
  @override
  bool get rewarded;
  @override
  int get walletBalance;

  /// Create a copy of TodoDetailResponseDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TodoDetailResponseDtoImplCopyWith<_$TodoDetailResponseDtoImpl>
  get copyWith => throw _privateConstructorUsedError;
}
