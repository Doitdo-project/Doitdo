#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import ssl
import sys
import time
import traceback
import urllib.error
import urllib.parse
import urllib.request
import uuid
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import Any, Callable, Optional


DEV_BASE_URL = "https://168.107.48.80"
LOCAL_BASE_URL = "http://localhost:8080"


@dataclass
class Context:
    email: str
    username: str
    password: str
    new_password: str
    access_token: Optional[str] = None
    refresh_token: Optional[str] = None
    category_id: Optional[int] = None
    category_name: Optional[str] = None
    todo_id: Optional[int] = None
    user_character_id: Optional[int] = None
    device_token_id: Optional[int] = None
    fcm_token: Optional[str] = None
    notification_ids: list[int] = field(default_factory=list)
    user_item_id: Optional[int] = None


@dataclass
class StepResult:
    name: str
    method: str
    path: str
    status: Optional[int]
    elapsed_ms: int
    ok: bool = False
    skipped: bool = False
    note: str = ""
    error: str = ""
    response: Any = None


@dataclass
class Step:
    name: str
    method: str
    path: str
    fn: Callable[["Client", Context, "Step"], StepResult]
    label: str = ""


class Client:
    def __init__(self, base_url: str, verbose: bool, insecure: bool = False):
        self.base_url = base_url.rstrip("/")
        self.verbose = verbose
        self.insecure = insecure
        self.access_token: Optional[str] = None
        self.refresh_token: Optional[str] = None
        self.last_request: dict[str, Any] = {}
        self.last_response: dict[str, Any] = {}

    def set_token(self, access: Optional[str], refresh: Optional[str]) -> None:
        self.access_token = access
        self.refresh_token = refresh

    def request(
        self,
        method: str,
        path: str,
        *,
        json_body: Any = None,
        params: Optional[dict[str, Any]] = None,
        auth: bool = True,
    ) -> tuple[int, Any, int]:
        url = self.base_url + path
        if params:
            clean_params = {k: v for k, v in params.items() if v is not None}
            query = urllib.parse.urlencode(clean_params, doseq=True)
            if query:
                url = url + ("&" if "?" in url else "?") + query

        data = None
        headers = {"Accept": "application/json"}
        if json_body is not None:
            data = json.dumps(json_body).encode("utf-8")
            headers["Content-Type"] = "application/json"
        if auth and self.access_token:
            headers["Authorization"] = "Bearer " + self.access_token

        self.last_request = {
            "method": method,
            "url": url,
            "headers": self._redact_headers(headers),
            "body": json_body,
        }

        started = time.monotonic()
        status = 0
        raw = ""
        try:
            req = urllib.request.Request(url, data=data, headers=headers, method=method)
            if self.insecure:
                ctx = ssl.create_default_context()
                ctx.check_hostname = False
                ctx.verify_mode = ssl.CERT_NONE
                with urllib.request.urlopen(req, timeout=20, context=ctx) as resp:
                    status = resp.getcode()
                    raw = resp.read().decode("utf-8", errors="replace")
            else:
                with urllib.request.urlopen(req, timeout=20) as resp:
                    status = resp.getcode()
                    raw = resp.read().decode("utf-8", errors="replace")
        except urllib.error.HTTPError as exc:
            status = exc.code
            raw = exc.read().decode("utf-8", errors="replace")
        elapsed_ms = int((time.monotonic() - started) * 1000)

        body_obj = self._parse_body(raw)
        self.last_response = {"status": status, "body": body_obj, "raw": raw}
        return status, body_obj, elapsed_ms

    def _parse_body(self, raw: str) -> Any:
        if not raw:
            return None
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            return raw

    def _redact_headers(self, headers: dict[str, str]) -> dict[str, str]:
        redacted = dict(headers)
        if "Authorization" in redacted:
            redacted["Authorization"] = "Bearer <redacted>"
        return redacted


def data_of(body: Any) -> Any:
    if isinstance(body, dict) and "data" in body:
        return body.get("data")
    return body


