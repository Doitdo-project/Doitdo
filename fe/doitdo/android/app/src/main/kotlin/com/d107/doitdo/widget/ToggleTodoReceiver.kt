package com.d107.doitdo.widget

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * 위젯 체크박스 탭 → 백엔드 PATCH + 로컬 payload 갱신 + 위젯 재렌더.
 *
 * iOS `ToggleTodoIntent` 와 동등 역할. AppWidgetProvider 의 RemoteViews 에서
 * `setOnClickPendingIntent(checkBox, getBroadcast(...))` 로 trigger 된다.
 *
 * 백그라운드라 사용자에게 토스트 띄우는 수단이 없어 실패는 silent — 다음 timeline
 * 또는 앱 진입 시 정합성 회복.
 */
class ToggleTodoReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_TOGGLE = "com.d107.doitdo.widget.ACTION_TOGGLE_TODO"
        const val EXTRA_TODO_ID = "todoId"
        private const val TAG = "ToggleTodoReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_TOGGLE) return
        val todoId = intent.getIntExtra(EXTRA_TODO_ID, -1)
        if (todoId == -1) return

        // BroadcastReceiver 의 onReceive 는 main thread + 짧은 시간(약 10s) 안에 끝나야
        // 한다. 네트워크/디스크 I/O 는 goAsync() 로 백그라운드 스레드 양보 후 처리.
        val pending = goAsync()
        Thread {
            try {
                handleToggle(context, todoId)
            } catch (e: Exception) {
                Log.w(TAG, "toggle 처리 실패 todoId=$todoId", e)
            } finally {
                pending.finish()
            }
        }.start()
    }

    private fun handleToggle(context: Context, todoId: Int) {
        // 1. 현재 payload 에서 해당 TODO 의 상태 반대값 결정.
        val payload = WidgetSharedStore.payload(context) ?: return
        val target = (payload.todayTodos + payload.somedayTodos)
            .firstOrNull { it.id == todoId } ?: return
        val nextStatus = if (target.isDone) "TODO" else "DONE"
        val nextIsDone = !target.isDone

        // 2. 로컬 payload 즉시 반영 (낙관적 갱신) — 사용자 체감 반응 빠르게.
        val updated = payload.copy(
            todayTodos = payload.todayTodos.map {
                if (it.id == todoId) it.copy(isDone = nextIsDone) else it
            },
            somedayTodos = payload.somedayTodos.map {
                if (it.id == todoId) it.copy(isDone = nextIsDone) else it
            },
        )
        WidgetSharedStore.savePayload(context, updated)

        // 3. 위젯 재렌더 — payload 만 바꾸고 reload 안 하면 다음 OS 갱신까지 옛 상태.
        reloadAllWidgets(context)

        // 4. 백엔드 PATCH (실패해도 silent — 다음 syncTodos 호출에서 정합성 회복).
        try {
            WidgetApiClient.changeTodoStatus(context, todoId, nextStatus)
        } catch (e: Exception) {
            Log.w(TAG, "PATCH 실패 todoId=$todoId (silent)", e)
        }
    }

    private fun reloadAllWidgets(context: Context) {
        val mgr = AppWidgetManager.getInstance(context)
        val component = ComponentName(context, DoitdoWidgetProvider::class.java)
        val ids = mgr.getAppWidgetIds(component)
        if (ids.isEmpty()) return
        val intent = Intent(context, DoitdoWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        }
        context.sendBroadcast(intent)
    }
}
