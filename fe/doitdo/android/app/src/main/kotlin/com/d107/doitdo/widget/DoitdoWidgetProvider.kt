package com.d107.doitdo.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.widget.RemoteViews
import com.d107.doitdo.MainActivity
import com.d107.doitdo.R

class DoitdoWidgetProvider : AppWidgetProvider() {

    companion object {
        const val MAX_ROWS = 4

        fun updateAllWidgets(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(ComponentName(context, DoitdoWidgetProvider::class.java))
            if (ids.isEmpty()) return
            val provider = DoitdoWidgetProvider()
            for (id in ids) {
                provider.renderWidget(context, mgr, id)
            }
        }

        /**
         * 체크 아이콘 + 텍스트 색상만 부분 업데이트 (full redraw 없음).
         * [preUpdatePayload] 는 isDone 변경 전 원본 payload — 행 위치 계산에 사용.
         */
        fun partiallyUpdateCheckState(context: Context, todoId: Int, preUpdatePayload: WidgetPayload) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(ComponentName(context, DoitdoWidgetProvider::class.java))
            if (ids.isEmpty()) return

            val todayPage = WidgetSharedStore.todayPage(context)
            val somedayPage = WidgetSharedStore.somedayPage(context)
            val activeTodayItems = preUpdatePayload.todayTodos.filter { !it.isDone }
            val activeSomedayItems = preUpdatePayload.somedayTodos.filter { !it.isDone }

            val partial = RemoteViews(context.packageName, R.layout.doitdo_widget)

            fun applyCheck(items: List<WidgetTodo>, page: Int, checkIds: IntArray, titleIds: IntArray) {
                if (items.isEmpty()) return
                val safePage = page.coerceIn(0, (items.size - 1) / MAX_ROWS)
                val pageItems = items.drop(safePage * MAX_ROWS).take(MAX_ROWS)
                val idx = pageItems.indexOfFirst { it.id == todoId }
                if (idx < 0) return
                partial.setImageViewResource(checkIds[idx], R.drawable.widget_check_done)
                partial.setTextColor(titleIds[idx], context.getColor(R.color.widget_text_done))
            }

            applyCheck(activeTodayItems, todayPage, TODAY_CHECK_IDS, TODAY_TITLE_IDS)
            applyCheck(activeSomedayItems, somedayPage, SOMEDAY_CHECK_IDS, SOMEDAY_TITLE_IDS)

            for (id in ids) {
                mgr.partiallyUpdateAppWidget(id, partial)
            }
        }

        private val TODAY_ROW_IDS = intArrayOf(
            R.id.row_today_0, R.id.row_today_1, R.id.row_today_2, R.id.row_today_3,
        )
        private val TODAY_CHECK_IDS = intArrayOf(
            R.id.check_today_0, R.id.check_today_1, R.id.check_today_2, R.id.check_today_3,
        )
        private val TODAY_TITLE_IDS = intArrayOf(
            R.id.title_today_0, R.id.title_today_1, R.id.title_today_2, R.id.title_today_3,
        )
        private val SOMEDAY_ROW_IDS = intArrayOf(
            R.id.row_someday_0, R.id.row_someday_1, R.id.row_someday_2, R.id.row_someday_3,
        )
        private val SOMEDAY_CHECK_IDS = intArrayOf(
            R.id.check_someday_0, R.id.check_someday_1, R.id.check_someday_2, R.id.check_someday_3,
        )
        private val SOMEDAY_TITLE_IDS = intArrayOf(
            R.id.title_someday_0, R.id.title_someday_1, R.id.title_someday_2, R.id.title_someday_3,
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

        val activeToday = payload?.todayTodos.orEmpty().filter { !it.isDone }
        val activeSomeday = payload?.somedayTodos.orEmpty().filter { !it.isDone }

        views.setOnClickPendingIntent(R.id.widget_root, openAppPendingIntent(context))

        when {
            !hasToken -> renderEmptyState(views, "로그인이 필요해요", "탭해서 doitdo 열기")
            payload == null -> renderEmptyState(views, "아직 데이터가 없어요", "탭해서 doitdo 열기")
            activeToday.isEmpty() && activeSomeday.isEmpty() -> renderEmptyState(views, "오늘 할 일이 없어요!", "탭해서 추가하기")
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
            spacerId = R.id.today_spacer,
            navId = R.id.today_nav,
            prevId = R.id.today_prev,
            pageLabelId = R.id.today_page_label,
            nextId = R.id.today_next,
            emptyHintId = R.id.today_empty_hint,
            page = WidgetSharedStore.todayPage(context),
            column = PageTurnReceiver.COLUMN_TODAY,
        )
        renderColumn(
            context, views,
            todos = activeSomeday,
            rowIds = SOMEDAY_ROW_IDS,
            checkIds = SOMEDAY_CHECK_IDS,
            titleIds = SOMEDAY_TITLE_IDS,
            spacerId = R.id.someday_spacer,
            navId = R.id.someday_nav,
            prevId = R.id.someday_prev,
            pageLabelId = R.id.someday_page_label,
            nextId = R.id.someday_next,
            emptyHintId = R.id.someday_empty_hint,
            page = WidgetSharedStore.somedayPage(context),
            column = PageTurnReceiver.COLUMN_SOMEDAY,
        )
    }