def as_items(body: Any) -> list[Any]:
    data = data_of(body)
    if isinstance(data, dict) and isinstance(data.get("items"), list):
        return data["items"]
    return []


def expect_api(status: int, body: Any, expected: set[int]) -> tuple[bool, str]:
    if status not in expected:
        return False, "unexpected status"
    if isinstance(body, dict) and "status" in body and body.get("status") != status:
        return False, "response status mismatch"
    return True, ""


def request_step(
    client: Client,
    step: Step,
    ctx: Context,
    *,
    json_body: Any = None,
    params: Optional[dict[str, Any]] = None,
    auth: bool = True,
    expected: Optional[set[int]] = None,
    note: str = "",
    validator: Optional[Callable[[int, Any, Context], str]] = None,
    tolerated: Optional[set[int]] = None,
) -> StepResult:
    expected = expected or {200}
    tolerated = tolerated or set()
    status, body, elapsed_ms = client.request(
        step.method, step.path, json_body=json_body, params=params, auth=auth
    )

    ok, error = expect_api(status, body, expected)
    if not ok and status in tolerated:
        ok = True
        error = ""
        note = note or "precondition not met; reported only"
    if ok and validator:
        error = validator(status, body, ctx)
        ok = error == ""

    return StepResult(
        step.name,
        step.method,
        step.path,
        status,
        elapsed_ms,
        ok=ok,
        note=note,
        error=error,
        response=body,
    )


def skip(step: Step, reason: str) -> StepResult:
    return StepResult(
        step.name,
        step.method,
        step.path,
        None,
        0,
        ok=True,
        skipped=True,
        note=reason,
    )


def fail(step: Step, error: str, response: Any = None) -> StepResult:
    return StepResult(
        step.name,
        step.method,
        step.path,
        None,
        0,
        ok=False,
        error=error,
        response=response,
    )


def require_data_field(body: Any, field_name: str) -> Any:
    data = data_of(body)
    if not isinstance(data, dict) or data.get(field_name) is None:
        raise ValueError("missing data.%s" % field_name)
    return data[field_name]


def validate_available(expected_available: bool, label: str) -> Callable[[int, Any, Context], str]:
    def _validator(status: int, body: Any, ctx: Context) -> str:
        data = data_of(body)
        actual = data.get("available") if isinstance(data, dict) else None
        if actual is not expected_available:
            return "%s available expected %s got %s" % (label, expected_available, actual)
        return ""

    return _validator


def step_health(client: Client, ctx: Context, step: Step) -> StepResult:
    return request_step(client, step, ctx, auth=False, expected={200})


def step_signup(client: Client, ctx: Context, step: Step) -> StepResult:
    body = {"email": ctx.email, "password": ctx.password, "username": ctx.username}
    return request_step(client, step, ctx, json_body=body, auth=False, expected={201})


def step_check_email_duplicate(client: Client, ctx: Context, step: Step) -> StepResult:
    return request_step(
        client,
        step,
        ctx,
        params={"email": ctx.email},
        auth=False,
        expected={200},
        note="duplicate=true 검증 OK",
        validator=validate_available(False, "email duplicate"),
    )


def step_check_username_duplicate(client: Client, ctx: Context, step: Step) -> StepResult:
    return request_step(
        client,
        step,
        ctx,
        params={"username": ctx.username},
        auth=False,
        expected={200},
        note="duplicate=true 검증 OK",
        validator=validate_available(False, "username duplicate"),
    )


def step_check_email_available(client: Client, ctx: Context, step: Step) -> StepResult:
    fake = "e2e_available_%s@e2e.local" % uuid.uuid4().hex[:12]
    return request_step(
        client,
        step,
        ctx,
        params={"email": fake},
        auth=False,
        expected={200},
        note="available=true 검증 OK",
        validator=validate_available(True, "email available"),
    )


