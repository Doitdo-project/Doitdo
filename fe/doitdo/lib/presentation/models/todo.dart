import 'package:flutter/foundation.dart';

/// 할 일 / 카테고리 표시용 경량 모델.
///
/// 도메인 엔티티가 확정되기 전까지 프레젠테이션 레이어에서 사용하는
/// 임시 모델이다. API 연동 시점에 `domain/entities/todo.dart` 의
/// 실제 엔티티로 교체하거나 매핑하도록 한다.

@immutable
class Todo {
  const Todo({
    required this.id,
    required this.title,
    required this.category,
    required this.isDone,
  });

  final String id;
  final String title;
  final TodoCategory category;
  final bool isDone;

  Todo copyWith({bool? isDone}) => Todo(
        id: id,
        title: title,
        category: category,
        isDone: isDone ?? this.isDone,
      );
}

/// 카테고리 뱃지에 필요한 최소 정보.
/// 실제 색상은 위젯 레이어에서 `colorKey` 로 매핑한다.
@immutable
class TodoCategory {
  const TodoCategory({required this.name, required this.colorKey});

  final String name;
  final CategoryColorKey colorKey;
}

enum CategoryColorKey { health, study, work, hobby, etc }