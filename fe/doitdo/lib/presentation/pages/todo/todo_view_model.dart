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

  // POST 응답 전에 삭제된 로컬 임시 ID 추적.
  // replaceLocalTodo 시 여기 있으면 실제 서버 ID로 DELETE를 즉시 전송.
  final Set<String> _pendingDeleteLocalIds = {};

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

  // 빠른 연속 토글 시 마지막 상태만 서버로 전송 — per-todo 디바운스.
  final Map<String, Timer> _toggleTimers = {};
  int _rewardGainTick = 0;

  @override
  void dispose() {
    for (final t in _toggleTimers.values) t.cancel();
    _toggleTimers.clear();
    super.dispose();
  }

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
              // scope=only 로 삭제된 날짜는 표시 안 함
              final selStr = '${sel.year}-${sel.month.toString().padLeft(2,'0')}-${sel.day.toString().padLeft(2,'0')}';
              if (state.excludedOccurrences.contains('${t.id}_$selStr')) return false;

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

    // RECURRING 완료 후 fetchTodos() 로 NORMAL 인스턴스가 추가되면
    // 같은 날짜에 RECURRING 마스터와 NORMAL 인스턴스가 동시에 표시되는 문제 방지.
    // NORMAL 인스턴스가 있는 날짜엔 같은 제목+카테고리의 RECURRING 마스터를 숨긴다.
    if (selectedDay != null) {
      // RECURRING 완료 후 같은 날짜에 RECURRING 마스터와 NORMAL 인스턴스가
      // 동시에 표시되는 문제 방지. title 기준으로만 매칭한다.
      // (title + category 조합은 카테고리 변경 시 매칭 실패로 중복 표시 버그 발생)
      final normalKeys = filteredTodos
          .where((t) =>
      t.dateType == TodoDateType.normal &&
          t.date != null &&
          isSameDay(t.date!, selectedDay!))
          .map((t) => t.title)
          .toSet();

      if (normalKeys.isNotEmpty) {
        filteredTodos = filteredTodos.where((t) {
          if (t.dateType != TodoDateType.repeat) return true;
          return !normalKeys.contains(t.title);
        }).toList();
      }
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
        categoryId: dto.categoryId,
        colorHex: dto.colorHex,
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
        // 같은 반복 흐름 묶음용 ID — scope=from 으로 분할돼도 같은 값.
        // 시리즈 전체 삭제, 시각적 그룹핑 등에 사용.
        recurrenceGroupId: dto.recurrenceGroupId,
      )).toList();

      // 서버 list API 가 RECURRING 투두의 daysOfWeek 를 [] 로 반환하는 경우
      // (BE가 해당 필드를 list 응답에 미포함), 기존 state 에서 repeatDays 를 보존.
      // 앱 재시작 후 첫 fetch 에서는 보존할 대상이 없으므로 null 유지 — 이 경우
      // BE 에 list API 에서 daysOfWeek 를 포함하도록 요청 필요.
      final existingDaysMap = {
        for (final t in state.allTodos)
          if (t.repeatDays != null && t.repeatDays!.isNotEmpty)
            t.id: t.repeatDays!,
      };
      final mergedFetched = allFetched.map((t) {
        if (t.dateType == TodoDateType.repeat &&
            (t.repeatDays == null || t.repeatDays!.isEmpty)) {
          final preserved = existingDaysMap[t.id];
          if (preserved != null) return t.copyWith(repeatDays: preserved);
        }
        return t;
      }).toList();

      // ✏️ 수정: PERIOD 타입은 rangeStart(또는 date)를 기준으로 분류
      //   date가 null이어도 rangeEnd가 있으면 날짜 있는 할 일
      //
      // ✅ excludedOccurrences hydrate (BE MR !281)
      // 서버가 RECURRING 마스터마다 scope=only로 삭제된 날짜를
      // excludedDates: ["2026-05-14", ...] 로 내려준다.
      // 키 포맷은 기존 로컬 키와 동일하게 "${todoId}_${yyyy-MM-dd}".
      // 앱 재시작/다른 기기에서도 삭제된 occurrence가 다시 보이지 않도록
      // 서버 응답을 source of truth로 삼아 매번 set을 새로 만든다.
      final hydratedExcluded = <String>{
        // 삭제된 RECURRING occurrence (마스터의 excludedDates)
        for (final dto in sortedItems)
          if (dto.type == 'RECURRING')
            for (final d in dto.excludedDates) '${dto.todoId}_$d',
        // 수정된 NORMAL 인스턴스(scope=only) — 해당 날짜 마스터 가상 occurrence 숨김.
        // BE: 살아있는 인스턴스는 excludedDates에 포함 안 됨 → FE가 직접 처리.
        for (final dto in sortedItems)
          if (dto.masterTodoId != null && dto.occurrenceDate != null)
            '${dto.masterTodoId}_${dto.occurrenceDate}',
      };

      state = state.copyWith(
        allTodos: mergedFetched
            .where((t) => t.dateType != TodoDateType.someday)
            .toList(),
        allSomedayTodos: mergedFetched
            .where((t) => t.dateType == TodoDateType.someday)
            .toList(),
        excludedOccurrences: {...state.excludedOccurrences, ...hydratedExcluded},
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
          // scope=only 로 삭제된 날짜는 캘린더 점에서도 제외
          final dayStr = '${normalizedDay.year}-${normalizedDay.month.toString().padLeft(2,'0')}-${normalizedDay.day.toString().padLeft(2,'0')}';
          if (state.excludedOccurrences.contains('${todo.id}_$dayStr')) {
            shouldAddEvent = false;
          } else {
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
    // POST 응답 전에 삭제된 경우 → 서버 ID로 즉시 DELETE 전송
    if (_pendingDeleteLocalIds.remove(localId)) {
      unawaited(deleteTodo(serverTodo.id));
    }
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
    // POST 실패 → pending delete 도 정리
    _pendingDeleteLocalIds.remove(localId);
  }

  /// RECURRING todo 의 repeatDays 를 detail API 응답으로 채운다.
  /// list API 가 daysOfWeek:[] 를 반환하는 경우 detail sheet 에서 fetch 후 호출.
  void patchRepeatDays(String todoId, List<int> days) {
    if (days.isEmpty) return;
    final updated = state.allTodos
        .map((t) => t.id == todoId ? t.copyWith(repeatDays: days) : t)
        .toList();
    state = state.copyWith(allTodos: updated);
    _updateCalendarEvents(updated);
    _updateDisplayedTodos();
  }

  void _emitStatusRewardIfNeeded(TodoDetailResponseDto? dto) {
    if (dto == null) return;
    if (!dto.rewarded || dto.earnedCoin <= 0) return;
    _rewardGainTick += 1;
    state = state.copyWith(
      lastRewardGain: TodoRewardGain(
        amount: dto.earnedCoin,
        tick: _rewardGainTick,
      ),
    );
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
      colorHex: dto.colorHex,
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
      // 같은 반복 흐름 묶음용 ID — scope=from 으로 분할돼도 같은 값.
      recurrenceGroupId: dto.recurrenceGroupId,
    );
  }

  Future<void> toggleTodo(String id) async {
    final idx = state.allTodos.indexWhere((t) => t.id == id);
    if (idx == -1) return;

    final todo = state.allTodos[idx];
    final wasDone = todo.isDone;
    final newIsDone = !wasDone;
    final newStatus = newIsDone ? 'DONE' : 'TODO';

    // RECURRING 타입은 낙관적 업데이트 스킵.
    // 마스터의 isDone 을 바꾸면 _updateCalendarEvents 의 copyWith 로
    // 모든 날짜 복사본에 isDone: true 가 전파되어 전체가 완료 처리됨.
    // 대신 임시 NORMAL 인스턴스를 즉시 추가하고 API 성공 후 실제 id로 교체.
    final isRecurring = todo.dateType == TodoDateType.repeat;

    if (!isRecurring) {
      // 1. 일반 타입만 낙관적 업데이트 + fading 마크
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
    }

    // 2. API 호출
    if (isRecurring) {
      final occurrenceDate = state.selectedDay ?? DateTime.now();
      final tempId = 'temp_$id';

      // 연타 방지: 이미 처리 중(임시 인스턴스 존재)이면 무시
      if (state.allTodos.any((t) => t.id == tempId)) return;

      // 낙관적 업데이트: 임시 NORMAL 인스턴스를 마스터 위치에 즉시 삽입
      final tempTodo = todo.copyWith(
        id: tempId,
        isDone: newIsDone,
        dateType: TodoDateType.normal,
        date: occurrenceDate,
      );
      final masterIdx = state.allTodos.indexWhere((t) => t.id == id);
      final optimisticList = List<Todo>.from(state.allTodos);
      if (masterIdx >= 0) {
        optimisticList.insert(masterIdx, tempTodo);
      } else {
        optimisticList.add(tempTodo);
      }
      state = state.copyWith(
        allTodos: optimisticList,
        fadingTodoIds: newIsDone
            ? {...state.fadingTodoIds, tempId}
            : state.fadingTodoIds,
      );
      _updateCalendarEvents(state.allTodos);
      _updateDisplayedTodos();

      // 백그라운드 API
      unawaited(
        AsyncValue.guard(
              () => _repository.updateTodoStatus(
            id,
            newStatus,
            occurrenceDate: occurrenceDate,
          ),
        ).then((result) {
          if (!mounted) return;
          if (result.hasError) {
            // 실패: 임시 인스턴스 제거(롤백)
            state = state.copyWith(
              allTodos: state.allTodos.where((t) => t.id != tempId).toList(),
              fadingTodoIds: state.fadingTodoIds.where((it) => it != tempId).toSet(),
            );
            _updateCalendarEvents(state.allTodos);
            _updateDisplayedTodos();
            return;
          }
          // 성공: 임시 인스턴스를 실제 서버 인스턴스로 교체
          final dto = result.value;
          if (dto != null) {
            _emitStatusRewardIfNeeded(dto);
            final realTodo = Todo(
              id: dto.todoId.toString(),
              title: dto.title,
              isDone: dto.status == 'DONE',
              memo: dto.content,
              category: TodoCategory(
                name: dto.category ?? '기타',
                colorKey: _colorKey(dto.category),
              ),
              colorHex: dto.colorHex,
              date: dto.startDate != null ? DateTime.tryParse(dto.startDate!) : null,
              alarmTime: _parseTime(dto.alarmTime),
              alarmEnabled: dto.alarmTime != null,
              dateType: TodoDateType.normal,
              // 같은 반복 흐름 묶음용 ID (BE 가 NORMAL 파생 인스턴스에도 채워 내려줌)
              recurrenceGroupId: dto.recurrenceGroupId,
            );
            // fading id도 tempId → realId 로 교체
            final newFading = {
              ...state.fadingTodoIds.where((it) => it != tempId),
              if (newIsDone) realTodo.id,
            };
            state = state.copyWith(
              allTodos: state.allTodos
                  .map((t) => t.id == tempId ? realTodo : t)
                  .toList(),
              fadingTodoIds: newFading,
            );
            _updateCalendarEvents(state.allTodos);
            _updateDisplayedTodos();
          } else {
            // dto 파싱 실패 시에도 tempId → 정리
            state = state.copyWith(
              allTodos: state.allTodos.where((t) => t.id != tempId).toList(),
              fadingTodoIds: state.fadingTodoIds.where((it) => it != tempId).toSet(),
            );
            _updateCalendarEvents(state.allTodos);
            _updateDisplayedTodos();
          }
        }),
      );
    } else {
      _toggleTimers[id] = Timer(const Duration(milliseconds: 400), () async {
        _toggleTimers.remove(id);
        final result = await AsyncValue.guard(
              () => _repository.updateTodoStatus(id, newStatus),
        );
        if (!mounted) return;
        if (result.hasError) {
          state = state.copyWith(
            allTodos: state.allTodos
                .map((t) => t.id == id ? t.copyWith(isDone: wasDone) : t)
                .toList(),
            fadingTodoIds: state.fadingTodoIds.where((it) => it != id).toSet(),
          );
          _updateCalendarEvents(state.allTodos);
          _updateDisplayedTodos();
        } else {
          _emitStatusRewardIfNeeded(result.value);
        }
      });
    }

    // 3. DONE 으로 토글된 경우 600ms 뒤 fading 해제 (일반 타입만)
    if (!isRecurring && newIsDone) {
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

  /// 반복 todo 수정 정책 (BE MR !300 반영).
  ///
  /// - 모든 RECURRING 수정은 "전체 수정" 으로 통일. scope=from/only 분기 없음.
  /// - BE 는 마스터를 직접 수정하고 미완료(DONE 아닌) 파생 인스턴스에도
  ///   title/content/category/alertTime 을 자동 반영. DONE 은 히스토리 보존.
  /// - 분할(새 마스터 생성) 이 일어나지 않으므로 todoId 가 유지된다.
  ///
  /// [scope] / [occurrenceDate] 파라미터는 하위 호환을 위해 시그니처에 남겨두지만
  /// **수정 흐름에서는 무시**한다. 단건 발생일만 별도 분기하는 기능은 제거됨.
  /// (삭제는 [deleteTodo] 가 scope=only/from 을 그대로 사용한다.)
  Future<void> updateTodo(Todo updated, {String? scope, DateTime? occurrenceDate}) async {
    // RECURRING 타입이면 `date` 가 null 일 수 있으므로(TodoDateResult.repeat 는 date 미포함)
    // repeatStartDate 로 채워준다.
    Todo finalTodo = updated;
    if (updated.dateType == TodoDateType.repeat && updated.repeatStartDate != null) {
      finalTodo = updated.copyWith(date: updated.date ?? updated.repeatStartDate);
    }

    // ── BE 정책 (MR !300+): RECURRING 수정 시 startDate 를 body 에 안 보내면 ─
    //   - 기존 startDate 요일이 새 daysOfWeek 에 없어도 허용 (T14-002 발생 X)
    //   - startDate 는 반복 시작 경계로 그대로 유지
    //   - 앞으로 생성되는 가상 occurrence 는 새 daysOfWeek 기준으로 생성
    //
    // → 사용자가 startDate 를 명시적으로 바꾸지 않았다면 body 에서 빼서 전송한다.
    //   (이전엔 FE 가 startDate 를 자동 시프트했는데, 그 로직은 BE 정책으로 대체됨)
    // 원본 알람 상태 캡처 (state 변경 전). 원본에 알람이 있었고 수정 후 없어진
    // 경우에만 clearAlertTime=true 전송 — 알람이 없던 투두에 보내면 T03-004 발생.
    final originalTodo = state.allTodos.where((t) => t.id == finalTodo.id).firstOrNull;
    final clearAlarm = (originalTodo?.alarmEnabled ?? false) && !finalTodo.alarmEnabled;

    DateTime? _startOf(Todo t) => switch (t.dateType) {
          TodoDateType.repeat => t.repeatStartDate ?? t.date,
          TodoDateType.range  => t.rangeStart ?? t.date,
          _                   => t.date,
        };
    final newStart = _startOf(finalTodo);
    final origStart = originalTodo == null ? null : _startOf(originalTodo);
    final startUnchanged = newStart != null &&
        origStart != null &&
        newStart.year == origStart.year &&
        newStart.month == origStart.month &&
        newStart.day == origStart.day;
    // RECURRING 에서 startDate 가 안 바뀌었다면 body 에 null 로 보낸다.
    // 그 외 타입(NORMAL/PERIOD/SOMEDAY) 은 BE 가 startDate 필수일 수 있으므로 항상 전송.
    final omitStartDate =
        finalTodo.dateType == TodoDateType.repeat && startUnchanged;

    // 낙관적 업데이트: 로컬 state 의 해당 todo 를 수정값으로 교체.
    state = state.copyWith(
      allTodos: state.allTodos
          .map((t) => t.id == finalTodo.id ? finalTodo : t)
          .toList(),
    );
    _updateCalendarEvents(state.allTodos);
    _updateDisplayedTodos();

    // 요청 body 빌드 — 항상 마스터 일괄 수정.
    // - RECURRING: 기본은 startDate/endDate/daysOfWeek 전송.
    //              단, startDate 가 안 바뀌었으면 null 로 omit → BE 가 boundary 유지
    // - PERIOD/NORMAL/SOMEDAY: 기존 규칙 동일
    final endDate = finalTodo.dateType == TodoDateType.range
        ? finalTodo.rangeEnd
        : finalTodo.repeatEndDate;
    final requestDto = TodoUpdateRequestDto(
      title:      finalTodo.title,
      content:    finalTodo.memo,
      categoryId: finalTodo.categoryId,
      type: switch (finalTodo.dateType) {
        TodoDateType.normal  => 'NORMAL',
        TodoDateType.someday => 'SOMEDAY',
        TodoDateType.range   => 'PERIOD',
        TodoDateType.repeat  => 'RECURRING',
      },
      // RECURRING + startDate 안 바뀜 → null. 그 외 케이스는 newStart 그대로.
      startDate: omitStartDate
          ? null
          : newStart?.toIso8601String().split('T')[0],
      endDate: endDate?.toIso8601String().split('T')[0],
      daysOfWeek: finalTodo.repeatDays != null && finalTodo.repeatDays!.isNotEmpty
          ? _repeatDaysToDaysOfWeek(finalTodo.repeatDays!)
          : null,
      alarmTime: finalTodo.alarmEnabled ? _formatTime(finalTodo.alarmTime) : null,
      clearAlertTime: clearAlarm ? true : null,
    );

    // AsyncValue.guard 제거 — 오류를 caller(_onSave) 까지 전파해야 후속 fetchTodos 호출을
    // 막을 수 있다. guard 로 삼키면 PATCH 실패 후 fetchTodos 가 서버 구버전 데이터로
    // 덮어써 "반영 안됨" 현상 발생.
    //
    // scope 파라미터는 BE 호환을 위해 안 보낸다 (안 보내도 BE 가 일괄 수정).
    // BE 가 미완료 파생 인스턴스를 자동 갱신하므로 FE 는 fetchTodos 로 동기화하면 끝.
    await _repository.updateTodo(finalTodo.id, requestDto);
  }

  Future<void> deleteTodo(String id, {String? scope, DateTime? occurrenceDate}) async {
    // ── 시리즈 전체 삭제 (FE 자체 scope='series') ───────────────────────────
    // 같은 recurrenceGroupId 를 가진 모든 todo (분할된 마스터들 + 파생 인스턴스)
    // 를 한 번에 정리한다. BE 에 전용 엔드포인트가 없으므로 같은 group 의
    // 마스터(원본 + scope=from 분할본) 각각에 scope=all 로 DELETE 요청.
    if (scope == 'series') {
      final target = state.allTodos.where((t) => t.id == id).firstOrNull;
      final groupId = target?.recurrenceGroupId;
      if (groupId == null) {
        // 시리즈 정보 없으면 일반 단건 삭제로 폴백.
        return deleteTodo(id);
      }
      // 같은 group 의 RECURRING 마스터들(파생 NORMAL 인스턴스는 BE 가
      // scope=all 처리하며 함께 정리하므로 마스터만 호출하면 충분).
      final mastersInSeries = state.allTodos
          .where((t) =>
              t.recurrenceGroupId == groupId &&
              t.dateType == TodoDateType.repeat)
          .toList();

      // 낙관적: 같은 group 전체를 화면에서 제거
      state = state.copyWith(
        allTodos: state.allTodos
            .where((t) => t.recurrenceGroupId != groupId)
            .toList(),
      );
      _updateCalendarEvents(state.allTodos);
      _updateDisplayedTodos();

      // 마스터마다 scope=all 호출 (병렬). 실패는 fetchTodos 가 정정.
      await Future.wait(mastersInSeries.map((m) => AsyncValue.guard(
            () => _repository.deleteTodo(m.id, scope: 'all'),
          )));
      await fetchTodos();
      return;
    }

    if (scope == 'only' && occurrenceDate != null) {
      final dateStr = occurrenceDate.toIso8601String().split('T')[0];
      final key = '${id}_$dateStr';
      final target = state.allTodos.where((t) => t.id == id).firstOrNull;
      if (target != null && target.dateType == TodoDateType.repeat) {
        // RECURRING: 마스터는 유지하고 해당 날짜 발생분만 제외
        state = state.copyWith(
          excludedOccurrences: {...state.excludedOccurrences, key},
        );
      } else {
        // NORMAL/PERIOD: 마스터 자체를 삭제 → allTodos에서 제거
        state = state.copyWith(
          allTodos: state.allTodos.where((t) => t.id != id).toList(),
        );
      }
      _updateCalendarEvents(state.allTodos);
      _updateDisplayedTodos();
    } else if (scope == 'from') {
      // ── 옵션 B: scope=from 삭제도 시리즈 후속 마스터까지 함께 정리 ─────────
      //
      // 사용자가 "이 일정과 이후 모두 삭제" 를 누르면, 현재 마스터 뒤에 분할 생성된
      // 후속 마스터들(같은 recurrenceGroupId) 까지 함께 사라져야 "이후 모두" 가
      // 진짜 시리즈 끝까지 의미를 가진다. (안 그러면 후속 마스터가 그대로 남음)
      //
      // ⚠️ 시간 순서 체크 필수: 현재 마스터보다 startDate 가 **뒤** 인 마스터만 후속.
      // 같은 group 이라도 앞에 있는 (과거) 마스터를 삭제하면 분할 이전 기간이 함께
      // 사라져버려 사용자 의도와 정반대로 동작한다.
      final target = state.allTodos.where((t) => t.id == id).firstOrNull;
      final groupId = target?.recurrenceGroupId;
      final targetStart = target?.date ?? target?.repeatStartDate;
      final subsequentSeriesMasters =
          (groupId == null || targetStart == null)
              ? const <Todo>[]
              : state.allTodos
                  .where((t) {
                    if (t.id == id) return false;
                    if (t.recurrenceGroupId != groupId) return false;
                    if (t.dateType != TodoDateType.repeat) return false;
                    final tStart = t.date ?? t.repeatStartDate;
                    if (tStart == null) return false;
                    return tStart.isAfter(targetStart); // 뒤에 있는 것만
                  })
                  .toList();

      // 낙관적 업데이트:
      //   - 현재 마스터: repeatEndDate 를 occurrenceDate-1 로 줄임 (과거 부분 보존)
      //   - 단, 줄인 endDate 가 startDate 보다 이전이면 마스터 자체가 의미 없으니 제거
      //   - 후속 마스터들(시리즈 분할 잔재): scope=all 로 BE 도 삭제하므로 화면에서 제거
      //
      // 이전 버그: 마스터를 통째로 제거해 사용자가 "이후 삭제" 한 뒤에도 과거 부분이
      // 화면에서 잠시 사라졌다가 fetchTodos 후 돌아오는 어색한 동작 + 사용자 의도(과거 유지)
      // 와 어긋나는 인상을 줌.
      if (occurrenceDate == null) return;
      final occurrenceDateOnly = DateTime(
        occurrenceDate.year,
        occurrenceDate.month,
        occurrenceDate.day,
      );
      final newEndDate =
          occurrenceDateOnly.subtract(const Duration(days: 1));
      final masterStart = targetStart;
      final shouldRemoveMasterCompletely =
          masterStart != null && newEndDate.isBefore(masterStart);
      final subsequentIds =
          subsequentSeriesMasters.map((t) => t.id).toSet();
      final removeIds = <String>{
        ...subsequentIds,
        if (shouldRemoveMasterCompletely) id,
      };
      state = state.copyWith(
        allTodos: state.allTodos
            .where((t) => !removeIds.contains(t.id))
            .map((t) {
              if (!shouldRemoveMasterCompletely && t.id == id) {
                return t.copyWith(repeatEndDate: newEndDate);
              }
              return t;
            })
            .toList(),
      );
      _updateCalendarEvents(state.allTodos);
      _updateDisplayedTodos();

      // BE 동기화: 현재 마스터 scope=from + 후속 마스터들 scope=all 병렬 호출
      await Future.wait([
        AsyncValue.guard(() => _repository.deleteTodo(
              id,
              scope: 'from',
              occurrenceDate: occurrenceDate,
            )),
        ...subsequentSeriesMasters.map((m) => AsyncValue.guard(
            () => _repository.deleteTodo(m.id, scope: 'all'))),
      ]);
      await fetchTodos();
      return;
    } else {
      state = state.copyWith(
        allTodos: state.allTodos.where((t) => t.id != id).toList(),
      );
      _updateCalendarEvents(state.allTodos);
      _updateDisplayedTodos();
      // 로컬 임시 ID — POST 완료 후 replaceLocalTodo 에서 실제 DELETE 전송
      if (int.tryParse(id) == null) {
        _pendingDeleteLocalIds.add(id);
        return;
      }
    }
    await AsyncValue.guard(
      () => _repository.deleteTodo(id, scope: scope, occurrenceDate: occurrenceDate),
    );
    await fetchTodos();
  }

  /// 같은 반복 시리즈에 속한 RECURRING 마스터 개수 반환.
  ///
  /// scope=from 으로 분할된 적이 있으면 2 이상. 1 이면 분할 없음(혹은 마스터 하나).
  /// 다이얼로그에서 "시리즈 전체 삭제" 옵션 노출 여부 결정에 사용.
  int countMastersInSeries(int recurrenceGroupId) {
    return state.allTodos
        .where((t) =>
            t.recurrenceGroupId == recurrenceGroupId &&
            t.dateType == TodoDateType.repeat)
        .length;
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
        title:      normalized.title,
        content:    normalized.memo,
        categoryId: normalized.categoryId,
        type:       'SOMEDAY',
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
          title:      item.title,
          content:    item.memo,
          categoryId: item.categoryId,
          type:       'SOMEDAY',
          startDate:  null,
          endDate:    null,
          alarmTime:      item.alarmEnabled ? _formatTime(item.alarmTime) : null,
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
          title:      item.title,
          content:    item.memo,
          categoryId: item.categoryId,
          type:       'NORMAL',
          startDate:  today.toIso8601String().split('T')[0],
          endDate:    null,
          alarmTime:      item.alarmEnabled ? _formatTime(item.alarmTime) : null,
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
          title:      snoozed.title,
          content:    snoozed.memo,
          categoryId: snoozed.categoryId,
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
        .where((t) => _isTodayForWidget(t, today, s.excludedOccurrences))
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
  /// [excludedOccurrences] 는 scope=only 로 삭제된 반복 발생 키 집합.
  static bool _isTodayForWidget(
    Todo todo,
    DateTime today, [
    Set<String> excludedOccurrences = const {},
  ]) {
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
        if (end != null && !onOrBefore(today, end)) return false;
        // ✅ scope=only 로 오늘 발생분이 삭제됐다면 위젯에서도 제외
        final todayStr =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        if (excludedOccurrences.contains('${todo.id}_$todayStr')) return false;
        return true;
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
