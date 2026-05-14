/// `POST /api/characters/me/actions/{actionType}` 응답(envelope 내부 `data`).
///
/// ```json
/// {
///   "actionUrl": "https://.../characters/duck/actions/teen/eye.gif",
///   "earnedAmount": 5,
///   "balanceAfter": 120
/// }
/// ```
///
/// 평소(미터치) 상태는 `Character.thumbnailUrl` (정적 png) 을 그대로 보여주고,
/// 캐릭터를 탭하면 이 응답의 [actionUrl] 로 잠시 swap 해 동작 gif 를 재생한다.
///
/// 하루 N회까지 코인 보상이 지급되며, 한도를 넘기면 BE 가 [earnedAmount] = 0
/// 으로 내려준다. 호출자는 그 경우 floating "+N" 시각화를 띄우지 않는다.
class CharacterActionDto {
  const CharacterActionDto({
    required this.actionUrl,
    required this.earnedAmount,
    required this.balanceAfter,
  });

  final String actionUrl;

  /// 이번 탭으로 지급된 코인량. 0 이면 한도 초과 또는 미지급.
  final int earnedAmount;

  /// 지급 후 사용자의 코인 잔액.
  final int balanceAfter;

  factory CharacterActionDto.fromJson(Map<String, dynamic> json) =>
      CharacterActionDto(
        actionUrl: (json['actionUrl'] as String?) ?? '',
        earnedAmount: (json['earnedAmount'] as num?)?.toInt() ?? 0,
        balanceAfter: (json['balanceAfter'] as num?)?.toInt() ?? 0,
      );
}
