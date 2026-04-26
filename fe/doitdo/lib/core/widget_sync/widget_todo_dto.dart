/// 홈스크린 위젯이 표시할 TODO 1 건의 최소 정보.
///
/// 위젯의 좁은 화면에 들어갈 정보만 추림 — 메모/카테고리 색상/알람 등은 위젯에는 불필요.
/// 위젯 → 앱 전환 시 풀 데이터는 앱이 다시 조회한다.
///
/// JSON 키 이름은 네이티브(Swift Codable / Kotlin) 에서도 동일하게 디코드한다 — 변경 시 양쪽 동기화 필수.
class WidgetTodoDto {
  const WidgetTodoDto({
    required this.id,
    required this.title,
    required this.isDone,
    required this.isSomeday,
  });

  /// 서버 PK. 위젯에서 토글 PATCH 호출 시 path param 으로 사용.
  final int id;

  final String title;

  /// `status == DONE` 이면 true. 위젯 체크박스 채움 + 텍스트 취소선 트리거.
  final bool isDone;

  /// SOMEDAY 타입 여부. 위젯에서 "오늘" 섹션 vs "나중에" 섹션을 분리할 때 사용.
  final bool isSomeday;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isDone': isDone,
        'isSomeday': isSomeday,
      };

  factory WidgetTodoDto.fromJson(Map<String, dynamic> json) => WidgetTodoDto(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String,
        isDone: json['isDone'] as bool,
        isSomeday: json['isSomeday'] as bool,
      );
}

/// 위젯에 보내는 페이로드 전체.
///
/// 오늘 + SOMEDAY 두 섹션 + 마지막 갱신 시각(위젯이 "방금 전" 표시용).
class WidgetPayload {
  const WidgetPayload({
    required this.todayTodos,
    required this.somedayTodos,
    required this.updatedAt,
  });

  final List<WidgetTodoDto> todayTodos;
  final List<WidgetTodoDto> somedayTodos;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'todayTodos': todayTodos.map((t) => t.toJson()).toList(),
        'somedayTodos': somedayTodos.map((t) => t.toJson()).toList(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
