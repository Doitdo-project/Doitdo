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

## 6. `TodoDetailResp` 필드 (참고)

모든 TODO 단건/목록/검색 응답 공통 필드:

| 필드 | 타입 | 비고 |
|---|---|---|
| `todoId` | `Long` | |
| `title` | `String` | |
| `content` | `String` | nullable |
| `category` | `String` | 카테고리 이름, nullable |
| `type` | `TodoType` | NORMAL / RECURRING / PERIOD |
| `priority` | `Integer` | |
| `startDate` | `LocalDate` | |
| `endDate` | `LocalDate` | nullable |
| `daysOfWeek` | `String` | nullable. RECURRING 타입만 채워짐. 요일 CSV (예: `"MON,WED,FRI"`) |
| `status` | `TodoStatus` | TODO / IN_PROGRESS / DONE |
| `updatedAt` | `LocalDateTime` | |
| `snoozedDays` | `int` | 이 TODO 를 미룬 누적 횟수. `snooze_history` 테이블 COUNT 파생 (todos DDL 변경 없음) |

`TodoListResp.items[]` 와 `TodoSearchResp.items[]` 도 동일한 `TodoDetailResp` 구조를 사용한다.

## 7. `TodoCalendarResp` 필드

`GET /api/todos/calendar` 응답:

```json
{
  "items": [
    {
      "todoId": 12,
      "masterTodoId": 3,
      "occurrenceDate": "2026-04-23",
      "isVirtual": false
    }
  ]
}
```

`CalendarItemResp` 필드:

| 필드 | 타입 | 비고 |
|---|---|---|
| `todoId` | `Long` | 실체 TODO ID. 가상 인스턴스는 `null` |
| `masterTodoId` | `Long` | RECURRING 마스터 ID. 일반 NORMAL/PERIOD 는 `null` |
| `occurrenceDate` | `LocalDate` | RECURRING 발생일. 일반 NORMAL/PERIOD 는 `null` |
| `isVirtual` | `boolean` | DB row 없는 가상 인스턴스 여부 |
| `title` | `String` | |
| `content` | `String` | nullable |
| `category` | `String` | 카테고리 이름, nullable |
| `type` | `TodoType` | NORMAL / RECURRING / PERIOD |
| `priority` | `Integer` | |
| `startDate` | `LocalDate` | 가상 인스턴스는 occurrenceDate 와 동일 |
| `endDate` | `LocalDate` | nullable |
| `daysOfWeek` | `String` | nullable. RECURRING 마스터의 요일 집합 CSV (예: `"MON,WED,FRI"`) |
| `status` | `TodoStatus` | 가상 인스턴스는 항상 `TODO` |
| `updatedAt` | `LocalDateTime` | 가상 인스턴스는 마스터 `updatedAt` |
| `snoozedDays` | `int` | 가상 인스턴스는 `0` |

## 8. `CharacterActionUrlResp` 필드 (뚜레딧 적립 Stage 3+)

`GET /api/characters/me/actions/{actionType}` 응답:

| 필드 | 타입 | 비고 |
|---|---|---|
| `actionUrl` | `String` | 재생할 캐릭터 애니메이션 URL. 쿨다운/cap 관계없이 항상 정상 반환 |
| `earnedAmount` | `int` | 이번 호출에서 지급된 뚜레딧 (적립 불가 시 0) |
| `balanceAfter` | `int` | 호출 직후 지갑 잔액 |
| `dailyTouchCount` | `int` | 오늘 적립된 터치 횟수 (최대 3) |
| `nextAvailableAt` | `LocalDateTime` | 다음 적립 가능 시각. 오늘 cap 소진 시 내일 자정, 쿨다운 중이면 `lastTouchedAt + 1h` |

`actionType = EYE` 인 경우 적립 평가 없이 `earnedAmount=0`, `dailyTouchCount` 는 현재 카운트, `nextAvailableAt` 은 정상 계산.

## 9. 관련 문서

- 에러 코드 정의/네이밍: [`error-codes.md`](error-codes.md)
- Swagger 문서화: [`swagger.md`](swagger.md)
