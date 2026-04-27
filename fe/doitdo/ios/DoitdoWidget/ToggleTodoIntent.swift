//
//  ToggleTodoIntent.swift
//  DoitdoWidget
//
//  iOS 17+ 인터랙티브 위젯의 핵심. 위젯 내 Button(intent:) 이 trigger 되면 OS 가
//  본 Intent 를 별도 extension 프로세스에서 실행 — 앱을 안 열고도 PATCH 호출 가능.
//
//  완료 토글 시 UX:
//    1) payload 의 isDone 을 뒤집어 저장 + reloadTimelines (단 1회)
//    2) TimelineProvider.getTimeline 이 두 entry 를 만들어 시간 transition 처리:
//         entry 1 (now): isDone=true → "주황 채움 + 취소선" 노출
//         entry 2 (now+0.45초): 해당 항목 제거된 payload → 부드럽게 사라짐
//       (이 방식은 AppIntent 안에서 reload 를 여러 번 호출하다 OS throttling 으로
//        첫 reload 가 무시되는 케이스를 근본 차단한다.)
//    3) 백엔드 PATCH 호출 — 다음 timeline / 앱 sync 에서 정합성 회복.
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
        guard let payload = SharedStore.payload() else {
            return .result()
        }
        let allTodos = payload.todayTodos + payload.somedayTodos
        guard let target = allTodos.first(where: { $0.id == todoId }) else {
            return .result()
        }
        let willBeDone = !target.isDone
        let nextStatus = willBeDone ? "DONE" : "TODO"

        // payload 에서 해당 항목의 isDone 만 뒤집어 저장.
        // TimelineProvider.getTimeline 이 이 변화를 감지해 두 entry 로 transition 시킨다.
        let updatedToday = payload.todayTodos.map {
            $0.id == todoId
                ? WidgetTodo(id: $0.id, title: $0.title, isDone: willBeDone, isSomeday: $0.isSomeday)
                : $0
        }
        let updatedSomeday = payload.somedayTodos.map {
            $0.id == todoId
                ? WidgetTodo(id: $0.id, title: $0.title, isDone: willBeDone, isSomeday: $0.isSomeday)
                : $0
        }
        SharedStore.savePayload(
            WidgetPayload(
                todayTodos: updatedToday,
                somedayTodos: updatedSomeday,
                updatedAt: payload.updatedAt
            )
        )

        // 단 1회 reload — getTimeline 이 미래 entry 까지 만들어 자연 transition 발생
        WidgetCenter.shared.reloadTimelines(ofKind: "DoitdoWidget")

        // 백엔드 PATCH (실패해도 다음 sync 에서 회복)
        do {
            try await WidgetApiClient.changeTodoStatus(todoId: todoId, newStatus: nextStatus)
        } catch {
            // no-op
        }

        return .result()
    }
}
