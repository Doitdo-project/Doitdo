class TodoStatusResponseDto {
  const TodoStatusResponseDto({
    required this.todoId,
    required this.status,
    required this.changedAt,
  });

  final int todoId;
  final String status;
  final String changedAt;

  factory TodoStatusResponseDto.fromJson(Map<String, dynamic> json) {
    return TodoStatusResponseDto(
      todoId: json['todoId'] as int,
      status: json['status'] as String,
      // 명세서 표에는 updatedAt, 예시에는 changedAt 혼용되어 있으므로 안전하게 둘 다 체크
      changedAt: (json['changedAt'] ?? json['updatedAt'] ?? '') as String,
    );
  }
}