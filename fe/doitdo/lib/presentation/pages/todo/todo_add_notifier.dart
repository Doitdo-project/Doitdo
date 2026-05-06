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
  /// [localId] 는 시트에서 낙관적으로 삽입한 Todo 의 임시 ID.
  /// 성공 시 서버 응답으로 교체, 실패 시 제거하고 에러 상태로 전환.
  Future<void> createTodo(Todo newTodo, String localId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final created = await ref.read(todoRepositoryProvider).createTodo(newTodo);
      ref.read(todoViewModelProvider.notifier).replaceLocalTodo(localId, created);
    });
    if (state.hasError) {
      ref.read(todoViewModelProvider.notifier).removeLocalTodo(localId);
    }
  }
}

// UI에서 접근하기 위한 Provider
final todoAddNotifierProvider = AsyncNotifierProvider<TodoAddNotifier, void>(
      () => TodoAddNotifier(),
);