def step_check_username_available(client: Client, ctx: Context, step: Step) -> StepResult:
    fake = "e2e_available_%s" % uuid.uuid4().hex[:12]
    return request_step(
        client,
        step,
        ctx,
        params={"username": fake},
        auth=False,
        expected={200},
        note="available=true 검증 OK",
        validator=validate_available(True, "username available"),
    )


def step_login(client: Client, ctx: Context, step: Step) -> StepResult:
    body = {"username": ctx.username, "password": ctx.password}
    result = request_step(client, step, ctx, json_body=body, auth=False, expected={200})
    if result.ok:
        try:
            ctx.access_token = require_data_field(result.response, "accessToken")
            ctx.refresh_token = require_data_field(result.response, "refreshToken")
            client.set_token(ctx.access_token, ctx.refresh_token)
        except ValueError as exc:
            result.ok = False
            result.error = str(exc)
    return result


def step_me(client: Client, ctx: Context, step: Step) -> StepResult:
    return request_step(client, step, ctx, expected={200})


def step_change_password(client: Client, ctx: Context, step: Step) -> StepResult:
    body = {"currentPassword": ctx.password, "newPassword": ctx.new_password}
    result = request_step(client, step, ctx, json_body=body, expected={204})
    if result.ok:
        ctx.password = ctx.new_password
        client.set_token(None, None)
    return result


def step_relogin(client: Client, ctx: Context, step: Step) -> StepResult:
    body = {"username": ctx.username, "password": ctx.password}
    result = request_step(client, step, ctx, json_body=body, auth=False, expected={200})
    if result.ok:
        try:
            ctx.access_token = require_data_field(result.response, "accessToken")
            ctx.refresh_token = require_data_field(result.response, "refreshToken")
            client.set_token(ctx.access_token, ctx.refresh_token)
        except ValueError as exc:
            result.ok = False
            result.error = str(exc)
    return result


def step_refresh(client: Client, ctx: Context, step: Step) -> StepResult:
    if not ctx.refresh_token:
        return skip(step, "refreshToken 없음")
    body = {"refreshToken": ctx.refresh_token}
    result = request_step(client, step, ctx, json_body=body, auth=False, expected={200})
    if result.ok:
        try:
            ctx.access_token = require_data_field(result.response, "accessToken")
            ctx.refresh_token = require_data_field(result.response, "refreshToken")
            client.set_token(ctx.access_token, ctx.refresh_token)
        except ValueError as exc:
            result.ok = False
            result.error = str(exc)
    return result


def step_register_device_token(client: Client, ctx: Context, step: Step) -> StepResult:
    ctx.fcm_token = "e2e-fcm-%s" % uuid.uuid4().hex
    body = {"fcmToken": ctx.fcm_token, "platform": "ANDROID"}
    result = request_step(client, step, ctx, json_body=body, expected={201})
    if result.ok:
        try:
            ctx.device_token_id = require_data_field(result.response, "deviceTokenId")
        except ValueError as exc:
            result.ok = False
            result.error = str(exc)
    return result


def step_get_settings(client: Client, ctx: Context, step: Step) -> StepResult:
    return request_step(client, step, ctx, expected={200})


def step_patch_settings(client: Client, ctx: Context, step: Step) -> StepResult:
    body = {
        "dndEnabled": True,
        "dndStartTime": "22:00:00",
        "dndEndTime": "07:00:00",
        "morningReminderEnabled": True,
        "morningReminderTime": "08:30:00",
    }
    return request_step(client, step, ctx, json_body=body, expected={200})


def step_create_category(client: Client, ctx: Context, step: Step) -> StepResult:
    ctx.category_name = "e2e_cat_%s" % uuid.uuid4().hex[:8]
    body = {"name": ctx.category_name, "colorId": 6}
    result = request_step(client, step, ctx, json_body=body, expected={201})
    if result.ok:
        try:
            ctx.category_id = require_data_field(result.response, "categoryId")
        except ValueError as exc:
            result.ok = False
            result.error = str(exc)
    return result


