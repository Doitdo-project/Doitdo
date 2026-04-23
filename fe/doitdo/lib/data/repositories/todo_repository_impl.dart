import 'package:doitdo/core/network/base_repository.dart';
import 'package:doitdo/data/datasources/todo_api.dart';
import 'package:doitdo/domain/repositories/todo_repository.dart';
import 'package:doitdo/presentation/models/todo.dart';

class TodoRepositoryImpl extends BaseRepository implements TodoRepository {
  TodoRepositoryImpl(this._todoApi);

  final TodoApi _todoApi;

  @override
  Future<void> createTodo(Todo todo) async {
    // 1. 날짜 포맷팅 (YYYY-MM-DD)
    final startDateStr = todo.date?.toIso8601String().split('T')[0] ??
        DateTime.now().toIso8601String().split('T')[0];
    final endDateStr = todo.rangeEnd?.toIso8601String().split('T')[0] ??
        todo.repeatEndDate?.toIso8601String().split('T')[0];

    // 2. 반복 주기(period) 계산 (일 단위)
    int? periodDays;
    if (todo.dateType == TodoDateType.repeat) {
      if (todo.repeatType == '매주') periodDays = 7;
      else if (todo.repeatType == '매월') periodDays = 30; // 백엔드와 월 단위 처리 협의 필요할 수 있음
      else if (todo.repeatType == '매년') periodDays = 365;
    }

    // 3. API 명세서(T06)에 맞춘 Request Body 생성
    final body = {
      'title': todo.title,
      'content': todo.memo, // 우리 UI의 memo를 content로 전송
      'category': todo.category.name,
      'type': todo.dateType.name.toUpperCase(), // NORMAL, PERIOD, RECURRING(repeat)
      'startDate': startDateStr,
      if (endDateStr != null) 'endDate': endDateStr,
      if (periodDays != null) 'period': periodDays,
    };

    // ✅ 가이드라인 적용: 응답 데이터(Data)가 없는 API이므로 safeApiCallNoData 사용
    await safeApiCallNoData(() => _todoApi.createTodo(body));
  }
}