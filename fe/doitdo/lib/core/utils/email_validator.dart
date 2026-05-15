/// 이메일 형식 검증 — 서버 검증이 없는 환경에서 클라가 마지막 방어선이라
/// RFC 5321 의 실용적 부분집합으로 좀 엄격하게 검사한다.
///
/// 거르는 비정상 케이스:
/// - 로컬 파트 시작/끝 점 (`.user@x`, `user.@x`)
/// - 로컬 파트 연속 점 (`us..er@x`)
/// - 도메인 라벨이 영숫자가 아닌 것으로 시작/끝 (`-example.com`, `example-.com`)
/// - 도메인 라벨 사이 연속 점 (`a..b.com`)
/// - 도메인에 언더스코어 (`user@my_domain.com`)
/// - TLD 1글자 (`x.y`)
/// - 전체 길이 254자 초과 (RFC 5321 제한)
///
/// 정상 케이스: 일반 이메일 + 점/언더스코어/플러스/하이픈/퍼센트 등 흔히 쓰는 특수문자
/// (`user.name+tag@sub.example.co.kr` 등).
final _emailRegex = RegExp(
  r'^[a-zA-Z0-9_%+-]+(?:\.[a-zA-Z0-9_%+-]+)*'
  r'@[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?'
  r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?)*'
  r'\.[a-zA-Z]{2,}$',
);

/// 클라이언트 측 이메일 유효성 검사. true 면 형식상 정상 이메일.
bool isValidEmail(String email) {
  if (email.isEmpty || email.length > 254) return false;
  return _emailRegex.hasMatch(email);
}
