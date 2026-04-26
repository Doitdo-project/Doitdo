//
//  ToggleTodoIntent.swift
//  DoitdoWidget
//
//  iOS 17+ 인터랙티브 위젯의 핵심. 위젯 내 Button(intent:) 이 trigger 되면 OS 가
//  본 Intent 를 별도 extension 프로세스에서 실행 — 앱을 안 열고도 PATCH 호출 가능.
//
//  성공 시 App Group 의 payload JSON 을 즉시 갱신하고 WidgetCenter 로 timeline reload.
//  실패 시 위젯 UI 는 변경 없이 다음 갱신 때까지 그대로 (사용자가 다시 탭).
//

import AppIntents
import WidgetKit

@available(iOS 17.0, *)
struct ToggleTodoIntent: AppIntent {
    static var title: LocalizedStringResource = "TODO 토글"
    static var description = IntentDescription("위젯에서 TODO 의 완료 상태를 전환")

    /// 위젯이 외형상 즉시 변하지 않도록(=갱신 후 다시 그리도록) false.
    static var openAppWhenRun: Bool = false

    @Parameter(title: "TODO ID")
    var todoId: Int

    init() {}
    init(todoId: Int) { self.todoId = todoId }

    func perform() async throws -> some IntentResult {
        // 1. 현재 payload 에서 해당 TODO 의 status 반대값 결정
        guard let payload = SharedStore.payload() else {
            return .result()
        }
        let allTodos = payload.todayTodos + payload.somedayTodos
        guard let target = allTodos.first(where: { $0.id == todoId }) else {
            return .result()
        }
        let nextStatus = target.isDone ? "TODO" : "DONE"

        // 2. 백엔드 PATCH (실패해도 throw 하지 않고 조용히 무시 — 다음 갱신에서 sync)
        do {
            try await WidgetApiClient.changeTodoStatus(todoId: todoId, newStatus: nextStatus)
        } catch {
            // 디버그용 로그만 남김 — 위젯 extension 은 사용자에게 토스트를 띄울 수단이 없다.
            // 다음 timeline 새로고침 또는 앱 진입 시 정합성 회복.
            return .result()
        }

        // 3. App Group 의 payload 도 즉시 반영 → 위젯이 reload 되면 새 상태 표시
        let updatedToday = payload.todayTodos.map {
            $0.id == todoId
                ? WidgetTodo(id: $0.id, title: $0.title, isDone: !target.isDone, isSomeday: $0.isSomeday)
                : $0
        }
        let updatedSomeday = payload.somedayTodos.map {
            $0.id == todoId
                ? WidgetTodo(id: $0.id, title: $0.title, isDone: !target.isDone, isSomeday: $0.isSomeday)
                : $0
        }
        SharedStore.savePayload(
            WidgetPayload(
                todayTodos: updatedToday,
                somedayTodos: updatedSomeday,
                updatedAt: payload.updatedAt
            )
        )

        // 4. 위젯 timeline 재생성
        WidgetCenter.shared.reloadTimelines(ofKind: "DoitdoWidget")
        return .result()
    }
}
