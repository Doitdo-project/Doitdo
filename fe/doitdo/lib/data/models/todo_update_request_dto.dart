import 'package:freezed_annotation/freezed_annotation.dart';

part 'todo_update_request_dto.freezed.dart';
part 'todo_update_request_dto.g.dart';

@freezed
class TodoUpdateRequestDto with _$TodoUpdateRequestDto {
  const factory TodoUpdateRequestDto({
    required String title,
    String? content,
    // 서버는 카테고리 이름(String)이 아닌 categoryId(int)를 요구 — T04-005 방지.
    // null 이면 JSON 에서 생략 → 서버 기존 카테고리 유지.
    @JsonKey(name: 'categoryId', includeIfNull: false) int? categoryId,
    required String type, // NORMAL, RECURRING, PERIOD
    // null 이면 JSON 에서 통째로 생략. BE 정책 (RECURRING 수정 시):
    //   - body 에 startDate key 없음 → 기존 startDate 유지 + 요일 검증 안 함
    //   - body 에 startDate 값 있음 → 검증 (T14-002) + 갱신
    // FE 는 사용자가 startDate 를 명시적으로 안 바꿨을 때 null 로 채워 보낸다.
    @JsonKey(includeIfNull: false) required String? startDate, // YYYY-MM-DD
    String? endDate, // YYYY-MM-DD 형식
    @JsonKey(includeIfNull: false) Set<String>? daysOfWeek,
    @JsonKey(name: 'alertTime') String? alarmTime,
    @JsonKey(name: 'clearAlertTime', includeIfNull: false)
    bool? clearAlertTime, // ✏️ true면 서버에서 alertTime null로 초기화. null이면 JSON에 포함 안 함
  }) = _TodoUpdateRequestDto;

  factory TodoUpdateRequestDto.fromJson(Map<String, dynamic> json) =>
      _$TodoUpdateRequestDtoFromJson(json);
}