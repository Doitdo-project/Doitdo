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

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Timeline Provider

struct DoitdoEntry: TimelineEntry {
    let date: Date
    let payload: WidgetPayload?
    let hasAuthToken: Bool
}

struct DoitdoTimelineProvider: TimelineProvider {
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
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DoitdoEntry>) -> Void) {
        // OS 가 결정하는 갱신 주기지만 한 시간 후 다시 새로 그리도록 힌트.
        // 실제 즉시 갱신은 WidgetCenter.reloadTimelines 호출(앱/Intent 측)으로 트리거.
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [currentEntry()], policy: .after(next))
        completion(timeline)
    }

    private func currentEntry() -> DoitdoEntry {
        DoitdoEntry(
            date: Date(),
            payload: SharedStore.payload(),
            hasAuthToken: (SharedStore.accessToken()?.isEmpty == false)
        )
    }
}

// MARK: - Entry View

struct DoitdoWidgetEntryView: View {
    var entry: DoitdoEntry

    private static let maxTodayRows = 4
    private static let maxSomedayRows = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
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
        let today = Array(payload.todayTodos.prefix(Self.maxTodayRows))
        let someday = Array(payload.somedayTodos.prefix(Self.maxSomedayRows))

        if today.isEmpty && someday.isEmpty {
            emptyState(text: "오늘 할 일이 없어요!", subtext: "탭해서 추가하기")
        } else {
            // 오늘 헤더
            HStack(spacing: 4) {
                Text("오늘")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)
                Text("\(payload.todayTodos.count)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            ForEach(today) { todo in
                row(todo: todo)
            }
            if !someday.isEmpty {
                HStack(spacing: 4) {
                    Text("나중에")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding(.top, 2)
                ForEach(someday) { todo in
                    row(todo: todo)
                }
            }
        }
    }

    /// TODO 한 줄. iOS 17+ 는 체크박스가 인터랙티브 버튼, 16 이하는 단순 디스플레이 + 위젯 전체 탭으로 앱 진입.
    @ViewBuilder
    private func row(todo: WidgetTodo) -> some View {
        HStack(spacing: 8) {
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
                .strikethrough(todo.isDone, color: .secondary)
                .foregroundStyle(todo.isDone ? .secondary : .primary)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
    }

    private func checkIcon(isDone: Bool) -> some View {
        Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(isDone ? Color.accentColor : Color.secondary)
            .frame(width: 20, height: 20)
    }

    private func emptyState(text: String, subtext: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Spacer(minLength: 0)
            Text(text).font(.system(size: 14, weight: .semibold))
            Text(subtext).font(.caption).foregroundStyle(.secondary)
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
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                DoitdoWidgetEntryView(entry: entry)
                    .padding()
                    .background()
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
