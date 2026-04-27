//
//  DoitdoWidget.swift
//  DoitdoWidget
//
//  doitdo 홈스크린 위젯 (Medium 사이즈 단일 지원).
//  - 오늘 TODO 목록을 표시 (최대 4~5개)
//  - 공간 남으면 "나중에" 섹션 1~2개
//  - iOS 17+: 체크박스 직접 탭 → AppIntent 백그라운드 토글 (앱 안 열림)
//  - iOS 16 이하: 어떤 영역을 탭해도 앱 열림 (URL deep link)
//
//  컬러 톤은 본 앱 메인 화면(`AppColors`) 과 일치 — 위젯은 별도 프로세스라
//  `DoitdoColors` ThemeExtension 을 못 받으므로 하드코딩한다.
//  값은 `lib/core/theme/app_colors.dart` 의 상수와 1:1 매핑.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - doitdo 디자인 토큰 (앱 메인 화면 톤과 동일)

private extension Color {
    /// 메인 액센트 주황 — 체크 채움 / 강조 칩 (`AppColors.loginBtnOn`)
    static let doitdoAccent = Color(red: 0xE2 / 255, green: 0x78 / 255, blue: 0x2B / 255)
    /// 위젯 배경 크림 — 메인 홈 톤 (`#F8F5EC` 계열)
    static let doitdoBackground = Color(red: 0xF8 / 255, green: 0xF5 / 255, blue: 0xEC / 255)
    /// 미체크 체크박스의 외곽 링 (`AppColors.streakCheckX`)
    static let doitdoUnchecked = Color(red: 0xEA / 255, green: 0xE8 / 255, blue: 0xDE / 255)
    /// 본문 텍스트 (진한 갈회색)
    static let doitdoTextPrimary = Color(red: 0x3A / 255, green: 0x35 / 255, blue: 0x2D / 255)
    /// 보조 텍스트 / 카운트
    static let doitdoTextSecondary = Color(red: 0x8C / 255, green: 0x81 / 255, blue: 0x74 / 255)
    /// 완료 처리된 텍스트 — 더 흐린 톤 + 취소선
    static let doitdoTextDone = Color(red: 0xB3 / 255, green: 0xAA / 255, blue: 0x9A / 255)
}

// MARK: - Timeline Provider

struct DoitdoEntry: TimelineEntry {
    let date: Date
    let payload: WidgetPayload?
    let hasAuthToken: Bool
}

struct DoitdoTimelineProvider: TimelineProvider {

    /// 토글 직후 strikethrough 노출 시간 — 너무 짧으면 인지 못 하고, 너무 길면 답답.
    private static let strikethroughLinger: TimeInterval = 0.45

