import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doitdo/data/models/todo_detail_response_dto.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';

// 전달받은 ID를 가지고 서버에서 상세 정보를 가져오는 FutureProvider
final todoDetailProvider = FutureProvider.autoDispose.family<TodoDetailResponseDto, String>((ref, id) async {
  final repository = ref.read(todoRepositoryProvider);
  return await repository.getTodoDetail(id);
});