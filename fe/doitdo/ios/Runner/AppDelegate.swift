import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 명시적으로 UNUserNotificationCenter delegate 를 자기 자신으로 설정.
    // FlutterAppDelegate 가 이미 UNUserNotificationCenterDelegate 를 구현하고 있고
    // firebase_messaging 의 swizzling 이 대부분 처리하지만, 일부 환경에서
    // delegate 가 비어있어 포어그라운드 알림 콜백이 누락되는 케이스가 있어 안전망 차원에서 명시.
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    // APNs 등록을 명시적으로 트리거.
    // Firebase swizzling 이 자동으로 처리하지만, 첫 설치/첫 로그인 직후
    // APNs 토큰 도착이 늦어지는 케이스를 줄이기 위해 launch 시점에 한 번 더 호출.
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
