/// `GET /api/characters/me/actions/{actionType}` 응답(envelope 내부 `data`).
///
/// ```json
/// {
///   "actionUrl": "https://.../characters/duck/actions/teen/eye.gif"
/// }
/// ```
///
/// 평소(미터치) 상태는 `Character.thumbnailUrl` (정적 png) 을 그대로 보여주고,
/// 캐릭터를 탭하면 이 응답의 [actionUrl] 로 잠시 swap 해 동작 gif 를 재생한다.
class CharacterActionDto {
  const CharacterActionDto({required this.actionUrl});

  final String actionUrl;

  factory CharacterActionDto.fromJson(Map<String, dynamic> json) {
    return CharacterActionDto(
      actionUrl: (json['actionUrl'] as String?) ?? '',
    );
  }
}
