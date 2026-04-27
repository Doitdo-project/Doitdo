/// `POST /api/users/me/agreements` 요청 바디 (온보딩 2단계).
///
/// 스웨거 스펙(`RegisterAgreementsReq`):
/// - `termsAgreed`     (bool, required) — 이용약관 동의. 필수 (반드시 true 로 보내야 함).
/// - `privacyAgreed`   (bool, required) — 개인정보 처리방침 동의. 필수 (반드시 true).
/// - `marketingAgreed` (bool, required) — 마케팅 알림 수신 동의. 선택 (true/false 모두 허용).
///
/// 호출측에서 termsAgreed, privacyAgreed 가 false 면 서버로 보내기 전에 막아야 한다 —
/// 현재 ViewModel 의 검증 로직이 그 역할을 한다.
class RegisterAgreementsRequestDto {
  const RegisterAgreementsRequestDto({
    required this.termsAgreed,
    required this.privacyAgreed,
    required this.marketingAgreed,
  });

  final bool termsAgreed;
  final bool privacyAgreed;
  final bool marketingAgreed;

  Map<String, dynamic> toJson() => {
        'termsAgreed': termsAgreed,
        'privacyAgreed': privacyAgreed,
        'marketingAgreed': marketingAgreed,
      };
}
