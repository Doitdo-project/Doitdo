package com.d107.doitdo.widget

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * 위젯 페이지 이동 화살표 탭 → 해당 컬럼의 페이지를 1 증감하고 위젯 재렌더.
 *
 * [DoitdoWidgetProvider] 가 `setPendingIntentTemplate` 없이 각 화살표마다
 * 독립 PendingIntent 로 연결한다.
 */
class PageTurnReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_PAGE_TURN = "com.d107.doitdo.widget.ACTION_PAGE_TURN"
        const val EXTRA_COLUMN = "column"
        const val EXTRA_DIRECTION = "direction"
        const val COLUMN_TODAY = "today"
        const val COLUMN_SOMEDAY = "someday"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_PAGE_TURN) return
        val column = intent.getStringExtra(EXTRA_COLUMN) ?: return
        val direction = intent.getIntExtra(EXTRA_DIRECTION, 0)
        if (direction == 0) return

        val payload = WidgetSharedStore.payload(context)
        val todos = when (column) {
            COLUMN_TODAY -> payload?.todayTodos.orEmpty().filter { !it.isDone }
            else -> payload?.somedayTodos.orEmpty().filter { !it.isDone }
        }
        val maxPage = if (todos.isEmpty()) 0 else (todos.size - 1) / DoitdoWidgetProvider.MAX_ROWS

        val currentPage = when (column) {
            COLUMN_TODAY -> WidgetSharedStore.todayPage(context)
            else -> WidgetSharedStore.somedayPage(context)
        }
        val newPage = (currentPage + direction).coerceIn(0, maxPage)

        when (column) {
            COLUMN_TODAY -> WidgetSharedStore.saveTodayPage(context, newPage)
            else -> WidgetSharedStore.saveSomedayPage(context, newPage)
        }

        DoitdoWidgetProvider.updateAllWidgets(context)
    }
}
