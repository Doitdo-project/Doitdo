/// 백엔드 공통 응답 envelope.
///
/// 모든 REST 응답은 아래 스키마를 따른다:
/// ```json
/// {
///   "status": 200,
///   "message": "OK",
///   "data": { ... }
/// }
/// ```
///
/// - Retrofit 인터페이스는 `Future<ApiResponse<XxxDto>>` 를 반환하도록 선언한다.
/// - Repository 에서는 [BaseRepository.safeApiCall] 이 envelope 을 벗겨 [data] 만
///   도메인으로 올려 보내고, 실패(status != 2xx) 시 `ServerException` 으로 throw
///   한다. 따라서 ViewModel 레이어는 envelope 을 몰라도 된다.
///
/// generic fromJson 시그니처는 retrofit_generator 가 요구하는 형태 그대로이다.
class ApiResponse<T> {
  const ApiResponse({
    required this.status,
    required this.message,
    this.code,
    this.data,
  });

  /// HTTP status mirror. 보통 200/201 이 성공, 4xx/5xx 가 실패.
  final int status;

  /// 서버 정의 에러/성공 코드 문자열. 스펙상 envelope 에 함께 내려오며
  /// 화면별 예외 분기(예: "EMAIL_ALREADY_EXISTS") 에 쓰일 수 있어 보존.
  /// 현재 UI 에선 사용하지 않지만, 스펙 일치 + 향후 확장 대비.
  final String? code;

  /// 사람이 읽는 메시지. 실패 시 토스트/다이얼로그에 노출해도 되는 문구.
  final String message;

  /// 실제 응답 페이로드. 엔드포인트에 따라 null 일 수 있다(e.g. 삭제 API).
  final T? data;

  bool get isSuccess => status >= 200 && status < 300;

  /// retrofit_generator 가 generic response 에 대해 호출하는 형태.
  /// [fromJsonT] 는 `data` 필드를 T 로 변환하는 함수이며, retrofit 이
  /// `XxxDto.fromJson` 을 자동으로 꽂아준다.
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    final rawData = json['data'];
    return ApiResponse<T>(
      status: json['status'] as int,
      code: json['code'] as String?,
      message: (json['message'] as String?) ?? '',
      data: rawData == null ? null : fromJsonT(rawData),
    );
  }
}