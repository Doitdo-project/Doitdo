import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:doitdo/core/widget_sync/widget_sync_service.dart';
import 'package:doitdo/core/widget_sync/widget_todo_dto.dart';
import 'package:doitdo/presentation/models/todo.dart';
import 'package:doitdo/presentation/pages/todo/todo_state.dart';
import 'package:doitdo/domain/repositories/todo_repository.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';
import 'package:doitdo/data/models/todo_update_request_dto.dart';
import 'package:doitdo/data/models/todo_detail_response_dto.dart';

class TodoViewModel extends StateNotifier<TodoState> {
  // ✅ 전역 reorder 락: todo_page/tamagochi_page 두 인스턴스 중복 방지
  bool _isReordering = false;

  bool tryStartReorder() {
    if (_isReordering) return false;
    _isReordering = true;
    return true;
  }

  void finishReorder() {
    _isReordering = false;
  }

  TodoViewModel(this._repository, this._widgetSync)
      : super(TodoState(
    selectedDay: DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day),
    focusedDay: DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day),
  )) {
    // 모든 state 변경에 위젯 동기화 — addListener 가 매 set 때마다 발화하므로
    // 각 mutation 메서드에서 별도 호출 불필요. fireImmediately false 로 초기 빈
    // 상태는 sync 하지 않고, fetchTodos 가 채워준 직후부터 위젯이 갱신됨.
    addListener(_syncWidget, fireImmediately: false);
    fetchTodos();
  }

  final TodoRepository _repository;
  final WidgetSyncService _widgetSync;

  static CategoryColorKey _colorKey(String? category) {
    switch (category) {
      case '운동': return CategoryColorKey.exercise;
      case '업무': return CategoryColorKey.work;
      case '건강': return CategoryColorKey.health;
      case '취미': return CategoryColorKey.hobby;
      case '공부': return CategoryColorKey.study;
      default:     return CategoryColorKey.etc;
    }
  }

  // ✅ [치명적 버그 수정] 서버의 String 타입을 앱의 Enum으로 변환해주는 헬퍼 추가
  TodoDateType _mapTypeFromServer(String? type) {
    if (type == 'PERIOD') return TodoDateType.range;
    if (type == 'RECURRING') return TodoDateType.repeat;
    if (type == 'SOMEDAY') return TodoDateType.someday;
    return TodoDateType.normal;
  }

  void _updateDisplayedTodos() {
    final filter = state.currentFilter;
    final selectedDay = state.selectedDay;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<Todo> filteredTodos = state.allTodos;
    List<Todo> filteredSomeday = state.allSomedayTodos;

    // 카테고리별 필터 (cat:{name})
    if (filter.startsWith('cat:')) {
      final catName = filter.substring(4);
      filteredTodos = filteredTodos
          .where((t) => t.category.name == catName)
          .toList();
      filteredSomeday = state.allSomedayTodos
          .where((t) => t.category.name == catName)
          .toList();
      state = state.copyWith(todos: filteredTodos, somedayTodos: filteredSomeday);
      return;
    }

    // 유형별 필터 (type:NORMAL / type:RECURRING / type:PERIOD)
    if (filter.startsWith('type:')) {
      final typeStr = filter.substring(5);
      final dateType = switch (typeStr) {
        'RECURRING' => TodoDateType.repeat,
        'PERIOD'    => TodoDateType.range,
        _           => TodoDateType.normal,
      };
      filteredTodos = filteredTodos
          .where((t) => t.dateType == dateType)
          .toList();
      filteredSomeday = [];
      state = state.copyWith(todos: filteredTodos, somedayTodos: filteredSomeday);
      return;
    }

    switch (filter) {
      default:
        if (selectedDay != null) {
          final sel = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);

          filteredTodos = filteredTodos.where((t) {
            // ✏️ 수정: PERIOD 타입은 date 대신 rangeStart 또는 date 우선 사용
            final effectiveDate = (t.dateType == TodoDateType.range)
                ? (t.date ?? t.rangeStart)
                : t.date;

            if (effectiveDate == null) return false;

            final start = DateTime(effectiveDate.year, effectiveDate.month, effectiveDate.day);

            // 시작 날짜 이전은 표시 안 함
            if (sel.isBefore(start)) return false;

            // 종료 날짜 계산 (PERIOD → rangeEnd, RECURRING → repeatEndDate)
            DateTime? endDay;
            if (t.rangeEnd != null) {
              endDay = DateTime(t.rangeEnd!.year, t.rangeEnd!.month, t.rangeEnd!.day);
            } else if (t.repeatEndDate != null) {
              endDay = DateTime(t.repeatEndDate!.year, t.repeatEndDate!.month, t.repeatEndDate!.day);
            }
            if (endDay != null && sel.isAfter(endDay)) return false;

            if (t.dateType == TodoDateType.repeat) {
              // ✅ RECURRING: 선택 날짜가 반복 요일에 해당하는지 체크
              final flutterWd = sel.weekday; // 1=월~7=일
              final appIndex  = flutterWd == 7 ? 0 : flutterWd; // 일요일(7)→0

              if (t.repeatDays != null && t.repeatDays!.isNotEmpty) {
                // 로컬에 repeatDays 있으면 요일 배열로 체크
                return t.repeatDays!.contains(appIndex);
              } else {
                // 서버 재조회 후 repeatDays 없을 때: 시작 요일과 일치하는지 폴백
                return sel.weekday == start.weekday;
              }
            } else if (t.dateType == TodoDateType.range) {
              // ✅ PERIOD: 범위 내에 있으면 표시
              return !sel.isBefore(start) &&
                  (endDay == null || !sel.isAfter(endDay));
            } else if (t.dateType == TodoDateType.someday) {
              return false;
            } else {
              // NORMAL: 날짜 일치
              return isSameDay(t.date!, selectedDay);
            }
          }).toList();
        } else {
          filteredTodos = [];
        }
    }

    // ✏️ 수정: todo/done 은 날짜 선택과 무관하게 전체 기간 기준
    if (filter == 'todo') {
      filteredTodos   = state.allTodos.where((t) => !t.isDone).toList();
      filteredSomeday = state.allSomedayTodos.where((t) => !t.isDone).toList();
    } else if (filter == 'done') {
      filteredTodos   = state.allTodos.where((t) => t.isDone).toList();
      filteredSomeday = state.allSomedayTodos.where((t) => t.isDone).toList();
    }

    state = state.copyWith(
      todos: filteredTodos,
      somedayTodos: filteredSomeday,
    );
  }

  Future<void> fetchTodos() async {
    final result = await AsyncValue.guard(
          () => _repository.getTodos(view: 'all'),
    );

    // 비로그인 상태 부트스트랩 → 401 → /welcome 으로 리다이렉트되는 race:
    // consumer 가 unmount 되면 autoDispose 는 다음 microtask 에 스케줄되는데,
    // 우리 await 가 그보다 먼저 깨면 mounted 가 아직 true 라 defunct consumer 의
    // markNeedsBuild 를 호출 → framework.dart 5340 어설션 → cascade 로 GlobalKey
    // duplicate 등이 터지고 release 빌드에서 회색 화면이 됨.
    // 빈 microtask 한 번 yield 해서 autoDispose 가 먼저 돌게 하고, 그 다음 mounted
    // 체크가 정확한 상태를 반영하도록.
    // Riverpod autoDispose 는 vsync 기반 (frame 단위) — microtask yield 만으론
    // 늦게 돈다. endOfFrame 까지 기다려서 dispose 가 먼저 처리되게.
    await SchedulerBinding.instance.endOfFrame;
    if (!mounted) return;

    if (result.hasValue) {
      final items = result.value!.items;

      final sortedItems = List.of(items)
        ..sort((a, b) => (a.priority ?? 999).compareTo(b.priority ?? 999));

      final allFetched = sortedItems.map((dto) => Todo(
        id: dto.todoId.toString(),
        title: dto.title,
        isDone: dto.status == 'DONE',
        memo: dto.content,
        category: TodoCategory(
          name: dto.category ?? '기타',
          colorKey: _colorKey(dto.category),
        ),
        date: dto.startDate != null ? DateTime.tryParse(dto.startDate!) : null,
        // ✏️ 수정: PERIOD → rangeEnd, RECURRING → repeatEndDate 로 각각 분리
        rangeEnd: dto.type == 'PERIOD' && dto.endDate != null
            ? DateTime.tryParse(dto.endDate!)
            : null,
        repeatEndDate: dto.type == 'RECURRING' && dto.endDate != null
            ? DateTime.tryParse(dto.endDate!)
            : null,
        alarmTime: _parseTime(dto.alarmTime),
        alarmEnabled: dto.alarmTime != null,
        dateType: _mapTypeFromServer(dto.type),
        // ✏️ 수정: period 대신 daysOfWeek 파싱 (서버 응답: ["MON","WED","FRI"])
        repeatDays: dto.daysOfWeek != null && dto.daysOfWeek!.isNotEmpty
            ? _parseDaysOfWeek(dto.daysOfWeek!)
            : null,
      )).toList();

      // ✏️ 수정: PERIOD 타입은 rangeStart(또는 date)를 기준으로 분류
      //   date가 null이어도 rangeEnd가 있으면 날짜 있는 할 일
      state = state.copyWith(
        allTodos: allFetched
            .where((t) => t.dateType != TodoDateType.someday)
            .toList(),
        allSomedayTodos: allFetched
            .where((t) => t.dateType == TodoDateType.someday)
            .toList(),
      );

      _updateCalendarEvents(state.allTodos);
      _updateDisplayedTodos();
    }
  }

  void _updateCalendarEvents(List<Todo> allTodos) {
    final Map<DateTime, List<Todo>> newEvents = {};

    for (var todo in allTodos) {
      // ✏️ 수정: PERIOD 타입은 date(startDate)가 null이어도 rangeEnd가 있으면 처리
      //   date 대신 rangeStart 또는 date 중 유효한 것을 사용
      DateTime? effectiveStart;
      if (todo.dateType == TodoDateType.range) {
        effectiveStart = todo.date ?? todo.rangeStart;
      } else {
        effectiveStart = todo.date;
      }

      if (effectiveStart == null) continue;

      final start = DateTime(effectiveStart.year, effectiveStart.month, effectiveStart.day);

      // ✏️ 수정: PERIOD → rangeEnd, RECURRING → repeatEndDate 각각 사용
      final effectiveEnd = todo.dateType == TodoDateType.range
          ? todo.rangeEnd
          : todo.dateType == TodoDateType.repeat
          ? todo.repeatEndDate
          : null;

      // ✅ 반복 종료일 없으면 현재 focusedDay 기준 앞뒤 2달 범위 끝까지 표시
      // (90일 하드코딩 제거 — 달을 넘겨도 DOT 계속 표시)
      final calendarEnd = DateTime(
        state.focusedDay.year,
        state.focusedDay.month + 3,
        0,
      );

      final end = effectiveEnd != null
          ? DateTime(effectiveEnd.year, effectiveEnd.month, effectiveEnd.day)
          : (todo.dateType == TodoDateType.repeat
          ? calendarEnd  // ✅ 종료일 없는 반복 → 캘린더 표시 범위까지
          : start);

      final totalDays = end.difference(start).inDays;

      for (int i = 0; i <= totalDays; i++) {
        final currentDay = start.add(Duration(days: i));
        final normalizedDay = DateTime(currentDay.year, currentDay.month, currentDay.day);

        bool shouldAddEvent = false;

        if (todo.dateType == TodoDateType.repeat) {
          // ✏️ 수정: repeatDays(요일 배열) 기반 체크
          //   앱 인덱스: 0=일, 1=월, 2=화, 3=수, 4=목, 5=금, 6=토
          //   Flutter weekday: 1=월~6=토, 7=일
          final flutterWd = currentDay.weekday; // 1~7
          final appIndex  = flutterWd == 7 ? 0 : flutterWd; // 일요일(7)→0

          if (todo.repeatDays != null && todo.repeatDays!.isNotEmpty) {
            // repeatDays 기반 요일 체크
            if (todo.repeatDays!.contains(appIndex)) shouldAddEvent = true;
          } else {
            // repeatDays 없으면 시작 요일과 일치하는지 폴백
            if (flutterWd == start.weekday) shouldAddEvent = true;
          }
        } else if (todo.dateType == TodoDateType.range) {
          shouldAddEvent = true;
        } else {
          if (i == 0) shouldAddEvent = true;
        }

        if (shouldAddEvent) {
          if (newEvents[normalizedDay] == null) {
            newEvents[normalizedDay] = [];
          }
          newEvents[normalizedDay]!.add(todo);
        }

        if (todo.dateType == TodoDateType.normal && i == 0) break;
      }
    }

    state = state.copyWith(kEvents: newEvents);
  }

  Future<void> fetchCalendarData() async {
    // fetchTodos(view: 'all') 가 전체 투두를 이미 보유하므로 별도 API 호출 불필요.
    // 달 이동 시 focusedDay 가 바뀌어 calendarEnd 범위가 달라지므로
    // state.allTodos 기반 재계산만 수행한다.
    await SchedulerBinding.instance.endOfFrame;
    if (!mounted) return;
    _updateCalendarEvents(state.allTodos);
  }

  Future<void> setFilter(String filter) async {
    state = state.copyWith(currentFilter: filter);
    _updateDisplayedTodos();
  }

  /// 탭 진입 시 애니메이션 없이 오늘 날짜로 즉시 이동.
  void resetToToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    state = state.copyWith(
      selectedDay: today,
      focusedDay: today,
      pageAnimationEnabled: false,
    );
    _updateDisplayedTodos();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      state = state.copyWith(pageAnimationEnabled: true);
    });
  }

  Future<void> onDaySelected(DateTime selected, DateTime focused) async {
    final prevMonth = state.focusedDay.month;
    final prevYear  = state.focusedDay.year;

    state = state.copyWith(
      selectedDay: DateTime(selected.year, selected.month, selected.day),
      focusedDay:  focused,
    );
    _updateDisplayedTodos();

    // ✅ 달이 바뀐 경우 캘린더 데이터 재조회
    if (focused.month != prevMonth || focused.year != prevYear) {
      await fetchCalendarData();
    }
  }

  void onFormatChanged(CalendarFormat format) {
    state = state.copyWith(calendarFormat: format);
  }

  void addTodo(Todo todo) {
    state = state.copyWith(allTodos: [...state.allTodos, todo]);
    _updateCalendarEvents(state.allTodos);
    _updateDisplayedTodos();
  }

  /// POST /api/todos 응답 DTO 를 Todo 로 변환해 적절한 리스트에 삽입한다.
  /// SOMEDAY 타입은 allSomedayTodos 에, 그 외는 allTodos 에 추가한다.
  /// fetchTodos 없이 POST 응답만으로 목록을 옵티미스틱하게 갱신할 때 사용한다.
  void insertCreatedTodo(TodoDetailResponseDto dto) {
    final todo = _dtoToTodo(dto);
    if (todo.dateType == TodoDateType.someday) {
      state = state.copyWith(
        allSomedayTodos: [...state.allSomedayTodos, todo],
      );
    } else {
      state = state.copyWith(
        allTodos: [...state.allTodos, todo],
      );
      _updateCalendarEvents(state.allTodos);
    }
    _updateDisplayedTodos();
  }

  /// 낙관적 UI: 로컬 ID 를 가진 Todo 를 즉시 목록에 삽입.
  /// API 응답 전 사용자에게 즉각적인 피드백을 준다.
  void insertLocalTodo(Todo todo) {
    if (todo.dateType == TodoDateType.someday) {
      state = state.copyWith(
        allSomedayTodos: [...state.allSomedayTodos, todo],
      );
    } else {
      state = state.copyWith(allTodos: [...state.allTodos, todo]);
      _updateCalendarEvents(state.allTodos);
    }
    _updateDisplayedTodos();
  }

  /// 낙관적 UI: API 성공 후 로컬 Todo 를 서버 응답으로 교체 (실제 ID 반영).
  void replaceLocalTodo(String localId, TodoDetailResponseDto dto) {
    final serverTodo = _dtoToTodo(dto);
    if (state.allSomedayTodos.any((t) => t.id == localId)) {
      state = state.copyWith(
        allSomedayTodos: state.allSomedayTodos
            .map((t) => t.id == localId ? serverTodo : t)
            .toList(),
      );
    } else {
      final updated = state.allTodos
          .map((t) => t.id == localId ? serverTodo : t)
          .toList();
      state = state.copyWith(allTodos: updated);
      _updateCalendarEvents(updated);
    }
    _updateDisplayedTodos();
  }

  /// 낙관적 UI: API 실패 시 로컬 Todo 를 목록에서 제거.
  void removeLocalTodo(String localId) {
    if (state.allSomedayTodos.any((t) => t.id == localId)) {
      state = state.copyWith(
        allSomedayTodos: state.allSomedayTodos
            .where((t) => t.id != localId)
            .toList(),
      );
    } else {
      final updated = state.allTodos.where((t) => t.id != localId).toList();
      state = state.copyWith(allTodos: updated);
      _updateCalendarEvents(updated);
    }
    _updateDisplayedTodos();
  }

  /// TodoDetailResponseDto → Todo 변환 헬퍼.
  /// fetchTodos 의 DTO 매핑 로직과 동일한 규칙을 따른다.
  Todo _dtoToTodo(TodoDetailResponseDto dto) {
    final dateType = _mapTypeFromServer(dto.type);
    return Todo(
      id: dto.todoId.toString(),
      title: dto.title,
      isDone: dto.status == 'DONE',
      category: TodoCategory(
        name: dto.category ?? '기타',
        colorKey: _colorKey(dto.category),
      ),
      date: dto.startDate != null ? DateTime.tryParse(dto.startDate!) : null,
      rangeEnd: dto.type == 'PERIOD' && dto.endDate != null
          ? DateTime.tryParse(dto.endDate!)
          : null,
      repeatEndDate: dto.type == 'RECURRING' && dto.endDate != null
          ? DateTime.tryParse(dto.endDate!)
          : null,
      alarmTime: _parseTime(dto.alarmTime),
      alarmEnabled: dto.alarmTime != null,
      dateType: dateType,
      repeatDays: dto.daysOfWeek != null && dto.daysOfWeek!.isNotEmpty
          ? _parseDaysOfWeek(dto.daysOfWeek!)
          : null,
    );
  }

  Future<void> toggleTodo(String id) async {
    final idx = state.allTodos.indexWhere((t) => t.id == id);
    if (idx == -1) return;

    final wasDone = state.allTodos[idx].isDone;
    final newIsDone = !wasDone;
    final newStatus = newIsDone ? 'DONE' : 'TODO';

    // 1. allTodos isDone 토글 + DONE 으로 가는 경우만 fading 마크.
    //    fading 동안에는 _updateDisplayedTodos 가 done 필터에도 불구하고 카드를 유지 →
    //    사용자가 "주황 체크" 된 모습을 잠깐 본 후 사라짐. TODO 로 되돌리는 경우는
    //    안전 차원에서 혹시 남아있던 fading 마크 정리.
    final newFading = newIsDone
        ? {...state.fadingTodoIds, id}
        : (state.fadingTodoIds.where((it) => it != id).toSet());
    state = state.copyWith(
      allTodos: state.allTodos
          .map((t) => t.id == id ? t.copyWith(isDone: newIsDone) : t)
          .toList(),
      fadingTodoIds: newFading,
    );
    _updateCalendarEvents(state.allTodos);
    _updateDisplayedTodos();

    // 2. PATCH 병렬 발사 — 시각 효과 타이밍을 네트워크 지연과 분리.
    unawaited(
      AsyncValue.guard(() => _repository.updateTodoStatus(id, newStatus)),
    );

    // 3. DONE 으로 토글된 경우 600ms 뒤 fading 해제 → done 필터가 발동해 카드 unmount.
    if (newIsDone) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      if (!state.fadingTodoIds.contains(id)) return;
      state = state.copyWith(
        fadingTodoIds:
        state.fadingTodoIds.where((it) => it != id).toSet(),
      );
      _updateDisplayedTodos();
    }
  }

  Future<void> updateTodo(Todo updated) async {
    // ✅ [수정] 반복 일정인 경우 시작 날짜를 선택된 요일 중 첫 번째 날로 보정
    Todo finalTodo = updated;
    if (updated.dateType == TodoDateType.repeat &&
        updated.repeatDays != null &&
        updated.repeatDays!.isNotEmpty &&
        updated.repeatStartDate != null) {
      DateTime adjustedStart = updated.repeatStartDate!;
      for (int i = 0; i < 7; i++) {
        final candidate = updated.repeatStartDate!.add(Duration(days: i));
        final flutterWd = candidate.weekday;
        final appIdx = flutterWd == 7 ? 0 : flutterWd;
        if (updated.repeatDays!.contains(appIdx)) {
          adjustedStart = candidate;
          break;
        }
      }
      finalTodo = updated.copyWith(date: adjustedStart, repeatStartDate: adjustedStart);
    }

    state = state.copyWith(
      allTodos: state.allTodos
          .map((t) => t.id == finalTodo.id ? finalTodo : t)
          .toList(),
    );
    _updateCalendarEvents(state.allTodos);
    _updateDisplayedTodos();

    // AsyncValue.guard 제거 — 오류를 caller(_onSave)까지 전파해야 fetchTodos 호출을 막을 수 있다.
    // guard로 삼키면 PATCH 실패 후 fetchTodos가 서버 구버전 데이터로 덮어써 "반영 안됨" 현상 발생.
    await _repository.updateTodo(
      finalTodo.id,
      TodoUpdateRequestDto(
        title:     finalTodo.title,
        content:   finalTodo.memo,
        category:  finalTodo.category.name,
        type: switch (finalTodo.dateType) {
          TodoDateType.normal => 'NORMAL',
          TodoDateType.someday => 'SOMEDAY',
          TodoDateType.range  => 'PERIOD',
          TodoDateType.repeat => 'RECURRING',
        },
        // PERIOD 타입은 date picker 확인 시 rangeStart 만 채워지고 date 는 null 이 됨.
        // rangeStart ?? date 로 폴백해야 startDate 가 null 로 날아가는 버그 방지.
        startDate: switch (finalTodo.dateType) {
          TodoDateType.repeat  => finalTodo.repeatStartDate,
          TodoDateType.range   => finalTodo.rangeStart ?? finalTodo.date,
          _                    => finalTodo.date,
        }?.toIso8601String().split('T')[0],
        endDate:   (finalTodo.dateType == TodoDateType.range ? finalTodo.rangeEnd : finalTodo.repeatEndDate)
            ?.toIso8601String().split('T')[0],
        // ✏️ 수정: period → daysOfWeek
        daysOfWeek: finalTodo.repeatDays != null && finalTodo.repeatDays!.isNotEmpty
            ? _repeatDaysToDaysOfWeek(finalTodo.repeatDays!)
            : null,
        // ✏️ 수정: 알람 off 시 clearAlertTime: true 전송
        alarmTime: finalTodo.alarmEnabled ? _formatTime(finalTodo.alarmTime) : null,
        clearAlertTime: finalTodo.alarmEnabled ? null : true,
      ),
    );
  }

  Future<void> deleteTodo(String id, {String? scope}) async {
    state = state.copyWith(
      allTodos: state.allTodos.where((t) => t.id != id).toList(),
    );
    _updateCalendarEvents(state.allTodos);
    _updateDisplayedTodos();
    await AsyncValue.guard(() => _repository.deleteTodo(id, scope: scope));
  }

  Future<void> reorderTodo(int oldIndex, int newIndex) async {
    // ⚠️ ReorderableListView newIndex 보정은 호출자(_CrossSectionTodoList.handleReorder)에서
    // 이미 처리하므로 여기서 다시 -= 1 하지 않는다. 두 번 보정하면 "내릴 때만 1칸 위로
    // 어긋나는" 버그가 발생.
    final list = List<Todo>.from(state.todos);
    final Todo item = list.removeAt(oldIndex);

    // ✅ insert 전에 anchor 계산 — insert 후엔 list[newIndex]가 item 자신이 되어 버림
    final String? anchorId = newIndex < list.length ? list[newIndex].id : null;
    list.insert(newIndex, item);

    final allList = List<Todo>.from(state.allTodos);
    final allIdx = allList.indexWhere((t) => t.id == item.id);
    if (allIdx != -1) {
      allList.removeAt(allIdx);
      final int allInsertIdx = anchorId == null
          ? allList.length
          : () {
        final idx = allList.indexWhere((t) => t.id == anchorId);
        return idx == -1 ? allList.length : idx;
      }();
      allList.insert(allInsertIdx, item);
    }

    state = state.copyWith(todos: list, allTodos: allList);

    // ✅ allTodos 기준 실제 위치로 우선순위 계산 (완료된 항목 포함)
    final newPriority = allList.indexWhere((t) => t.id == item.id) + 1;
    await AsyncValue.guard(
          () => _repository.updateTodoPriority(item.id, newPriority),
    );
  }

  void addSomedayTodo(Todo todo) {
    state = state.copyWith(
        allSomedayTodos: [...state.allSomedayTodos, todo]);
    _updateDisplayedTodos();
  }

  Future<void> toggleSomedayTodo(String id) async {
    final idx = state.allSomedayTodos.indexWhere((t) => t.id == id);
    if (idx == -1) return;

    final wasDone = state.allSomedayTodos[idx].isDone;
    final newIsDone = !wasDone;
    final newStatus = newIsDone ? 'DONE' : 'TODO';

    final newFading = newIsDone
        ? {...state.fadingTodoIds, id}
        : (state.fadingTodoIds.where((it) => it != id).toSet());
    state = state.copyWith(
      allSomedayTodos: state.allSomedayTodos
          .map((t) => t.id == id ? t.copyWith(isDone: newIsDone) : t)
          .toList(),
      fadingTodoIds: newFading,
    );
    _updateDisplayedTodos();

    unawaited(
      AsyncValue.guard(() => _repository.updateTodoStatus(id, newStatus)),
    );

    if (newIsDone) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      if (!state.fadingTodoIds.contains(id)) return;
      state = state.copyWith(
        fadingTodoIds:
        state.fadingTodoIds.where((it) => it != id).toSet(),
      );
      _updateDisplayedTodos();
    }
  }

  Future<void> updateSomedayTodo(Todo updated) async {
    final normalized = updated.copyWith(
      dateType: TodoDateType.someday,
      date: null,
      rangeStart: null,
      rangeEnd: null,
      repeatType: null,
      repeatStartDate: null,
      repeatEndDate: null,
      period: null,
      repeatDays: null,
    );

    state = state.copyWith(
      allSomedayTodos: state.allSomedayTodos
          .map((t) => t.id == normalized.id ? normalized : t)
          .toList(),
    );
    _updateDisplayedTodos();

    // AsyncValue.guard 제거 — updateTodo와 동일한 이유
    await _repository.updateTodo(
      normalized.id,
      TodoUpdateRequestDto(
        title:     normalized.title,
        content:   normalized.memo, // ✅ [버그 수정] 메모 누락으로 항상 null 전송되던 문제 수정
        category:  normalized.category.name,
        type:      'SOMEDAY',
        startDate: null,
        endDate:   null,
        alarmTime: normalized.alarmEnabled ? _formatTime(normalized.alarmTime) : null,
        clearAlertTime: normalized.alarmEnabled ? null : true,
      ),
    );
  }

  Future<void> deleteSomedayTodo(String id) async {
    state = state.copyWith(
      allSomedayTodos:
      state.allSomedayTodos.where((t) => t.id != id).toList(),
    );
    _updateDisplayedTodos();
    await AsyncValue.guard(() => _repository.deleteTodo(id));
  }

  Future<void> reorderSomedayTodo(int oldIndex, int newIndex) async {
    // ⚠️ reorderTodo 와 동일 — 호출자에서 이미 보정하므로 여기선 보정하지 않는다.
    final list = List<Todo>.from(state.somedayTodos);
    final Todo item = list.removeAt(oldIndex);

    // ✅ insert 전에 anchor 계산
    final String? anchorId = newIndex < list.length ? list[newIndex].id : null;
    list.insert(newIndex, item);

    final allList = List<Todo>.from(state.allSomedayTodos);
    final allIdx = allList.indexWhere((t) => t.id == item.id);
    if (allIdx != -1) {
      allList.removeAt(allIdx);
      final int allInsertIdx = anchorId == null
          ? allList.length
          : () {
        final idx = allList.indexWhere((t) => t.id == anchorId);
        return idx == -1 ? allList.length : idx;
      }();
      allList.insert(allInsertIdx, item);
    }

    state = state.copyWith(somedayTodos: list, allSomedayTodos: allList);

    final newPriority = newIndex + 1;
    await AsyncValue.guard(
          () => _repository.updateTodoPriority(item.id, newPriority),
    );
  }

  /// ✅ 오늘의 할 일 → 언젠가 할 일로 이동 (targetIndex: 언젠가 섹션 내 삽입 위치)
  Future<void> moveToSomeday(String id, {int targetIndex = -1}) async {
    final idx = state.allTodos.indexWhere((t) => t.id == id);
    if (idx == -1) return;

    final item = state.allTodos[idx].copyWith(
      dateType: TodoDateType.someday,
      date: null,
      rangeStart: null,
      rangeEnd: null,
      repeatType: null,
      repeatStartDate: null,
      repeatEndDate: null,
      repeatDays: null,
    );

    // 로컬 상태 업데이트 — 지정 위치에 삽입
    final newSomeday = List<Todo>.from(state.allSomedayTodos);
    final insertAt = (targetIndex < 0 || targetIndex > newSomeday.length)
        ? newSomeday.length
        : targetIndex;
    newSomeday.insert(insertAt, item);

    final newAllTodos = state.allTodos.where((t) => t.id != id).toList();
    state = state.copyWith(
      allTodos: newAllTodos,
      allSomedayTodos: newSomeday,
    );
    _updateCalendarEvents(newAllTodos);
    _updateDisplayedTodos();

    // ✅ 완료된 항목은 서버가 type 변경 422 반환 → updateTodo 건너뜀
    if (!item.isDone) {
      await AsyncValue.guard(() => _repository.updateTodo(
        id,
        TodoUpdateRequestDto(
          title:    item.title,
          content:  item.memo,
          category: item.category.name,
          type:     'SOMEDAY',
          startDate: null,
          endDate:   null,
          alarmTime: item.alarmEnabled ? _formatTime(item.alarmTime) : null,
          clearAlertTime: item.alarmEnabled ? null : true,
        ),
      ));
    }

    // 우선순위 설정 (완료 여부 무관하게 항상 적용)
    await AsyncValue.guard(
            () => _repository.updateTodoPriority(id, insertAt + 1));
  }

  /// 언젠가 할 일 → 오늘의 할 일로 이동 (targetIndex: 오늘 섹션 내 삽입 위치)
  /// targetDate: 캘린더에서 선택된 날짜 — null 이면 오늘로 폴백.
  Future<void> moveToToday(String id, {int targetIndex = -1, DateTime? targetDate}) async {
    final idx = state.allSomedayTodos.indexWhere((t) => t.id == id);
    if (idx == -1) return;

    final now = DateTime.now();
    final today = targetDate ?? DateTime(now.year, now.month, now.day);
    final item = state.allSomedayTodos[idx].copyWith(
      dateType: TodoDateType.normal,
      date: today,
    );

    // ── 표시 목록(todos)에 먼저 삽입 — reorderTodo 와 동일한 앵커 방식 ──
    // allTodos 는 여러 날짜 항목이 섞여 있어 targetIndex 를 직접 절대 인덱스로
    // 쓰면 위치가 틀린다. 삽입 후 targetIndex 자리에 있어야 할 기존 항목(anchorId)을
    // 기준으로 allTodos 내 삽입 지점을 결정한다.
    final displayList = List<Todo>.from(state.todos);
    final insertInDisplay = targetIndex.clamp(0, displayList.length);
    final String? anchorId = insertInDisplay < displayList.length
        ? displayList[insertInDisplay].id
        : null;
    displayList.insert(insertInDisplay, item);

    final allList = List<Todo>.from(state.allTodos);
    final int allInsertIdx = anchorId == null
        ? allList.length
        : () {
            final i = allList.indexWhere((t) => t.id == anchorId);
            return i == -1 ? allList.length : i;
          }();
    allList.insert(allInsertIdx, item);

    final newAllSomeday = state.allSomedayTodos.where((t) => t.id != id).toList();
    state = state.copyWith(
      allSomedayTodos: newAllSomeday,
      somedayTodos:    state.somedayTodos.where((t) => t.id != id).toList(),
      allTodos: allList,
      todos:    displayList,
    );
    _updateCalendarEvents(allList);

    // ✅ 완료된 항목은 서버가 type 변경 422 반환 → updateTodo 건너뜀
    if (!item.isDone) {
      await AsyncValue.guard(() => _repository.updateTodo(
        id,
        TodoUpdateRequestDto(
          title:     item.title,
          content:   item.memo,
          category:  item.category.name,
          type:      'NORMAL',
          startDate: today.toIso8601String().split('T')[0],
          endDate:   null,
          alarmTime: item.alarmEnabled ? _formatTime(item.alarmTime) : null,
          clearAlertTime: item.alarmEnabled ? null : true,
        ),
      ));
    }

    // 우선순위: allTodos 기준 실제 위치 (reorderTodo 와 동일한 계산)
    final newPriority = allList.indexWhere((t) => t.id == id) + 1;
    await AsyncValue.guard(
            () => _repository.updateTodoPriority(id, newPriority));
  }

  Future<void> snoozeTodo(String id) async {
    final idx = state.allTodos.indexWhere((t) => t.id == id);
    if (idx == -1) return;

    final target = state.allTodos[idx];
    if (target.isDone) return;

    if (target.dateType == TodoDateType.repeat) {
      print('⚠️ 반복 일정은 아직 미루기를 지원하지 않습니다.');
      return;
    }

    final hadAlarm = target.alarmEnabled;

    final snoozed = target.copyWith(
      date: target.date != null ? target.date!.add(const Duration(days: 1)) : null,
      rangeEnd: target.rangeEnd != null ? target.rangeEnd!.add(const Duration(days: 1)) : null,
      alarmTime: null,
      alarmEnabled: false,
    );

    state = state.copyWith(
      allTodos: state.allTodos.map((t) => t.id == id ? snoozed : t).toList(),
    );
    _updateDisplayedTodos();

    await AsyncValue.guard(() => _repository.snoozeTodo(id));

    if (hadAlarm) {
      await AsyncValue.guard(() => _repository.updateTodo(
        id,
        TodoUpdateRequestDto(
          title:     snoozed.title,
          content:   snoozed.memo,
          category:  snoozed.category.name,
          type: switch (snoozed.dateType) {
            TodoDateType.normal  => 'NORMAL',
            TodoDateType.someday => 'SOMEDAY',
            TodoDateType.range   => 'PERIOD',
            TodoDateType.repeat  => 'RECURRING',
          },
          startDate: switch (snoozed.dateType) {
            TodoDateType.range => snoozed.rangeStart ?? snoozed.date,
            _                  => snoozed.date,
          }?.toIso8601String().split('T')[0],
          endDate: snoozed.rangeEnd?.toIso8601String().split('T')[0],
          alarmTime: null,
          clearAlertTime: true,
        ),
      ));
    }

    fetchTodos();
  }

  TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null || !timeStr.contains(':')) return null;
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return null;
    }
  }

  String? _formatTime(TimeOfDay? time) {
    if (time == null) return null;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  // ✏️ 추가: 서버 daysOfWeek(["MON","FRI"]) → 앱 인덱스([1,5]) 변환
  // 앱 인덱스: 0=일, 1=월, 2=화, 3=수, 4=목, 5=금, 6=토
  static List<int> _parseDaysOfWeek(List<String> daysOfWeek) {
    const codeToIndex = {
      'SUN': 0, 'MON': 1, 'TUE': 2, 'WED': 3,
      'THU': 4, 'FRI': 5, 'SAT': 6,
    };
    return daysOfWeek
        .map((code) => codeToIndex[code.toUpperCase()])
        .whereType<int>()
        .toList();
  }

  // ✏️ 추가: 앱 인덱스([1,5]) → 서버 daysOfWeek({"MON","FRI"}) 변환
  static Set<String> _repeatDaysToDaysOfWeek(List<int> repeatDays) {
    const indexToCode = {
      0: 'SUN', 1: 'MON', 2: 'TUE', 3: 'WED',
      4: 'THU', 5: 'FRI', 6: 'SAT',
    };
    return repeatDays
        .map((i) => indexToCode[i])
        .whereType<String>()
        .toSet();
  }

  // ── 위젯 동기화 ──────────────────────────────────────────────
  // addListener 로 매 state 변경마다 호출됨. 홈스크린 위젯이 보여줄 형태
  // (오늘 + 나중에) 로 가공해 SharedPreferences 에 push.
  // 네트워크/디스크 I/O 가 살짝 들어가지만 await 하지 않고 unawaited 처리해
  // ViewModel 의 reactive 흐름은 막지 않는다.
  void _syncWidget(TodoState s) {
    final today = DateTime.now();
    final todayTodos = s.allTodos
        .where((t) => _isTodayForWidget(t, today))
        .map(_toWidgetDto)
        .toList(growable: false);
    final somedayTodos =
    s.allSomedayTodos.map(_toWidgetDto).toList(growable: false);
    unawaited(_widgetSync.syncTodos(
      todayTodos: todayTodos,
      somedayTodos: somedayTodos,
    ));
  }

  static WidgetTodoDto _toWidgetDto(Todo t) => WidgetTodoDto(
    id: int.tryParse(t.id) ?? 0,
    title: t.title,
    isDone: t.isDone,
    isSomeday: t.dateType == TodoDateType.someday,
  );

  /// `tamagochi_page._isTodayTodo` 와 동일 로직 — 위젯 "오늘" 섹션 필터.
  /// 단일=오늘, 기간=오늘이 시작~종료 사이, 반복=시작 이후 + 종료 이내.
  static bool _isTodayForWidget(Todo todo, DateTime today) {
    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    bool onOrBefore(DateTime a, DateTime b) =>
        a.isBefore(b) || sameDay(a, b);
    switch (todo.dateType) {
      case TodoDateType.normal:
        return todo.date != null && sameDay(todo.date!, today);
      case TodoDateType.someday:
        return false;
      case TodoDateType.range:
        final start = todo.rangeStart;
        final end = todo.rangeEnd;
        if (start == null) return false;
        if (!onOrBefore(start, today)) return false;
        if (end == null) return true;
        return onOrBefore(today, end);
      case TodoDateType.repeat:
        final start = todo.repeatStartDate;
        final end = todo.repeatEndDate;
        if (start == null) return false;
        if (!onOrBefore(start, today)) return false;
        if (end == null) return true;
        return onOrBefore(today, end);
    }
  }
}

final todoViewModelProvider =
StateNotifierProvider.autoDispose<TodoViewModel, TodoState>((ref) {
  return TodoViewModel(
    ref.read(todoRepositoryProvider),
    ref.read(widgetSyncServiceProvider),
  );
});