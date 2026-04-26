//
//  WidgetTodo.swift
//  DoitdoWidget
//
//  Dart `WidgetTodoDto` / `WidgetPayload` 와 1:1 동일한 JSON 키 — 동기화 필수.
//

import Foundation

struct WidgetTodo: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let isDone: Bool
    let isSomeday: Bool
}

struct WidgetPayload: Codable {
    let todayTodos: [WidgetTodo]
    let somedayTodos: [WidgetTodo]
    let updatedAt: String  // ISO8601 — 위젯에서 직접 표시하지 않으므로 String 그대로
}

/// 백엔드 응답 envelope (`{status, code, data, message}`).
/// 우리 PATCH /api/todos/{id}/status 응답의 data 는 TodoDetailResp 형식이지만
/// 위젯은 `status` 필드만 알면 충분 — 모든 필드를 디코드하지 않고 dynamic 처리.
struct ApiEnvelope<T: Decodable>: Decodable {
    let status: Int
    let code: String?
    let data: T?
    let message: String?
}
