package com.d107.doitdo.widget

import org.json.JSONArray
import org.json.JSONObject

/**
 * 홈스크린 위젯이 표시할 TODO 1 건의 최소 정보.
 *
 * Dart `WidgetTodoDto` / iOS `WidgetTodo` 와 1:1 동일한 JSON 키 — 변경 시 양쪽 동기화 필수.
 */
data class WidgetTodo(
    val id: Int,
    val title: String,
    val isDone: Boolean,
    val isSomeday: Boolean,
) {
    fun toJson(): JSONObject = JSONObject().apply {
        put("id", id)
        put("title", title)
        put("isDone", isDone)
        put("isSomeday", isSomeday)
    }

    companion object {
        fun fromJson(o: JSONObject): WidgetTodo = WidgetTodo(
            id = o.getInt("id"),
            title = o.getString("title"),
            isDone = o.getBoolean("isDone"),
            isSomeday = o.getBoolean("isSomeday"),
        )
    }
}

/**
 * 위젯에 보내는 페이로드 전체.
 *
 * 오늘 + SOMEDAY 두 섹션 + 마지막 갱신 시각(위젯에선 표시 X, 디버깅용으로만 보존).
 * Dart `WidgetPayload` / iOS `WidgetPayload` 와 동일 스키마.
 */
data class WidgetPayload(
    val todayTodos: List<WidgetTodo>,
    val somedayTodos: List<WidgetTodo>,
    val updatedAt: String,
) {
    fun toJson(): JSONObject = JSONObject().apply {
        put("todayTodos", JSONArray().apply { todayTodos.forEach { put(it.toJson()) } })
        put("somedayTodos", JSONArray().apply { somedayTodos.forEach { put(it.toJson()) } })
        put("updatedAt", updatedAt)
    }

    companion object {
        fun fromJsonString(raw: String): WidgetPayload? = try {
            val o = JSONObject(raw)
            WidgetPayload(
                todayTodos = o.getJSONArray("todayTodos").toWidgetTodos(),
                somedayTodos = o.getJSONArray("somedayTodos").toWidgetTodos(),
                updatedAt = o.optString("updatedAt", ""),
            )
        } catch (e: Exception) {
            null
        }

        private fun JSONArray.toWidgetTodos(): List<WidgetTodo> =
            (0 until length()).map { WidgetTodo.fromJson(getJSONObject(it)) }
    }
}
