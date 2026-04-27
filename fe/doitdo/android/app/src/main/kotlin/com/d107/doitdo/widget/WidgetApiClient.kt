package com.d107.doitdo.widget

import android.content.Context
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL

/**
 * 위젯 백그라운드 컨텍스트(BroadcastReceiver) 에서 doitdo 백엔드를 직접 호출.
 *
 * iOS `WidgetApiClient` 와 동등 — 단순한 401 → refresh → retry 1회 동작.
 * 위젯 extension 은 사용자에게 UI 피드백을 줄 수 없으므로 실패해도 throw 만 하고
 * 호출자가 silent 처리한다.
 *
 * Dart Dio 와는 다음 두 가지가 다름:
 * - 백그라운드라 사용자 알림 없이 조용히 실패 가능 → 실패 시 예외만 던지고 끝
 * - 위젯이 갖는 토큰은 SharedPreferences 에 저장된 것 (마지막 앱 동기화 시점값)
 *
 * 모든 호출은 동기. 호출자(BroadcastReceiver)는 `goAsync()` + 별도 Thread 로 감싼다.
 */
object WidgetApiClient {
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
            // 401 → refresh 1회 → 재호출
            val refreshed = refreshAccessToken(context)
            patchStatus(url, body, refreshed)
        }
    }

    private fun patchStatus(urlString: String, body: String, accessToken: String) {
        val conn = (URL(urlString).openConnection() as HttpURLConnection).apply {
            // HttpURLConnection 은 PATCH 를 정식 지원하지 않아 (Java 11 이전) X-HTTP-Method-Override
            // 헤더 + POST 로 우회하는 방법이 표준. 단, OkHttp/Dio 와 동일한 진짜 PATCH 가 BE 라우트
            // 매칭에 필요하므로 reflection 으로 method 강제 주입.
            requestMethod = "POST"
            setRequestMethodViaReflection(this, "PATCH")
            doOutput = true
            connectTimeout = 10_000
            readTimeout = 10_000
            setRequestProperty("Content-Type", "application/json")
            setRequestProperty("Authorization", "Bearer $accessToken")
        }
        try {
            OutputStreamWriter(conn.outputStream, Charsets.UTF_8).use { it.write(body) }
            val code = conn.responseCode
            when {
                code in 200..299 -> return
                code == 401 -> throw WidgetApiException.Unauthorized
                else -> throw WidgetApiException.Server(code)
            }
        } catch (e: WidgetApiException) {
            throw e
        } catch (e: Exception) {
            throw WidgetApiException.Network(e)
        } finally {
            conn.disconnect()
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

        val conn = (URL(url).openConnection() as HttpURLConnection).apply {
            requestMethod = "POST"
            doOutput = true
            connectTimeout = 10_000
            readTimeout = 10_000
            setRequestProperty("Content-Type", "application/json")
        }
        try {
            OutputStreamWriter(conn.outputStream, Charsets.UTF_8).use { it.write(body) }
            val code = conn.responseCode
            if (code !in 200..299) throw WidgetApiException.Unauthorized

            val raw = BufferedReader(InputStreamReader(conn.inputStream, Charsets.UTF_8)).use {
                it.readText()
            }
            // envelope.data = { accessToken, refreshToken }
            val data = JSONObject(raw).optJSONObject("data") ?: throw WidgetApiException.Decode
            val newAccess = data.optString("accessToken").takeIf { it.isNotEmpty() }
                ?: throw WidgetApiException.Decode
            val newRefresh = data.optString("refreshToken").takeIf { it.isNotEmpty() }
                ?: throw WidgetApiException.Decode

            WidgetSharedStore.updateAccessToken(context, newAccess)
            WidgetSharedStore.updateRefreshToken(context, newRefresh)
            return newAccess
        } catch (e: WidgetApiException) {
            throw e
        } catch (e: Exception) {
            throw WidgetApiException.Network(e)
        } finally {
            conn.disconnect()
        }
    }

    /**
     * HttpURLConnection 은 method 화이트리스트가 하드코딩돼 있어 PATCH 를 거부한다.
     * reflection 으로 내부 `method` 필드를 직접 set — 모든 안드로이드 버전에서 검증된 우회법.
     */
    private fun setRequestMethodViaReflection(conn: HttpURLConnection, method: String) {
        try {
            val field = HttpURLConnection::class.java.getDeclaredField("method")
            field.isAccessible = true
            field.set(conn, method)
        } catch (_: Exception) {
            // reflection 실패 시 POST 로 폴백 — BE 라우트가 PATCH 만 받으면 405 나는데
            // 그건 그때 server() 예외로 떨어져 호출자가 무시한다.
        }
    }
}
