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
        // DONE 으로 토글된 항목이 사라지기 전에 "체크된 모습" 으로 노출되는 시간(ms).
        // goAsync() 가 부여하는 receiver 처리 한도(약 10s) 안에서 충분히 짧게.
        private const val FADE_DURATION_MS = 600L
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

        // 3. Stage 1 — DONE 으로 토글된 경우 잠깐 fading 마크. provider 가 done 이지만
        //    이 항목만 예외적으로 노출 + 채워진 원 + 취소선 으로 그린다 ("체크된 모습" 보여주기).
        //    TODO 로 되돌리는 경우엔 fading 불필요 (다시 빈 원으로 복귀).
        if (nextIsDone) {
            WidgetSharedStore.markFadingTodo(context, todoId)
        } else {
            WidgetSharedStore.clearFadingTodo(context)
        }
        reloadAllWidgets(context)

        // 4. 백엔드 PATCH (실패해도 silent — 다음 syncTodos 호출에서 정합성 회복).
        val patchStart = System.currentTimeMillis()
        try {
            WidgetApiClient.changeTodoStatus(context, todoId, nextStatus)
        } catch (e: Exception) {
            Log.w(TAG, "PATCH 실패 todoId=$todoId (silent)", e)
        }

        // 5. Stage 2 — DONE 토글이었다면 최소 FADE_DURATION_MS 동안 체크된 모습을 유지한 뒤
        //    fading 해제 + 재렌더. 이 시점에서 done 항목은 일반 필터에 의해 사라진다.
        //    PATCH 응답 시간이 이미 길었으면 추가 sleep 없이 즉시 사라지게.
        if (nextIsDone) {
            val elapsed = System.currentTimeMillis() - patchStart
            val remaining = FADE_DURATION_MS - elapsed
            if (remaining > 0) {
                try { Thread.sleep(remaining) } catch (_: InterruptedException) {}
            }
            WidgetSharedStore.clearFadingTodo(context)
            reloadAllWidgets(context)
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
