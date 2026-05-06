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
  /// POST 응답에 포함된 생성된 TODO 객체를 [TodoViewModel.insertCreatedTodo] 로
  /// 목록에 즉시 prepend 한다. 이를 통해 후속 GET /api/todos 재호출 없이
  /// 홈/투두 양쪽 화면이 최신 상태를 반영한다.
  Future<void> createTodo(Todo newTodo) async {
    // 1. 로딩 상태로 변경 (UI에서 로딩 스피너를 보여줄 수 있음)
    state = const AsyncValue.loading();

    // 2. API 호출 및 예외 처리 자동화 (guard)
    state = await AsyncValue.guard(() async {
      final repository = ref.read(todoRepositoryProvider);

      // POST 응답으로 서버가 반환한 생성된 TODO DTO 를 받아서
      // fetchTodos 없이 목록에 직접 삽입한다 (옵티미스틱 prepend).
      final created = await repository.createTodo(newTodo);

      // ✅ 성공 후 즉시 삽입 — 홈(다마고치) / 투두 페이지 양쪽이 같은
      //    todoViewModelProvider 를 watch 하고 있으므로 한 번만 갱신해도
      //    두 화면 모두 최신 상태로 리빌드된다. SOMEDAY/일반 타입 분기는
      //    insertCreatedTodo 내부에서 처리한다.
      ref.read(todoViewModelProvider.notifier).insertCreatedTodo(created);
    });
  }
}

// UI에서 접근하기 위한 Provider
final todoAddNotifierProvider = AsyncNotifierProvider<TodoAddNotifier, void>(
      () => TodoAddNotifier(),
);