def step_list_categories(client: Client, ctx: Context, step: Step) -> StepResult:
    def _validator(status: int, body: Any, context: Context) -> str:
        if context.category_id is None:
            return "categoryId 없음"
        ids = [item.get("categoryId") for item in as_items(body) if isinstance(item, dict)]
        if context.category_id not in ids:
            return "created category not found"
        return ""

    return request_step(
        client,
        step,
        ctx,
        expected={200},
        note="생성 카테고리 포함 검증 OK",
        validator=_validator,
    )


def step_patch_category(client: Client, ctx: Context, step: Step) -> StepResult:
    if ctx.category_id is None:
        return skip(step, "categoryId 없음")
    ctx.category_name = ctx.category_name + "_u" if ctx.category_name else "e2e_cat_u"
    return request_step(
        client,
        step,
        ctx,
        json_body={"name": ctx.category_name, "colorId": 7},
        expected={200},
    )


def step_encyclopedia(client: Client, ctx: Context, step: Step) -> StepResult:
    return request_step(client, step, ctx, expected={200})


def step_receive_egg(client: Client, ctx: Context, step: Step) -> StepResult:
    result = request_step(client, step, ctx, expected={200})
    if result.ok:
        try:
            ctx.user_character_id = require_data_field(result.response, "userCharacterId")
        except ValueError as exc:
            result.ok = False
            result.error = str(exc)
    return result


def step_current_character(client: Client, ctx: Context, step: Step) -> StepResult:
    result = request_step(client, step, ctx, expected={200})
    if result.ok and ctx.user_character_id is None:
        data = data_of(result.response)
        if isinstance(data, dict):
            ctx.user_character_id = data.get("userCharacterId")
    return result


def step_update_character_name(client: Client, ctx: Context, step: Step) -> StepResult:
    return request_step(
        client,
        step,
        ctx,
        json_body={"name": "e2e_%s" % uuid.uuid4().hex[:8]},
        expected={200},
    )


def step_hatch(client: Client, ctx: Context, step: Step) -> StepResult:
    return request_step(
        client,
        step,
        ctx,
        expected={200},
        tolerated={404, 422},
        note="전제 불만족 시 리포트만",
    )


def step_evolution(client: Client, ctx: Context, step: Step) -> StepResult:
    if ctx.user_character_id is None:
        return skip(step, "userCharacterId 없음")
    return request_step(
        client,
        step,
        ctx,
        expected={200},
        tolerated={404, 422},
        note="전제 불만족 시 리포트만",
    )


def step_create_todo(client: Client, ctx: Context, step: Step) -> StepResult:
    if not ctx.category_name:
        return skip(step, "categoryName 없음")
    today = datetime.now().date().isoformat()
    body = {
        "title": "e2e todo %s" % uuid.uuid4().hex[:8],
        "content": "created by stdlib e2e",
        "category": ctx.category_name,
        "type": "NORMAL",
        "startDate": today,
        "endDate": today,
        "priority": 2,
    }
    result = request_step(client, step, ctx, json_body=body, expected={201})
    if result.ok:
        try:
            ctx.todo_id = require_data_field(result.response, "todoId")
        except ValueError as exc:
            result.ok = False
            result.error = str(exc)
    return result


def step_list_todos(client: Client, ctx: Context, step: Step) -> StepResult:
    return request_step(client, step, ctx, expected={200})


def step_todo_detail(client: Client, ctx: Context, step: Step) -> StepResult:
    if ctx.todo_id is None:
        return skip(step, "todoId 없음")
    return request_step(client, step, ctx, expected={200})


def step_todo_search(client: Client, ctx: Context, step: Step) -> StepResult:
    return request_step(client, step, ctx, params={"q": "e2e"}, expected={200})


def step_todo_calendar(client: Client, ctx: Context, step: Step) -> StepResult:
    today = datetime.now().date()
    tomorrow = today + timedelta(days=1)
    return request_step(
        client,
        step,
        ctx,
        params={"from": today.isoformat(), "to": tomorrow.isoformat()},
        expected={200},
        note="source DTO 기준 from/to 사용",
    )


