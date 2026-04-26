//
//  SharedStore.swift
//  DoitdoWidget
//
//  Flutter 앱과 위젯 extension 간 데이터 공유 추상화.
//  Flutter 의 `home_widget` 패키지가 사용하는 App Group UserDefaults 키와 정확히 일치해야 한다.
//  → Dart 측 `WidgetSyncService` 의 상수와 1:1 매핑 (변경 시 양쪽 동기화 필수).
//

import Foundation

enum SharedStore {
    /// Flutter `WidgetSyncService` 의 `_iOSAppGroupId` 와 일치해야 한다.
    static let appGroupId = "group.com.d107.doitdo"

    /// Dart `WidgetSyncService` 의 `_keyXxx` 상수와 1:1 일치.
    enum Key {
        static let payload = "doitdo.widget.payload"
        static let accessToken = "doitdo.widget.accessToken"
        static let refreshToken = "doitdo.widget.refreshToken"
        static let apiBaseUrl = "doitdo.widget.apiBaseUrl"
    }

    /// home_widget 패키지(0.7.x)는 native 측에서 키를 그대로(`preferences.setValue(data, forKey: id)`)
    /// App Group UserDefaults 에 저장한다 — prefix 없음.
    /// 따라서 위젯에서도 동일한 raw key 로 읽으면 된다.
    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    static func string(forKey key: String) -> String? {
        let value = defaults?.string(forKey: key)
        return (value?.isEmpty == true) ? nil : value
    }

    static func payload() -> WidgetPayload? {
        guard let raw = string(forKey: Key.payload),
              let data = raw.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(WidgetPayload.self, from: data)
    }

    static func savePayload(_ payload: WidgetPayload) {
        guard let data = try? JSONEncoder().encode(payload),
              let json = String(data: data, encoding: .utf8) else { return }
        defaults?.set(json, forKey: Key.payload)
    }

    static func accessToken() -> String? { string(forKey: Key.accessToken) }
    static func refreshToken() -> String? { string(forKey: Key.refreshToken) }
    static func apiBaseUrl() -> String? { string(forKey: Key.apiBaseUrl) }

    static func updateAccessToken(_ token: String) {
        defaults?.set(token, forKey: Key.accessToken)
    }
    static func updateRefreshToken(_ token: String) {
        defaults?.set(token, forKey: Key.refreshToken)
    }
}
