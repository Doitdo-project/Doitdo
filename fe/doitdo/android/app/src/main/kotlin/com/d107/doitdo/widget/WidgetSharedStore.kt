package com.d107.doitdo.widget

import android.content.Context
import android.content.SharedPreferences

/**
 * Flutter 앱 ↔ AppWidget 간 데이터 공유 추상화.
 *
 * `home_widget` 패키지(0.7.x)는 Android 측에서 키-값을 그대로 SharedPreferences
 * `${packageName}.HomeWidgetPreferences` 에 저장한다 (prefix 없음). 위젯에서도
 * 동일한 raw key 로 읽으면 된다.
 *
 * 모든 키 상수는 Dart 의 `WidgetSyncService._keyXxx` 와 1:1 일치 — 변경 시
 * 양쪽 동기화 필수.
 */
object WidgetSharedStore {
    private const val PREFS_NAME = "com.d107.doitdo.HomeWidgetPreferences"

    // Dart `WidgetSyncService` 의 _keyXxx 와 동일.
    const val KEY_PAYLOAD = "doitdo.widget.payload"
    const val KEY_ACCESS_TOKEN = "doitdo.widget.accessToken"
    const val KEY_REFRESH_TOKEN = "doitdo.widget.refreshToken"
    const val KEY_API_BASE_URL = "doitdo.widget.apiBaseUrl"

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    private fun nonEmpty(value: String?): String? =
        if (value.isNullOrEmpty()) null else value

    fun payload(context: Context): WidgetPayload? {
        val raw = nonEmpty(prefs(context).getString(KEY_PAYLOAD, null)) ?: return null
        return WidgetPayload.fromJsonString(raw)
    }

    fun savePayload(context: Context, payload: WidgetPayload) {
        prefs(context).edit().putString(KEY_PAYLOAD, payload.toJson().toString()).apply()
    }

    fun accessToken(context: Context): String? =
        nonEmpty(prefs(context).getString(KEY_ACCESS_TOKEN, null))

    fun refreshToken(context: Context): String? =
        nonEmpty(prefs(context).getString(KEY_REFRESH_TOKEN, null))

    fun apiBaseUrl(context: Context): String? =
        nonEmpty(prefs(context).getString(KEY_API_BASE_URL, null))

    fun updateAccessToken(context: Context, token: String) {
        prefs(context).edit().putString(KEY_ACCESS_TOKEN, token).apply()
    }

    fun updateRefreshToken(context: Context, token: String) {
        prefs(context).edit().putString(KEY_REFRESH_TOKEN, token).apply()
    }
}