def step_patch_todo(client: Client, ctx: Context, step: Step) -> StepResult:
    if ctx.todo_id is None:
        return skip(step, "todoId 없음")
    body = {"title": "e2e todo updated", "content": "updated by stdlib e2e"}
    return request_step(client, step, ctx, json_body=body, expected={200})


def step_todo_status(client: Client, ctx: Context, step: Step) -> StepResult:
    if ctx.todo_id is None:
        return skip(step, "todoId 없음")
    return request_step(client, step, ctx, json_body={"status": "DONE"}, expected={200})


def step_todo_priority(client: Client, ctx: Context, step: Step) -> StepResult:
    if ctx.todo_id is None:
        return skip(step, "todoId 없음")
    return request_step(client, step, ctx, json_body={"priority": 5}, expected={200})


def step_todo_snooze(client: Client, ctx: Context, step: Step) -> StepResult:
    if ctx.todo_id is None:
        return skip(step, "todoId 없음")
    return request_step(client, step, ctx, json_body={}, expected={200})


def step_inventory(client: Client, ctx: Context, step: Step) -> StepResult:
    if ctx.user_character_id is None:
        return skip(step, "userCharacterId 없음")
    result = request_step(client, step, ctx, expected={200})
    if result.ok:
        for item in as_items(result.response):
            if isinstance(item, dict) and item.get("userItemId") is not None:
                ctx.user_item_id = item["userItemId"]
                break
    return result


def step_equip_item(client: Client, ctx: Context, step: Step) -> StepResult:
    if ctx.user_character_id is None:
        return skip(step, "userCharacterId 없음")
    if ctx.user_item_id is None:
        return skip(step, "보유 아이템 없음")
    return request_step(client, step, ctx, expected={200})


def step_unequip_item(client: Client, ctx: Context, step: Step) -> StepResult:
    if ctx.user_character_id is None:
        return skip(step, "userCharacterId 없음")
    if ctx.user_item_id is None:
        return skip(step, "장착 아이템 없음")
    return request_step(client, step, ctx, expected={200, 204})


def step_list_notifications(client: Client, ctx: Context, step: Step) -> StepResult:
    result = request_step(client, step, ctx, expected={200})
    if result.ok:
        seen = set(ctx.notification_ids)
        for item in as_items(result.response):
            if isinstance(item, dict) and item.get("notificationId") is not None:
                notification_id = item["notificationId"]
                if notification_id not in seen:
                    ctx.notification_ids.append(notification_id)
                    seen.add(notification_id)
    return result


def step_read_notification(client: Client, ctx: Context, step: Step) -> StepResult:
    if not ctx.notification_ids:
        return skip(step, "알림 없음")
    return request_step(client, step, ctx, expected={200})


def step_read_all_notifications(client: Client, ctx: Context, step: Step) -> StepResult:
    return request_step(client, step, ctx, expected={200})


def step_delete_notifications(client: Client, ctx: Context, step: Step) -> StepResult:
    if not ctx.notification_ids:
        return skip(step, "삭제할 알림 없음")
    elapsed_total = 0
    failures = []
    deleted = 0
    last_status: Optional[int] = None
    last_body: Any = None
    for notification_id in list(ctx.notification_ids):
        path = "/api/notifications/%s" % notification_id
        status, body, elapsed_ms = client.request("DELETE", path)
        elapsed_total += elapsed_ms
        last_status = status
        last_body = body
        if status in {200, 204, 404}:
            deleted += 1
        else:
            failures.append({"notificationId": notification_id, "status": status, "body": body})
    return StepResult(
        step.name,
        step.method,
        step.path,
        last_status,
        elapsed_total,
        ok=not failures,
        note="deleted %d/%d" % (deleted, len(ctx.notification_ids)),
        error="notification delete failures" if failures else "",
        response=failures or last_body,
    )


