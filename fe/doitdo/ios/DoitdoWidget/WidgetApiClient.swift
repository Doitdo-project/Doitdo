//
//  WidgetApiClient.swift
//  DoitdoWidget
//
//  위젯 백그라운드 컨텍스트(AppIntent)에서 doitdo 백엔드를 직접 호출.
//  앱 측 Dio AuthInterceptor 와 동등한 401 → refresh → retry 1회 동작을 단순화해서 구현.
//
//  Dart 측 Dio 와는 다음 두 가지가 다름:
//  - 위젯은 백그라운드라 사용자 알림 없이 조용히 실패 가능 → 실패 시 false 반환만
//  - 위젯이 갖는 토큰은 App Group UserDefaults 에 저장된 것 (마지막 앱 동기화 시점값)
//

import Foundation

enum WidgetApiError: Error {
    case noTokens
    case noBaseUrl
    case unauthorized       // refresh 까지 실패
    case server(Int)        // 4xx/5xx
    case network(Error)
    case decode
}

enum WidgetApiClient {
    /// PATCH /api/todos/{todoId}/status
    /// - Parameter newStatus: "DONE" / "TODO" 등 백엔드 enum 값
    /// - Throws: WidgetApiError
    static func changeTodoStatus(todoId: Int, newStatus: String) async throws {
        guard let baseUrl = SharedStore.apiBaseUrl(), !baseUrl.isEmpty else {
            throw WidgetApiError.noBaseUrl
        }
        guard let access = SharedStore.accessToken(), !access.isEmpty else {
            throw WidgetApiError.noTokens
        }

        let url = URL(string: baseUrl + "/api/todos/\(todoId)/status")!
        let body = try JSONSerialization.data(withJSONObject: ["status": newStatus])

        do {
            try await patch(url: url, body: body, accessToken: access)
        } catch WidgetApiError.unauthorized {
            // 401 → refresh 1회 시도 → 재호출
            let refreshed = try await refreshAccessToken()
            try await patch(url: url, body: body, accessToken: refreshed)
        }
    }

    private static func patch(url: URL, body: Data, accessToken: String) async throws {
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.httpBody = body
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (_, resp): (Data, URLResponse)
        do {
            (_, resp) = try await URLSession.shared.data(for: req)
        } catch {
            throw WidgetApiError.network(error)
        }
        guard let http = resp as? HTTPURLResponse else { throw WidgetApiError.decode }
        switch http.statusCode {
        case 200..<300: return
        case 401:       throw WidgetApiError.unauthorized
        default:        throw WidgetApiError.server(http.statusCode)
        }
    }

    /// POST /api/auth/refresh
    /// 성공 시 새 access/refresh 를 App Group 에도 갱신 저장하고 access 반환.
    private static func refreshAccessToken() async throws -> String {
        guard let baseUrl = SharedStore.apiBaseUrl(), !baseUrl.isEmpty else {
            throw WidgetApiError.noBaseUrl
        }
        guard let refresh = SharedStore.refreshToken(), !refresh.isEmpty else {
            throw WidgetApiError.unauthorized
        }
        let url = URL(string: baseUrl + "/api/auth/refresh")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["refreshToken": refresh])

        let (data, resp): (Data, URLResponse)
        do {
            (data, resp) = try await URLSession.shared.data(for: req)
        } catch {
            throw WidgetApiError.network(error)
        }
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw WidgetApiError.unauthorized
        }
        // envelope.data = { accessToken, refreshToken }
        struct TokenPair: Decodable {
            let accessToken: String
            let refreshToken: String
        }
        do {
            let envelope = try JSONDecoder().decode(ApiEnvelope<TokenPair>.self, from: data)
            guard let pair = envelope.data else { throw WidgetApiError.decode }
            SharedStore.updateAccessToken(pair.accessToken)
            SharedStore.updateRefreshToken(pair.refreshToken)
            return pair.accessToken
        } catch {
            throw WidgetApiError.decode
        }
    }
}
