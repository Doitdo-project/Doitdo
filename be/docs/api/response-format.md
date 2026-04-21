# 응답 포맷 — `GlobalApiResponse<T>`

위치: `com.doitdo.global.api.response.GlobalApiResponse`

모든 컨트롤러 응답은 이 객체로 감싸 반환한다. (성공/실패 모두)

## 1. 필드

| 필드 | 타입 | 직렬화 순서 | 비고 |
|---|---|---|---|
| `status` | `int` | 1 | HTTP status (예: `200`) |
| `code` | `String` | 2 | 에러 코드 (예: `"A00-001"`). 성공 응답에서는 `null` → JSON 에서 생략 |
| `message` | `String` | 3 | 사람이 읽는 메시지 |
| `data` | `T` | 4 | 응답 페이로드 (실패 시 보통 `null`) |

`@JsonPropertyOrder({"status", "code", "message", "data"})` 로 직렬화 순서가 고정된다.
`code` 는 `@JsonInclude(NON_NULL)` 로 값이 있을 때만 직렬화된다.

## 2. 정적 팩토리 — 성공

```java
GlobalApiResponse.ok(data)                  // 200 OK + "OK" 메시지
GlobalApiResponse.ok("로그인 성공", data)    // 200 OK + 메시지 지정
GlobalApiResponse.created("생성 완료", data) // 201 Created
GlobalApiResponse.noContent("삭제 완료")     // 204 No Content (data=null)
GlobalApiResponse.of(httpStatus, message, data) // 그 외 status
```

## 3. 정적 팩토리 — 실패

```java
GlobalApiResponse.fail(errorCode)                          // ErrorCode.getDefaultMessage() 사용
GlobalApiResponse.fail(errorCode, "override 메시지")        // 메시지 덮어쓰기
GlobalApiResponse.fail(httpStatus, code, message)           // 수동 지정
GlobalApiResponse.fail(httpStatus, message)                 // 호환 — code 없이 사용 (지양)
```

`fail(ErrorCode)` 호출 시 `status / code / message` 가 `ErrorCode` 에서 자동 계산된다 — **이 형태 사용을 권장**.

## 4. 컨트롤러 사용 예

```java
@PostMapping("/login")
public GlobalApiResponse<LoginResp> login(@Valid @RequestBody LoginReq req) {
    return GlobalApiResponse.ok(authService.login(req));
}
```

실패 응답은 보통 컨트롤러에서 직접 반환하지 않고, `CustomException` 을 던지면 `GlobalExceptionHandler` 가 `GlobalApiResponse.fail(errorCode)` 형태로 변환한다.

## 5. JSON 예시

성공:

```json
{
  "status": 200,
  "message": "OK",
  "data": { "userId": 1, "email": "user@example.com" }
}
```

실패:

```json
{
  "status": 401,
  "code": "A00-001",
  "message": "아이디 또는 비밀번호가 올바르지 않습니다."
}
```

(성공 응답에서는 `code` 키가 없다.)

## 6. 관련 문서

- 에러 코드 정의/네이밍: [`error-codes.md`](error-codes.md)
- Swagger 문서화: [`swagger.md`](swagger.md)