def step_delete_todo(client: Client, ctx: Context, step: Step) -> StepResult:
    if ctx.todo_id is None:
        return skip(step, "todoId 없음")
    return request_step(client, step, ctx, expected={200, 204, 404})


def step_delete_category(client: Client, ctx: Context, step: Step) -> StepResult:
    if ctx.category_id is None:
        return skip(step, "categoryId 없음")
    return request_step(client, step, ctx, expected={200, 204, 404})


def step_farewell(client: Client, ctx: Context, step: Step) -> StepResult:
    return request_step(
        client,
        step,
        ctx,
        json_body={"approved": True},
        expected={200},
        tolerated={404, 409, 422},
        note="성체가 아니면 cleanup 불가; 리포트만",
    )


def step_unregister_device_token(client: Client, ctx: Context, step: Step) -> StepResult:
    if not ctx.fcm_token:
        return skip(step, "fcmToken 없음")
    return request_step(
        client,
        step,
        ctx,
        json_body={"fcmToken": ctx.fcm_token},
        expected={200, 204, 404},
    )


def step_logout(client: Client, ctx: Context, step: Step) -> StepResult:
    if not client.access_token:
        return skip(step, "accessToken 없음")
    return request_step(client, step, ctx, expected={200, 204})


def bind_path(template: str, ctx: Context) -> str:
    path = template
    replacements = {
        "{categoryId}": ctx.category_id,
        "{todoId}": ctx.todo_id,
        "{userCharacterId}": ctx.user_character_id,
        "{userItemId}": ctx.user_item_id,
        "{notificationId}": ctx.notification_ids[0] if ctx.notification_ids else None,
    }
    for key, value in replacements.items():
        if value is not None:
            path = path.replace(key, str(value))
    return path


def wrap_dynamic_path(fn: Callable[[Client, Context, Step], StepResult]) -> Callable[[Client, Context, Step], StepResult]:
    def _wrapped(client: Client, ctx: Context, step: Step) -> StepResult:
        bound = Step(step.name, step.method, bind_path(step.path, ctx), step.fn, step.label)
        return fn(client, ctx, bound)

    return _wrapped


