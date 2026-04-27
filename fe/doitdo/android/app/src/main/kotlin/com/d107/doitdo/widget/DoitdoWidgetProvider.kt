package com.d107.doitdo.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Build
import android.text.SpannableString
import android.text.style.StrikethroughSpan
import android.widget.RemoteViews
import com.d107.doitdo.MainActivity
import com.d107.doitdo.R

/**
 * doitdo 홈 위젯 (4x2 셀, 좌우 2단).
 *
 * - 인증 토큰 없음 → "로그인이 필요해요" 안내
 * - payload 비어있음 → "오늘 할 일이 없어요!" 안내
 * - 미완료 todo 만 화면에 노출 (완료 항목은 필터로 제외).
 * - 좌(오늘) / 우(언젠간) 각 최대 4행 + 초과 시 "+N개 더" 푸터.
 *   실제 위젯 높이가 작은 런처에선 OS 가 하단 행을 자연스럽게 클립.
 *
 * 행의 체크 아이콘은 [ToggleTodoReceiver] 로 broadcast PendingIntent 연결.
 * 카드 배경 탭은 [MainActivity] 진입(딥링크 doitdo://widget/open).
 */
class DoitdoWidgetProvider : AppWidgetProvider() {

    companion object {
        // 컬럼당 채울 수 있는 최대 행 수.
        // 위젯 실제 높이가 작은 런처에선 하단 행이 자연스럽게 잘려나간다(visibility 는 VISIBLE
        // 이지만 부모 RemoteViews 가 짧으면 OS 가 클립). 큰 위젯에선 모두 보임.
        private const val MAX_ROWS_PER_COLUMN = 4

        private val TODAY_ROW_IDS = intArrayOf(
            R.id.row_today_0, R.id.row_today_1, R.id.row_today_2, R.id.row_today_3
        )
        private val TODAY_CHECK_IDS = intArrayOf(
            R.id.check_today_0, R.id.check_today_1, R.id.check_today_2, R.id.check_today_3
        )
        private val TODAY_TITLE_IDS = intArrayOf(
            R.id.title_today_0, R.id.title_today_1, R.id.title_today_2, R.id.title_today_3
        )
        private val SOMEDAY_ROW_IDS = intArrayOf(
            R.id.row_someday_0, R.id.row_someday_1, R.id.row_someday_2, R.id.row_someday_3
        )
        private val SOMEDAY_CHECK_IDS = intArrayOf(
            R.id.check_someday_0, R.id.check_someday_1, R.id.check_someday_2, R.id.check_someday_3
        )
        private val SOMEDAY_TITLE_IDS = intArrayOf(
            R.id.title_someday_0, R.id.title_someday_1, R.id.title_someday_2, R.id.title_someday_3
        )
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
        // 위젯에서 직전에 체크된 todo 는 ToggleTodoReceiver 가 잠깐 fading 마크해 둔다.
        // 그 todo 만 done 상태에서도 한 프레임 더 보여서 "체크 → 사라짐" 전환 효과를 만든다.
        val fadingId = WidgetSharedStore.fadingTodoId(context)
        val activeToday = payload?.todayTodos.orEmpty()
            .filter { !it.isDone || it.id == fadingId }
        val activeSomeday = payload?.somedayTodos.orEmpty()
            .filter { !it.isDone || it.id == fadingId }

        // 카드 전체 탭 → 앱 진입 (딥링크 doitdo://widget/open).
        // 행의 체크박스는 별도 PendingIntent 로 덮어써 토글 우선.
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
            activeToday.isEmpty() && activeSomeday.isEmpty() -> renderEmptyState(
                views,
                title = "오늘 할 일이 없어요!",
                subtitle = "탭해서 추가하기",
            )
            else -> renderContent(context, views, activeToday, activeSomeday)
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun renderEmptyState(views: RemoteViews, title: String, subtitle: String) {
        views.setViewVisibility(R.id.empty_state, android.view.View.VISIBLE)
        views.setViewVisibility(R.id.content_state, android.view.View.GONE)
        views.setTextViewText(R.id.empty_title, title)
        views.setTextViewText(R.id.empty_subtitle, subtitle)
    }

    private fun renderContent(
        context: Context,
        views: RemoteViews,
        activeToday: List<WidgetTodo>,
        activeSomeday: List<WidgetTodo>,
    ) {
        views.setViewVisibility(R.id.empty_state, android.view.View.GONE)
        views.setViewVisibility(R.id.content_state, android.view.View.VISIBLE)

        renderColumn(
            context, views,
            todos = activeToday,
            rowIds = TODAY_ROW_IDS,
            checkIds = TODAY_CHECK_IDS,
            titleIds = TODAY_TITLE_IDS,
            moreId = R.id.today_more,
            emptyHintId = R.id.today_empty_hint,
        )
        renderColumn(
            context, views,
            todos = activeSomeday,
            rowIds = SOMEDAY_ROW_IDS,
            checkIds = SOMEDAY_CHECK_IDS,
            titleIds = SOMEDAY_TITLE_IDS,
            moreId = R.id.someday_more,
            emptyHintId = R.id.someday_empty_hint,
        )
    }

    private fun renderColumn(
        context: Context,
        views: RemoteViews,
        todos: List<WidgetTodo>,
        rowIds: IntArray,
        checkIds: IntArray,
        titleIds: IntArray,
        moreId: Int,
        emptyHintId: Int,
    ) {
        // 빈 컬럼 안내 — 미완료 0개일 때.
        views.setViewVisibility(
            emptyHintId,
            if (todos.isEmpty()) android.view.View.VISIBLE else android.view.View.GONE,
        )

        // 행 채우기 (최대 MAX_ROWS_PER_COLUMN).
        val visible = todos.take(MAX_ROWS_PER_COLUMN)
        for (i in rowIds.indices) {
            if (i < visible.size) {
                fillRow(
                    context, views, visible[i],
                    rowId = rowIds[i],
                    checkId = checkIds[i],
                    titleId = titleIds[i],
                )
            } else {
                views.setViewVisibility(rowIds[i], android.view.View.GONE)
            }
        }

        // "+N개 더" 푸터 — 잘려나간 미완료 잔여분이 있을 때만.
        val overflow = todos.size - MAX_ROWS_PER_COLUMN
        if (overflow > 0) {
            views.setTextViewText(moreId, "+${overflow}개 더")
            views.setViewVisibility(moreId, android.view.View.VISIBLE)
        } else {
            views.setViewVisibility(moreId, android.view.View.GONE)
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
        if (todo.isDone) {
            // fading 중인 todo — 채워진 원 + 취소선 + 흐린 색으로 잠깐 보여줬다가 사라진다.
            views.setImageViewResource(checkId, R.drawable.widget_check_done)
            val span = SpannableString(todo.title)
            span.setSpan(StrikethroughSpan(), 0, span.length, 0)
            views.setTextViewText(titleId, span)
            views.setTextColor(titleId, color(context, R.color.widget_text_done))
        } else {
            views.setImageViewResource(checkId, R.drawable.widget_check_inactive)
            views.setTextViewText(titleId, todo.title)
            views.setTextColor(titleId, color(context, R.color.widget_text_primary))
        }
        // 체크 아이콘 탭 → ToggleTodoReceiver 로 broadcast.
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
