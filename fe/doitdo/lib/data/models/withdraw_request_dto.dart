/// `DELETE /api/users/me` 요청 본문.
///
/// 일반 계정(이메일+비번) 은 `currentPassword` 필수.
/// OAuth 계정(Google/Kakao) 은 생략 가능 (null 보내면 됨).
///
/// 서버는 `currentPassword` 가 string 타입을 기대하므로 null 인 경우 직렬화에서
/// 키 자체를 제외해 전송한다 (빈 문자열 보내면 검증 통과 여부가 모호함).
class WithdrawRequestDto {
  const WithdrawRequestDto({this.currentPassword});

  final String? currentPassword;

  Map<String, dynamic> toJson() => {
        if (currentPassword != null) 'currentPassword': currentPassword,
      };
}