def build_steps() -> list[Step]:
    dyn = wrap_dynamic_path
    return [
        Step("Phase 0 health", "GET", "/db-check", step_health, "헬스체크"),
        Step("signup", "POST", "/api/auth/signup", step_signup, "회원 가입"),
        Step("check email duplicate", "GET", "/api/users/check-email", step_check_email_duplicate, "이메일 중복 확인"),
        Step("check username duplicate", "GET", "/api/users/check-username", step_check_username_duplicate, "닉네임 중복 확인"),
        Step("check email available", "GET", "/api/users/check-email", step_check_email_available, "이메일 사용 가능 확인"),
        Step("check username available", "GET", "/api/users/check-username", step_check_username_available, "닉네임 사용 가능 확인"),
        Step("login", "POST", "/api/auth/login", step_login, "로그인"),
        Step("me", "GET", "/api/users/me", step_me, "내 정보 조회"),
        Step("change password", "POST", "/api/users/me/password", step_change_password, "비밀번호 변경"),
        Step("relogin", "POST", "/api/auth/login", step_relogin, "재로그인"),
        Step("refresh", "POST", "/api/auth/refresh", step_refresh, "토큰 재발급"),
        Step("register device token", "POST", "/api/notifications/device-token", step_register_device_token, "디바이스 토큰 등록"),
        Step("get settings", "GET", "/api/settings", step_get_settings, "설정 조회"),
        Step("patch settings", "PATCH", "/api/settings", step_patch_settings, "설정 수정"),
        Step("create category", "POST", "/api/categories", step_create_category, "카테고리 생성"),
        Step("list categories", "GET", "/api/categories", step_list_categories, "카테고리 목록 조회"),
        Step("patch category", "PATCH", "/api/categories/{categoryId}", dyn(step_patch_category), "카테고리 수정"),
        Step("encyclopedia", "GET", "/api/characters/encyclopedia", step_encyclopedia, "도감 조회"),
        Step("receive egg", "POST", "/api/characters/me/egg", step_receive_egg, "알 받기"),
        Step("current character", "GET", "/api/characters/me", step_current_character, "현재 캐릭터 조회"),
        Step("update character name", "PATCH", "/api/characters/me/name", step_update_character_name, "캐릭터 이름 변경"),
        Step("hatch", "POST", "/api/characters/me/hatch", step_hatch, "부화"),
        Step("evolution", "POST", "/api/characters/{userCharacterId}/evolution", dyn(step_evolution), "진화"),
        Step("create todo", "POST", "/api/todos", step_create_todo, "TODO 생성"),
        Step("list todos", "GET", "/api/todos", step_list_todos, "TODO 목록 조회"),
        Step("todo detail", "GET", "/api/todos/{todoId}", dyn(step_todo_detail), "TODO 상세 조회"),
        Step("todo search", "GET", "/api/todos/search", step_todo_search, "TODO 검색"),
        Step("todo calendar", "GET", "/api/todos/calendar", step_todo_calendar, "TODO 캘린더 조회"),
        Step("patch todo", "PATCH", "/api/todos/{todoId}", dyn(step_patch_todo), "TODO 수정"),
        Step("todo status", "PATCH", "/api/todos/{todoId}/status", dyn(step_todo_status), "TODO 상태 변경"),
        Step("todo priority", "PATCH", "/api/todos/{todoId}/priority", dyn(step_todo_priority), "TODO 우선순위 변경"),
        Step("todo snooze", "POST", "/api/todos/{todoId}/snooze", dyn(step_todo_snooze), "TODO 미루기"),
        Step("inventory", "GET", "/api/tamagotchis/{userCharacterId}/inventory", dyn(step_inventory), "인벤토리 조회"),
        Step("equip item", "POST", "/api/tamagotchis/{userCharacterId}/items/{userItemId}", dyn(step_equip_item), "아이템 장착"),
        Step("unequip item", "DELETE", "/api/tamagotchis/{userCharacterId}/items/{userItemId}", dyn(step_unequip_item), "아이템 해제"),
        Step("list notifications", "GET", "/api/notifications", step_list_notifications, "알림 목록 조회"),
        Step("read notification", "PATCH", "/api/notifications/{notificationId}/read", dyn(step_read_notification), "알림 읽음 처리"),
        Step("read all notifications", "PATCH", "/api/notifications/read-all", step_read_all_notifications, "알림 전체 읽음"),
        Step("cleanup notifications", "DELETE", "/api/notifications/{id}", step_delete_notifications, "알림 삭제"),
        Step("cleanup todo", "DELETE", "/api/todos/{todoId}", dyn(step_delete_todo), "TODO 삭제"),
        Step("cleanup category", "DELETE", "/api/categories/{categoryId}", dyn(step_delete_category), "카테고리 삭제"),
        Step("cleanup farewell", "POST", "/api/characters/me/farewell", step_farewell, "캐릭터 이별"),
        Step("cleanup device token", "DELETE", "/api/notifications/device-token", step_unregister_device_token, "디바이스 토큰 해제"),
        Step("logout", "DELETE", "/api/auth/logout", step_logout, "로그아웃"),
    ]


def run_step(index: int, total: int, step: Step, client: Client, ctx: Context) -> StepResult:
    try:
        result = step.fn(client, ctx, step)
    except Exception as exc:
        result = fail(step, str(exc), traceback.format_exc() if client.verbose else None)
    print_step(index, total, result, client.verbose, client, step.label)
    return result


def format_response(response: Any) -> str:
    if response is None:
        return ""
    if isinstance(response, str):
        return response
    return json.dumps(response, ensure_ascii=False, separators=(",", ":"))


