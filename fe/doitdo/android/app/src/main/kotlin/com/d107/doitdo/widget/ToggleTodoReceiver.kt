package com.d107.doitdo.widget

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * 위젯 체크박스 탭 → 백엔드 PATCH + 로컬 payload 갱신 + 위젯 재렌더.
 *
 * 2단계:
 *  T=0ms    partiallyUpdateAppWidget — 해당 행 체크 아이콘/색상만 교체 (full redraw 없음, 깜빡임 없음)
 *  T=400ms  updateAppWidget          — done 항목 제거 후 full redraw
 */
class ToggleTodoReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_TOGGLE = "com.d107.doitdo.widget.ACTION_TOGGLE_TODO"
        const val EXTRA_TODO_ID = "todoId"
        private const val TAG = "ToggleTodoReceiver"
        private const val REMOVE_DELAY_MS = 400L
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_TOGGLE) return
        val todoId = intent.getIntExtra(EXTRA_TODO_ID, -1)
        if (todoId == -1) return

        val payload = WidgetSharedStore.payload(context) ?: return
        val target = (payload.todayTodos + payload.somedayTodos)
            .firstOrNull { it.id == todoId } ?: return

        if (target.isDone) return

        val appContext = context.applicationContext

        val updated = payload.copy(
            todayTodos = payload.todayTodos.map {
                if (it.id == todoId) it.copy(isDone = true) else it
            },
            somedayTodos = payload.somedayTodos.map {
                if (it.id == todoId) it.copy(isDone = true) else it
            },
        )

        val pending = goAsync()

        // 애니메이션 스레드
        Thread {
            // Phase 1: payload 저장 + 해당 행만 부분 업데이트 (체크 아이콘, 글자색).
            WidgetSharedStore.savePayload(appContext, updated)
            DoitdoWidgetProvider.partiallyUpdateCheckState(appContext, todoId, payload)

            // Phase 2: 400ms 후 full redraw → done 항목 자동 제거.
            Thread.sleep(REMOVE_DELAY_MS)
            DoitdoWidgetProvider.updateAllWidgets(appContext)
        }.start()

        // PATCH 스레드
        Thread {
            try {
                WidgetApiClient.changeTodoStatus(appContext, todoId, "DONE")
            } catch (e: Exception) {
                Log.w(TAG, "PATCH 실패 todoId=$todoId (silent)", e)
            } finally {
                pending.finish()
            }
        }.start()
    }
}