    private fun renderColumn(
        context: Context,
        views: RemoteViews,
        todos: List<WidgetTodo>,
        rowIds: IntArray,
        checkIds: IntArray,
        titleIds: IntArray,
        spacerId: Int,
        navId: Int,
        prevId: Int,
        pageLabelId: Int,
        nextId: Int,
        emptyHintId: Int,
        page: Int,
        column: String,
    ) {
        if (todos.isEmpty()) {
            for (rowId in rowIds) views.setViewVisibility(rowId, android.view.View.GONE)
            views.setViewVisibility(emptyHintId, android.view.View.VISIBLE)
            views.setViewVisibility(spacerId, android.view.View.GONE)
            views.setViewVisibility(navId, android.view.View.GONE)
            return
        }

        views.setViewVisibility(emptyHintId, android.view.View.GONE)
        views.setViewVisibility(spacerId, android.view.View.INVISIBLE)

        val maxPage = (todos.size - 1) / MAX_ROWS
        val safePage = page.coerceIn(0, maxPage)
        val pageItems = todos.drop(safePage * MAX_ROWS).take(MAX_ROWS)

        for (i in rowIds.indices) {
            val rowId = rowIds[i]
            if (i < pageItems.size) {
                fillRow(context, views, pageItems[i], rowId, checkIds[i], titleIds[i])
            } else {
                views.setViewVisibility(rowId, android.view.View.GONE)
            }
        }

        if (maxPage > 0) {
            views.setViewVisibility(navId, android.view.View.VISIBLE)
            views.setTextViewText(pageLabelId, "${safePage + 1}/${maxPage + 1}")
            if (safePage > 0) {
                views.setViewVisibility(prevId, android.view.View.VISIBLE)
                views.setOnClickPendingIntent(prevId, pageTurnIntent(context, column, -1))
            } else {
                views.setViewVisibility(prevId, android.view.View.INVISIBLE)
            }
            if (safePage < maxPage) {
                views.setViewVisibility(nextId, android.view.View.VISIBLE)
                views.setOnClickPendingIntent(nextId, pageTurnIntent(context, column, +1))
            } else {
                views.setViewVisibility(nextId, android.view.View.INVISIBLE)
            }
        } else {
            views.setViewVisibility(navId, android.view.View.GONE)
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
        views.setImageViewResource(checkId, R.drawable.widget_check_inactive)
        views.setTextViewText(titleId, todo.title)
        views.setTextColor(titleId, context.getColor(R.color.widget_text_primary))
        views.setOnClickPendingIntent(checkId, togglePendingIntent(context, todo.id))
    }

    private fun pageTurnIntent(context: Context, column: String, direction: Int): PendingIntent {
        val requestCode = when {
            column == PageTurnReceiver.COLUMN_TODAY && direction < 0 -> 200
            column == PageTurnReceiver.COLUMN_TODAY && direction > 0 -> 201
            column == PageTurnReceiver.COLUMN_SOMEDAY && direction < 0 -> 202
            else -> 203
        }
        val intent = Intent(context, PageTurnReceiver::class.java).apply {
            action = PageTurnReceiver.ACTION_PAGE_TURN
            putExtra(PageTurnReceiver.EXTRA_COLUMN, column)
            putExtra(PageTurnReceiver.EXTRA_DIRECTION, direction)
        }
        return PendingIntent.getBroadcast(context, requestCode, intent, pendingIntentFlags())
    }

    private fun openAppPendingIntent(context: Context): PendingIntent {
        val hasToken = WidgetSharedStore.accessToken(context) != null
        val intent = Intent(context, MainActivity::class.java).apply {
            if (hasToken) {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            } else {
                action = Intent.ACTION_VIEW
                data = Uri.parse("doitdo://widget/open")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
        }
        return PendingIntent.getActivity(context, 0, intent, pendingIntentFlags())
    }

    private fun togglePendingIntent(context: Context, todoId: Int): PendingIntent {
        val intent = Intent(context, ToggleTodoReceiver::class.java).apply {
            action = ToggleTodoReceiver.ACTION_TOGGLE
            putExtra(ToggleTodoReceiver.EXTRA_TODO_ID, todoId)
        }
        return PendingIntent.getBroadcast(context, todoId, intent, pendingIntentFlags())
    }

    private fun pendingIntentFlags(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
}
