package com.d107.doitdo.widget

import android.content.Context
import android.util.Log
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.util.concurrent.TimeUnit

/**
 * 위젯 백그라운드 컨텍스트(BroadcastReceiver) 에서 doitdo 백엔드를 직접 호출.
 *
 * iOS `WidgetApiClient` 와 동등 — 401 → refresh → retry 1회 동작.
 *
 * Dart Dio 와 다음 두 가지가 다름:
 * - 백그라운드라 사용자에게 토스트/스낵바 띄울 수 없으므로 실패 시 throw 만 하고
 *   호출자(BroadcastReceiver) 가 silent 로 흡수
 * - 위젯이 갖는 토큰은 SharedPreferences 에 저장된 것 (마지막 앱 동기화 시점값)
 *
 * 모든 호출은 동기. 호출자는 `goAsync()` + 별도 Thread 로 감싼다.
 *
 * ─── PATCH 우회 히스토리 ───────────────────────────────────────────────
 * 초창기엔 `HttpURLConnection.method` 필드를 reflection 으로 강제 주입해 PATCH 를
 * 흉내냈지만, Android 12+ 에선 SDK 제한으로 set 이 silent 무시되는 경우가 있다
 * (예외도 안 나서 fallback 분기조차 못 탐). 결과적으로 BE 에 POST 가 도달해 500
 * 응답을 받는 사례 발생 → OkHttp 의 정식 PATCH 로 교체. 의존성 한 줄 부담 대비
 * 안정성 확보.
 */
object WidgetApiClient {
    private const val TAG = "WidgetApiClient"

    private val JSON = "application/json".toMediaType()

    // OkHttpClient 는 thread-safe + 내부에 connection pool 을 가지므로 싱글톤이 정석.
    // 위젯 receiver 는 짧게 살았다 죽으므로 lazy 로 첫 사용 시점에만 초기화.
    private val client: OkHttpClient by lazy {
        OkHttpClient.Builder()
            .connectTimeout(10, TimeUnit.SECONDS)
            .readTimeout(10, TimeUnit.SECONDS)
            .writeTimeout(10, TimeUnit.SECONDS)
            .build()
    }

    sealed class WidgetApiException(message: String) : Exception(message) {
        object NoTokens : WidgetApiException("토큰 없음")
        object NoBaseUrl : WidgetApiException("baseUrl 없음")
        object Unauthorized : WidgetApiException("refresh 까지 실패")
        class Server(val statusCode: Int) : WidgetApiException("server $statusCode")
        class Network(cause: Throwable) : WidgetApiException(cause.message ?: "network")
        object Decode : WidgetApiException("응답 파싱 실패")
    }

    /**
     * PATCH /api/todos/{todoId}/status
     *
     * @param newStatus "DONE" 또는 "TODO" — BE enum 값
     */
    fun changeTodoStatus(context: Context, todoId: Int, newStatus: String) {
        val baseUrl = WidgetSharedStore.apiBaseUrl(context)
            ?: throw WidgetApiException.NoBaseUrl
        val access = WidgetSharedStore.accessToken(context)
            ?: throw WidgetApiException.NoTokens

        val url = "$baseUrl/api/todos/$todoId/status"
        val body = JSONObject().put("status", newStatus).toString()

        try {
            patchStatus(url, body, access)
        } catch (e: WidgetApiException.Unauthorized) {
            // 401 → refresh 1회 → 재호출.
            try {
                val refreshed = refreshAccessToken(context)
                patchStatus(url, body, refreshed)
            } catch (e2: WidgetApiException.Unauthorized) {
                // refresh token도 만료 → 토큰 초기화 후 위젯에 로그인 필요 표시.
                Log.w(TAG, "토큰 전체 만료 → SharedPreferences 토큰 초기화")
                WidgetSharedStore.clearTokens(context)
                DoitdoWidgetProvider.updateAllWidgets(context)
                throw e2
            }
        }
    }

    private fun patchStatus(urlString: String, body: String, accessToken: String) {
        val request = Request.Builder()
            .url(urlString)
            .patch(body.toRequestBody(JSON))
            .header("Authorization", "Bearer $accessToken")
            .build()
        try {
            client.newCall(request).execute().use { response ->
                val code = response.code
                when {
                    response.isSuccessful -> return
                    code == 401 -> throw WidgetApiException.Unauthorized
                    else -> {
                        val errBody = response.body?.string()
                        Log.w(
                            TAG,
                            "PATCH $urlString → $code body=$body resp=$errBody",
                        )
                        throw WidgetApiException.Server(code)
                    }
                }
            }
        } catch (e: WidgetApiException) {
            throw e
        } catch (e: Exception) {
            throw WidgetApiException.Network(e)
        }
    }

    /**
     * POST /api/auth/refresh
     * 성공 시 새 access/refresh 를 SharedPreferences 에도 갱신 저장하고 access 반환.
     */
    private fun refreshAccessToken(context: Context): String {
        val baseUrl = WidgetSharedStore.apiBaseUrl(context)
            ?: throw WidgetApiException.NoBaseUrl
        val refresh = WidgetSharedStore.refreshToken(context)
            ?: throw WidgetApiException.Unauthorized

        val url = "$baseUrl/api/auth/refresh"
        val body = JSONObject().put("refreshToken", refresh).toString()

        val request = Request.Builder()
            .url(url)
            .post(body.toRequestBody(JSON))
            .build()
        try {
            client.newCall(request).execute().use { response ->
                if (!response.isSuccessful) {
                    Log.w(TAG, "refresh 응답 실패: ${response.code}")
                    throw WidgetApiException.Unauthorized
                }

                val raw = response.body?.string() ?: throw WidgetApiException.Decode
                // envelope.data = { accessToken, refreshToken }
                val data = JSONObject(raw).optJSONObject("data")
                    ?: throw WidgetApiException.Decode
                val newAccess = data.optString("accessToken").takeIf { it.isNotEmpty() }
                    ?: throw WidgetApiException.Decode
                val newRefresh = data.optString("refreshToken").takeIf { it.isNotEmpty() }
                    ?: throw WidgetApiException.Decode

                WidgetSharedStore.updateAccessToken(context, newAccess)
                WidgetSharedStore.updateRefreshToken(context, newRefresh)
                return newAccess
            }
        } catch (e: WidgetApiException) {
            throw e
        } catch (e: Exception) {
            throw WidgetApiException.Network(e)
        }
    }
}
