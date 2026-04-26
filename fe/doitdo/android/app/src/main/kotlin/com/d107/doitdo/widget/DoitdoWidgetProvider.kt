package com.d107.doitdo.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Paint
import android.os.Build
import android.text.SpannableString
import android.text.style.StrikethroughSpan
import android.widget.RemoteViews
import com.d107.doitdo.MainActivity
import com.d107.doitdo.R

/**
 * doitdo 홈 위젯 (Medium 사이즈 단일).
 *
 * iOS DoitdoWidget.swift 와 동일한 정보 구조:
 * - 인증 토큰 없음 → "로그인이 필요해요" 안내
 * - payload 비어있음 → "오늘 할 일이 없어요!" 안내
 * - 데이터 있음 → 오늘(최대 4) + 나중에(최대 1) 행
 *
 * 행 별 체크 아이콘은 [ToggleTodoReceiver] 로 broadcast PendingIntent 연결.
 * 카드 배경 탭은 [MainActivity] 진입(딥링크 doitdo://widget/open).
 */
class DoitdoWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val MAX_TODAY_ROWS = 4
        private const val MAX_SOMEDAY_ROWS = 1

        // 행/체크/제목 ID 를 인덱스로 lookup 하기 위한 매핑.
        // RemoteViews 는 R.id 정수만 받으므로 layout XML 의 id 와 1:1 매칭.
        private val TODAY_ROW_IDS = intArrayOf(
            R.id.row_today_0, R.id.row_today_1, R.id.row_today_2, R.id.row_today_3
        )
        private val TODAY_CHECK_IDS = intArrayOf(
            R.id.check_today_0, R.id.check_today_1, R.id.check_today_2, R.id.check_today_3
        )
        private val TODAY_TITLE_IDS = intArrayOf(
            R.id.title_today_0, R.id.title_today_1, R.id.title_today_2, R.id.title_today_3
        )
        private val SOMEDAY_ROW_IDS = intArrayOf(R.id.row_someday_0)
        private val SOMEDAY_CHECK_IDS = intArrayOf(R.id.check_someday_0)
        private val SOMEDAY_TITLE_IDS = intArrayOf(R.id.title_someday_0)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) {
            renderWidget(context, appWidgetManager, id)
        }
    }

    private fun renderWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
    ) {
        val views = RemoteViews(context.packageName, R.layout.doitdo_widget)

        val hasToken = WidgetSharedStore.accessToken(context) != null
        val payload = WidgetSharedStore.payload(context)

        // 카드 전체 탭 → 앱 진입 (딥링크 doitdo://widget/open).
        // 모든 컨텐츠 위에 깔리는 root LinearLayout 에 click 을 걸어두면 빈 영역
        // 어디를 눌러도 앱이 열린다. 행의 체크박스는 따로 별도 PendingIntent 로
        // 덮어써 토글 우선.
        views.setOnClickPendingIntent(R.id.widget_root, openAppPendingIntent(context))

        when {
            !hasToken -> renderEmptyState(
                views,
                title = "로그인이 필요해요",
                subtitle = "탭해서 doitdo 열기",
            )
            payload == null -> renderEmptyState(
                views,
                title = "아직 데이터가 없어요",
                subtitle = "탭해서 doitdo 열기",
            )
            payload.todayTodos.isEmpty() && payload.somedayTodos.isEmpty() -> renderEmptyState(
                views,
                title = "오늘 할 일이 없어요!",
                subtitle = "탭해서 추가하기",
            )
            else -> renderContent(context, views, payload)
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun renderEmptyState(views: RemoteViews, title: String, subtitle: String) {
        views.setViewVisibility(R.id.empty_state, android.view.View.VISIBLE)
        views.setViewVisibility(R.id.content_state, android.view.View.GONE)
        views.setTextViewText(R.id.empty_title, title)
        views.setTextViewText(R.id.empty_subtitle, subtitle)
    }

    private fun renderContent(context: Context, views: RemoteViews, payload: WidgetPayload) {
        views.setViewVisibility(R.id.empty_state, android.view.View.GONE)
        views.setViewVisibility(R.id.content_state, android.view.View.VISIBLE)

        // 오늘 헤더 카운트 — 잘리지 않은 전체 개수 노출.
        views.setTextViewText(R.id.today_count, payload.todayTodos.size.toString())

        // 오늘 행 채우기 (최대 MAX_TODAY_ROWS).
        val today = payload.todayTodos.take(MAX_TODAY_ROWS)
        for (i in TODAY_ROW_IDS.indices) {
            if (i < today.size) {
                fillRow(
                    context, views, today[i],
                    rowId = TODAY_ROW_IDS[i],
                    checkId = TODAY_CHECK_IDS[i],
                    titleId = TODAY_TITLE_IDS[i],
                )
            } else {
                views.setViewVisibility(TODAY_ROW_IDS[i], android.view.View.GONE)
            }
        }

        // 나중에 섹션 — 데이터 있으면 헤더 + 행 노출.
        val someday = payload.somedayTodos.take(MAX_SOMEDAY_ROWS)
        if (someday.isNotEmpty()) {
            views.setViewVisibility(R.id.someday_header, android.view.View.VISIBLE)
            for (i in SOMEDAY_ROW_IDS.indices) {
                if (i < someday.size) {
                    fillRow(
                        context, views, someday[i],
                        rowId = SOMEDAY_ROW_IDS[i],
                        checkId = SOMEDAY_CHECK_IDS[i],
                        titleId = SOMEDAY_TITLE_IDS[i],
                    )
                } else {
                    views.setViewVisibility(SOMEDAY_ROW_IDS[i], android.view.View.GONE)
                }
            }
        } else {
            views.setViewVisibility(R.id.someday_header, android.view.View.GONE)
            for (id in SOMEDAY_ROW_IDS) {
                views.setViewVisibility(id, android.view.View.GONE)
            }
        }
    }

    private fun fillRow(
        context: Context,
        views: RemoteViews,
        todo: WidgetTodo,
        rowId: Int,
        checkId: Int,
        titleId: Int,
    ) {
        views.setViewVisibility(rowId, android.view.View.VISIBLE)
        views.setImageViewResource(
            checkId,
            if (todo.isDone) R.drawable.widget_check_done else R.drawable.widget_check_inactive,
        )
        // 완료된 항목은 취소선 + 흐린 색.
        if (todo.isDone) {
            val span = SpannableString(todo.title)
            span.setSpan(StrikethroughSpan(), 0, span.length, 0)
            views.setTextViewText(titleId, span)
            views.setTextColor(titleId, color(context, R.color.widget_text_done))
        } else {
            views.setTextViewText(titleId, todo.title)
            views.setTextColor(titleId, color(context, R.color.widget_text_primary))
        }
        // 체크 아이콘 탭 → ToggleTodoReceiver 로 broadcast.
        // PendingIntent 의 requestCode 를 todoId 로 두면 같은 위젯 안에서 todo 별로 별도 instance.
        views.setOnClickPendingIntent(checkId, togglePendingIntent(context, todo.id))
    }

    private fun openAppPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = android.net.Uri.parse("doitdo://widget/open")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context, 0, intent,
            pendingIntentFlags(),
        )
    }

    private fun togglePendingIntent(context: Context, todoId: Int): PendingIntent {
        val intent = Intent(context, ToggleTodoReceiver::class.java).apply {
            action = ToggleTodoReceiver.ACTION_TOGGLE
            putExtra(ToggleTodoReceiver.EXTRA_TODO_ID, todoId)
        }
        return PendingIntent.getBroadcast(
            context, todoId, intent,
            pendingIntentFlags(),
        )
    }

    private fun pendingIntentFlags(): Int {
        // API 31+ 는 IMMUTABLE 또는 MUTABLE 명시 필수.
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
    }

    private fun color(context: Context, resId: Int): Int = context.getColor(resId)
}