    func placeholder(in context: Context) -> DoitdoEntry {
        DoitdoEntry(
            date: Date(),
            payload: WidgetPayload(
                todayTodos: [
                    WidgetTodo(id: 1, title: "물 마시기", isDone: false, isSomeday: false),
                    WidgetTodo(id: 2, title: "산책 30분", isDone: true, isSomeday: false),
                ],
                somedayTodos: [],
                updatedAt: ISO8601DateFormatter().string(from: Date())
            ),
            hasAuthToken: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (DoitdoEntry) -> Void) {
        // 스냅샷(위젯 갤러리 미리보기)은 transition 이 의미 없으므로 cleaned 상태만.
        // SwiftUI 컨텍스트에서는 Optional.map 이 Gesture.map 과 overload 충돌하므로 if-let 으로 풀어쓴다.
        let raw = SharedStore.payload()
        let cleanedSnapshot: WidgetPayload?
        if let raw = raw {
            cleanedSnapshot = cleaned(of: raw)
        } else {
            cleanedSnapshot = nil
        }
        completion(DoitdoEntry(
            date: Date(),
            payload: cleanedSnapshot,
            hasAuthToken: hasAuthToken()
        ))
    }

    /// 핵심: payload 에 isDone=true 항목이 있으면(=토글 직후) 두 entry 로 transition 을 만든다.
    ///   entry 1 (now)              : 그대로 노출 → "주황 채움 + 취소선"
    ///   entry 2 (now+strikethroughLinger) : 해당 항목들 제거 → 부드럽게 사라짐
    /// 동시에 SharedStore 도 cleaned 로 갱신 → 다음 reload 시 strikethrough 가 영구히 남는 사고 방지.
    /// (이 cleanup 이 없으면 위젯 화면을 잠시 떠났다 돌아올 때 완료된 항목이 다시 보이는 버그 발생.)
    func getTimeline(in context: Context, completion: @escaping (Timeline<DoitdoEntry>) -> Void) {
        let now = Date()
        let payload = SharedStore.payload()
        let token = hasAuthToken()
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now

        if let payload = payload, hasDoneItems(in: payload) {
            let cleanedNow = cleaned(of: payload)
            // SharedStore 정리 — 다음 호출에서는 cleaned 가 source of truth.
            SharedStore.savePayload(cleanedNow)

            let entry1 = DoitdoEntry(date: now, payload: payload, hasAuthToken: token)
            let entry2 = DoitdoEntry(
                date: now.addingTimeInterval(Self.strikethroughLinger),
                payload: cleanedNow,
                hasAuthToken: token
            )
            completion(Timeline(entries: [entry1, entry2], policy: .after(nextRefresh)))
        } else {
            let entry = DoitdoEntry(date: now, payload: payload, hasAuthToken: token)
            completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
        }
    }

    // MARK: - Helpers

    private func hasAuthToken() -> Bool {
        SharedStore.accessToken()?.isEmpty == false
    }

    private func hasDoneItems(in payload: WidgetPayload) -> Bool {
        payload.todayTodos.contains { $0.isDone } ||
        payload.somedayTodos.contains { $0.isDone }
    }

    /// payload 의 isDone=true 항목을 제거한 새 payload — non-optional 보장.
    private func cleaned(of payload: WidgetPayload) -> WidgetPayload {
        WidgetPayload(
            todayTodos: payload.todayTodos.filter { !$0.isDone },
            somedayTodos: payload.somedayTodos.filter { !$0.isDone },
            updatedAt: payload.updatedAt
        )
    }
}

// MARK: - Entry View

struct DoitdoWidgetEntryView: View {
    var entry: DoitdoEntry

    /// 한 컬럼이 위젯 높이 안에서 안정적으로 들어가는 행 수.
    /// (헤더 + 행 3 + spacer + overflow chip 기준 ~120pt)
    private static let maxRowsPerColumn = 3

