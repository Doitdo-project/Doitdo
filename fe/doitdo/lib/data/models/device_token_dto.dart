/// FCM 디바이스 토큰 관련 DTO.
///
/// Swagger 스펙:
/// - POST   /api/notifications/device-token → [DeviceTokenRegisterReq] / [DeviceTokenResp]
/// - DELETE /api/notifications/device-token → [DeviceTokenUnregisterReq]
///
/// `platform` 은 서버 enum 과 동일하게 `ANDROID` / `IOS` 로만 전송한다.

enum DeviceTokenPlatform {
  android,
  ios;

  /// 서버 enum 표현. 대문자 그대로 전송해야 400 이 안 뜬다.
  String get apiValue => switch (this) {
        DeviceTokenPlatform.android => 'ANDROID',
        DeviceTokenPlatform.ios => 'IOS',
      };

  static DeviceTokenPlatform fromApi(String raw) => switch (raw) {
        'ANDROID' => DeviceTokenPlatform.android,
        'IOS' => DeviceTokenPlatform.ios,
        _ => DeviceTokenPlatform.android,
      };
}

class DeviceTokenRegisterReq {
  const DeviceTokenRegisterReq({
    required this.fcmToken,
    required this.platform,
  });

  final String fcmToken;
  final DeviceTokenPlatform platform;

  Map<String, dynamic> toJson() => {
        'fcmToken': fcmToken,
        'platform': platform.apiValue,
      };
}

class DeviceTokenUnregisterReq {
  const DeviceTokenUnregisterReq({required this.fcmToken});

  final String fcmToken;

  Map<String, dynamic> toJson() => {'fcmToken': fcmToken};
}

class DeviceTokenResp {
  const DeviceTokenResp({
    required this.deviceTokenId,
    required this.fcmToken,
    required this.platform,
    required this.isActive,
  });

  final int deviceTokenId;
  final String fcmToken;
  final DeviceTokenPlatform platform;
  final bool isActive;

  factory DeviceTokenResp.fromJson(Map<String, dynamic> json) =>
      DeviceTokenResp(
        deviceTokenId: (json['deviceTokenId'] as num).toInt(),
        fcmToken: json['fcmToken'] as String,
        platform: DeviceTokenPlatform.fromApi(json['platform'] as String),
        isActive: json['isActive'] as bool,
      );
}
