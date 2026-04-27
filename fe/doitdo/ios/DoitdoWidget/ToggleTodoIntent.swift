//
//  ToggleTodoIntent.swift
//  DoitdoWidget
//
//  iOS 17+ 인터랙티브 위젯의 핵심. 위젯 내 Button(intent:) 이 trigger 되면 OS 가
//  본 Intent 를 별도 extension 프로세스에서 실행 — 앱을 안 열고도 PATCH 호출 가능.
//
//  완료 토글 시 UX (optimistic update):
//    1) payload 의 isDone 을 즉시 뒤집어 저장 + reloadTimelines (단 1회)
//    2) `perform()` 즉시 return → OS 가 새 timeline 을 빠르게 그릴 수 있게 함
//    3) 백엔드 PATCH 는 detached Task 로 fire-and-forget — extension 종료 직전까지 살아있음
//    4) TimelineProvider.getTimeline 이 두 entry 를 만들어 strikethrough → 사라짐 transition 처리
//
//  왜 await 하지 않는가:
//    AppIntent.perform() 안에서 try await PATCH 를 하면 perform() 이 PATCH 응답까지(보통 200~1000ms)
//    살아있고, OS 는 perform() 종료 후에야 timeline 을 다시 fetch 한다. 결과적으로 사용자는
//    PATCH 가 끝날 때까지 위젯에서 아무 변화도 못 본다.
//    fire-and-forget 으로 perform() 을 ~수 ms 안에 종료하면 위젯 반응이 즉각적이 된다.
//    PATCH 실패 시엔 다음 앱 sync / 위젯 timeline refresh 에서 정합성이 회복된다.
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

        // 1. payload 의 isDone 만 뒤집어 저장 — TimelineProvider 가 transition 을 만든다.
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
        // updatedAt 을 현재 시각으로 갱신 — TimelineProvider 가 "최근 토글" 로 인지해
        // SharedStore cleanup 을 윈도우 동안 보류 → 두 번 호출되어도 동일 transition 보장.
        let nowISO: String = {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return f.string(from: Date())
        }()
        SharedStore.savePayload(
            WidgetPayload(
                todayTodos: updatedToday,
                somedayTodos: updatedSomeday,
                updatedAt: nowISO
            )
        )

        // 2. 단 1회 reload — getTimeline 이 미래 entry 까지 만들어 자연 transition 발생
        WidgetCenter.shared.reloadTimelines(ofKind: "DoitdoWidget")

        // 3. 백엔드 PATCH 를 detached Task 로 fire-and-forget.
        //    perform() 종료 후에도 extension 프로세스가 짧은 grace period 동안 살아있어
        //    PATCH 한 번 끝낼 시간은 보통 확보된다. 실패 시엔 다음 sync 에서 정합성 회복.
        let capturedTodoId = todoId
        Task.detached(priority: .userInitiated) {
            do {
                try await WidgetApiClient.changeTodoStatus(todoId: capturedTodoId, newStatus: nextStatus)
            } catch {
                // no-op — 위젯 extension 은 사용자에게 알릴 수단이 없다.
            }
        }

        // 4. perform() 즉시 종료 — OS 가 timeline 을 빠르게 다시 그릴 수 있도록.
        return .result()
    }
}
