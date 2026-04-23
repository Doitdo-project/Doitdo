import 'package:doitdo/presentation/models/todo.dart';

abstract class TodoRepository {
  Future<void> createTodo(Todo todo);

  // ✅ 상태 변경 기능 추가
  Future<void> updateTodoStatus(String todoId, String status);
}