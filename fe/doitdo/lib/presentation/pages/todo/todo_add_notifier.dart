import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/presentation/models/todo.dart';
import 'package:doitdo/presentation/pages/todo/todo_view_model.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart'; // ✅ 중앙 DI 파일 임포트

// ============================================================================
// [상태 관리 Notifier]
// 화면에서 '저장' 버튼을 눌렀을 때 API 호출 및 로딩/에러 상태를 관리합니다.
// ============================================================================

class TodoAddNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // 초기 상태는 아무 작업도 하지 않은 상태
  }

  /// 새로운 할 일을 서버에 생성하도록 요청합니다.
  ///
  /// 성공 시 [TodoViewModel] 의 목록과 캘린더 데이터를 함께 갱신해서
  /// 호출자(시트)의 lifecycle / context.mounted 와 무관하게 홈/투두 양쪽이
  /// 동일한 최신 상태를 보게 한다.
  Future<void> createTodo(Todo newTodo) async {
    // 1. 로딩 상태로 변경 (UI에서 로딩 스피너를 보여줄 수 있음)
    state = const AsyncValue.loading();

    // 2. API 호출 및 예외 처리 자동화 (guard)
    state = await AsyncValue.guard(() async {
      final repository = ref.read(todoRepositoryProvider);

      // 서버로 데이터 전송
      await repository.createTodo(newTodo);

      // ✅ 성공 후 즉시 갱신 — 홈(다마고치) / 투두 페이지 양쪽이 같은
      //    todoViewModelProvider 를 watch 하고 있으므로 한 번만 갱신해도
      //    두 화면 모두 최신 상태로 리빌드된다.
      final vm = ref.read(todoViewModelProvider.notifier);
      await vm.fetchTodos();
      await vm.fetchCalendarData();
    });
  }
}

// UI에서 접근하기 위한 Provider
final todoAddNotifierProvider = AsyncNotifierProvider<TodoAddNotifier, void>(
      () => TodoAddNotifier(),
);