    var body: some View {
        Group {
            if !entry.hasAuthToken {
                emptyState(text: "로그인이 필요해요", subtext: "탭해서 doitdo 열기")
            } else if let payload = entry.payload {
                content(payload: payload)
            } else {
                emptyState(text: "아직 데이터가 없어요", subtext: "탭해서 doitdo 열기")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(URL(string: "doitdo://widget/open"))
    }

    @ViewBuilder
    private func content(payload: WidgetPayload) -> some View {
        // payload 의 모든 항목을 그대로 렌더 — DONE 항목 필터링은 두 가지 경로에서 별도 처리.
        //  1) 앱 → 위젯 sync 시점: TodoViewModel 이 미완료 TODO 만 보내므로 DONE 자체가 안 들어옴
        //  2) 위젯 토글 시점: AppIntent 가 DONE 으로 표시 → 짧게 strikethrough 노출 → 이후 제거
        // 이 분리 덕에 위젯에서 체크 누르면 "주황 채움 + 취소선 → 사라짐" 애니메이션이 자연스럽게 발생.
        let today = Array(payload.todayTodos.prefix(Self.maxRowsPerColumn))
        let someday = Array(payload.somedayTodos.prefix(Self.maxRowsPerColumn))
        let todayOverflow = max(0, payload.todayTodos.count - today.count)
        let somedayOverflow = max(0, payload.somedayTodos.count - someday.count)

        if today.isEmpty && someday.isEmpty {
            emptyState(text: "오늘 할 일이 없어요!", subtext: "탭해서 추가하기")
        } else {
            HStack(alignment: .top, spacing: 14) {
                column(
                    title: "오늘의 할 일",
                    todos: today,
                    overflow: todayOverflow,
                    emptyText: "다 했어요!"
                )
                column(
                    title: "언젠가 할 일",
                    todos: someday,
                    overflow: somedayOverflow,
                    emptyText: "다 했어요!"
                )
            }
        }
    }

    private func column(
        title: String,
        todos: [WidgetTodo],
        overflow: Int,
        emptyText: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            columnHeader(title)
            if todos.isEmpty {
                // 빈 컬럼 — 헤더 아래 남은 영역의 정중앙에 큰 안내 텍스트 한 줄.
                Spacer(minLength: 0)
                Text(emptyText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.doitdoTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer(minLength: 0)
            } else {
                ForEach(todos) { todo in
                    row(todo: todo)
                }
                Spacer(minLength: 0)
                // 컬럼별 overflow 는 좌측 하단. 너무 끝에 붙지 않게 살짝 띄움.
                if overflow > 0 {
                    Text("+\(overflow)개 더")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.doitdoTextSecondary)
                        .padding(.bottom, 4)
                        .padding(.leading, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func columnHeader(_ title: String) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Color.doitdoTextPrimary)
                .frame(width: 5, height: 5)
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.doitdoTextPrimary)
        }
        .padding(.bottom, 2)
    }

    /// TODO 한 줄. iOS 17+ 는 체크박스가 인터랙티브 버튼,
    /// 16 이하는 단순 디스플레이 + 위젯 전체 탭으로 앱 진입.
    @ViewBuilder
    private func row(todo: WidgetTodo) -> some View {
        HStack(spacing: 7) {
            if #available(iOS 17.0, *) {
                Button(intent: ToggleTodoIntent(todoId: todo.id)) {
                    checkIcon(isDone: todo.isDone)
                }
                .buttonStyle(.plain)
            } else {
                checkIcon(isDone: todo.isDone)
            }
            Text(todo.title)
                .font(.system(size: 13, weight: .medium))
                .strikethrough(todo.isDone, color: Color.doitdoTextDone)
                .foregroundStyle(todo.isDone ? Color.doitdoTextDone : Color.doitdoTextPrimary)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
    }

    /// 메인 홈의 체크박스와 동일 디자인을 유지하되 2컬럼 레이아웃에 맞게 21pt 로 축소.
    /// 외곽 frame 26pt 로 터치 영역 확보 — 위젯 좁은 컬럼에서도 누르기 충분.
    private func checkIcon(isDone: Bool) -> some View {
        ZStack {
            Circle()
                .fill(isDone ? Color.doitdoAccent : Color.clear)
                .frame(width: 21, height: 21)
            Circle()
                .stroke(isDone ? Color.doitdoAccent : Color.doitdoUnchecked, lineWidth: 1.8)
                .frame(width: 21, height: 21)
            if isDone {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 26, height: 26)
        .contentShape(Rectangle())
    }

    private func emptyState(text: String, subtext: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Spacer(minLength: 0)
            Text(text)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.doitdoTextPrimary)
            Text(subtext)
                .font(.system(size: 12))
                .foregroundStyle(Color.doitdoTextSecondary)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Widget

struct DoitdoWidget: Widget {
    let kind: String = "DoitdoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DoitdoTimelineProvider()) { entry in
            if #available(iOS 17.0, *) {
                DoitdoWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        Color.doitdoBackground
                    }
            } else {
                DoitdoWidgetEntryView(entry: entry)
                    .padding()
                    .background(Color.doitdoBackground)
            }
        }
        .configurationDisplayName("doitdo")
        .description("오늘 할 일을 빠르게 확인하고 체크하세요")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    DoitdoWidget()
} timeline: {
    DoitdoEntry(
        date: .now,
        payload: WidgetPayload(
            todayTodos: [
                WidgetTodo(id: 1, title: "물 8잔 마시기", isDone: false, isSomeday: false),
                WidgetTodo(id: 2, title: "산책 30분", isDone: true, isSomeday: false),
                WidgetTodo(id: 3, title: "영단어 50개", isDone: false, isSomeday: false),
            ],
            somedayTodos: [
                WidgetTodo(id: 99, title: "방 청소", isDone: false, isSomeday: true)
            ],
            updatedAt: ISO8601DateFormatter().string(from: .now)
        ),
        hasAuthToken: true
    )
}