def print_step(index: int, total: int, result: StepResult, verbose: bool, client: Client, label: str = "") -> None:
    display_label = label if label else result.name

    print("[%2d]" % index)
    print("--%s 진행--" % display_label)

    if result.skipped:
        state = "스킵"
        note_suffix = " (%s)" % result.note if result.note else ""
        print("--%s %s--%s" % (display_label, state, note_suffix))
    elif result.ok:
        state = "완료"
        note_suffix = " (%s)" % result.note if result.note else ""
        print("--%s %s--%s" % (display_label, state, note_suffix))
    else:
        state = "실패"
        print("--%s %s--" % (display_label, state))
        status_str = "-" if result.status is None else str(result.status)
        elapsed_str = "%dms" % result.elapsed_ms if result.elapsed_ms else "0ms"
        print("  status=%s error=%s [%s]" % (status_str, result.error, elapsed_str))

    if verbose:
        req = client.last_request
        resp = client.last_response
        if req:
            print("         ├─ request: %s %s" % (req.get("method"), req.get("url")))
            print("         │  headers: %s" % format_response(req.get("headers")))
            print("         │  body: %s" % format_response(req.get("body")))
        if resp:
            print("         └─ response: %s" % format_response(resp.get("body")))
    elif not result.ok and not result.skipped:
        if result.error:
            print("         ├─ error: %s" % result.error)
        if result.response is not None:
            print("         └─ response: %s" % format_response(result.response))

    print("")


def print_summary(results: list[StepResult], ctx: Context, total_seconds: float) -> None:
    passed = sum(1 for r in results if r.ok and not r.skipped)
    skipped = sum(1 for r in results if r.skipped)
    failed = sum(1 for r in results if not r.ok and not r.skipped)
    print(
        "Passed %d/%d  Failed %d  Skipped %d  Total %.1fs"
        % (passed, len(results), failed, skipped, total_seconds)
    )
    failures = [r for r in results if not r.ok and not r.skipped]
    if failures:
        print("Failures:")
        for result in failures:
            status = "-" if result.status is None else str(result.status)
            print("  - %s %s status=%s error=%s" % (result.method, result.path, status, result.error))
    print("⚠ 테스트 계정 %s DB 잔존" % ctx.email)


def all_passed(results: list[StepResult]) -> bool:
    return all(r.ok for r in results)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Doitdo stdlib-only E2E smoke flow")
    parser.add_argument("--local", action="store_true", help="use http://localhost:8080")
    parser.add_argument("--base-url", help="override target base URL")
    parser.add_argument("-v", "--verbose", action="store_true", help="dump raw request/response per step")
    parser.add_argument("--insecure", action="store_true", default=False, help="skip SSL certificate verification (self-signed dev cert)")
    return parser.parse_args()


def resolve_base_url(args: argparse.Namespace) -> str:
    if args.base_url:
        return args.base_url
    if args.local:
        return LOCAL_BASE_URL
    return DEV_BASE_URL


def make_context() -> Context:
    ts = datetime.now().strftime("%Y%m%d%H%M%S")
    suffix = uuid.uuid4().hex[:6]
    username = "e2e_%s_%s" % (ts, suffix)
    return Context(
        email="e2e_%s_%s@e2e.local" % (ts, suffix),
        username=username,
        password="E2ePass!%s" % suffix,
        new_password="E2ePass2!%s" % suffix,
    )


def main() -> int:
    args = parse_args()
    client = Client(resolve_base_url(args), args.verbose, args.insecure)
    ctx = make_context()
    steps = build_steps()
    results: list[StepResult] = []
    started = time.monotonic()

    if args.verbose:
        print("base_url=%s  insecure=%s" % (client.base_url, client.insecure))
        print("cwd=%s" % os.getcwd())

    for index, step in enumerate(steps, start=1):
        result = run_step(index, len(steps), step, client, ctx)
        results.append(result)
        if index == 1 and not result.ok:
            break

    print("=" * 60)
    print_summary(results, ctx, time.monotonic() - started)
    return 0 if all_passed(results) else 1


if __name__ == "__main__":
    sys.exit(main())
