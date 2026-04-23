import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/presentation/models/todo.dart';
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
  Future<void> createTodo(Todo newTodo) async {
    // 1. 로딩 상태로 변경 (UI에서 로딩 스피너를 보여줄 수 있음)
    state = const AsyncValue.loading();

    // 2. API 호출 및 예외 처리 자동화 (guard)
    state = await AsyncValue.guard(() async {
      // ✅ 중앙에 등록된 '진짜' 통신 Provider 호출!
      final repository = ref.read(todoRepositoryProvider);

      // 서버로 데이터 전송
      await repository.createTodo(newTodo);

      // TODO: 성공적으로 저장된 후, 메인 캘린더 화면의 목록을 갱신하는 로직이 필요합니다.
      // 예: ref.read(todoViewModelProvider.notifier).fetchTodos();
    });
  }
}

// UI에서 접근하기 위한 Provider
final todoAddNotifierProvider = AsyncNotifierProvider<TodoAddNotifier, void>(
      () => TodoAddNotifier(),
);