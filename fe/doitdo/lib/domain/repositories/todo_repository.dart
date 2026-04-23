import 'package:doitdo/presentation/models/todo.dart';

abstract class TodoRepository {
  Future<void> createTodo(Todo todo);
}