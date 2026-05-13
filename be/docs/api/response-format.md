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

## 6. `UserInfoResp` 필드

로그인 / 소셜 로그인 / `GET /api/users/me` / 온보딩 응답에서 공통으로 쓰는 사용자 요약 정보:

| 필드 | 타입 | 비고 |
|---|---|---|
| `userId` | `Long` | 사용자 ID |
| `username` | `String` | 닉네임 |
| `email` | `String` | 이메일 |
| `hasPassword` | `boolean` | 일반 비밀번호 보유 여부. 소셜 전용 계정은 `false` |
| `birthDateRegistered` | `boolean` | 생년월일 등록 여부 |
| `agreementsAccepted` | `boolean` | 필수 약관 동의 완료 여부 |
| `dailyAttendanceClaimed` | `boolean` | Asia/Seoul 기준 오늘 출석 보상 수령 여부 |

## 6-1. `CurrentCharacterResp` 필드

`GET /api/characters/me` 응답:

| 필드 | 타입 | 비고 |
|---|---|---|
| `characterId` | `Long` | 원본 캐릭터 식별자 |
| `name` | `String` | 현재 캐릭터 이름 |
| `stage` | `String` | EGG / BABY / TEEN / ADULT |
| `thumbnailUrl` | `String` | 대표 이미지 URL |
| `growthPercent` | `Integer` | 현재 단계 진행률 |
| `currentExp` | `Integer` | 현재 단계 EXP |
| `requiredExp` | `Integer` | 현재 단계 필요 EXP |
| `canEvolve` | `Boolean` | 진화 가능 여부 |
| `canFarewell` | `Boolean` | 독립 가능 여부 |
| `equippedUserItemId` | `Long` | 장착 아이템 row ID, nullable |
| `userCharacterId` | `Long` | 사용자가 실제로 키우는 활성 다마고치 row ID |
| `poop` | `Boolean` | 오늘 똥치우기 미션 활성 여부. `poop_time` 도래 후이고 오늘 아직 치우지 않았으면 `true` |

`poop_time` 은 `GET /api/characters/me` 호출 시 Asia/Seoul 기준 날짜가 바뀌었을 때 10:00~22:00 사이 분 단위 시각으로 Lazy 결정된다.

## 7. `TodoDetailResp` 필드 (참고)

모든 TODO 단건/목록/검색 응답 공통 필드:

| 필드 | 타입 | 비고 |
|---|---|---|
| `todoId` | `Long` | |
| `title` | `String` | |
| `content` | `String` | nullable |
| `category` | `String` | 카테고리 이름 스냅샷, nullable. 카테고리가 삭제되어도 todo 에 남아있던 이름이 그대로 노출된다. |
| `colorHex` | `String` | 카테고리 색상 hex (예: `"#FF8888"`), nullable. 동일 이름의 활성 카테고리가 있으면 그 색이 우선되고, 없으면 todo 의 스냅샷 색이 사용된다. |
| `type` | `TodoType` | NORMAL / RECURRING / PERIOD |
| `priority` | `Integer` | |
| `startDate` | `LocalDate` | |
| `endDate` | `LocalDate` | nullable |
| `daysOfWeek` | `String` | nullable. RECURRING 타입만 채워짐. 요일 CSV (예: `"MON,WED,FRI"`) |
| `status` | `TodoStatus` | TODO / IN_PROGRESS / DONE |
| `updatedAt` | `LocalDateTime` | |
| `snoozedDays` | `int` | 이 TODO 를 미룬 누적 횟수. `snooze_history` 테이블 COUNT 파생 (todos DDL 변경 없음) |

`TodoListResp.items[]` 와 `TodoSearchResp.items[]` 도 동일한 `TodoDetailResp` 구조를 사용한다.

### `DELETE /api/todos/{todoId}` 반복 scope

| Query | 응답 | 비고 |
|---|---|---|
| 없음 | 204 | 해당 row 단건 soft delete |
| `scope=all` | 204 | RECURRING 마스터면 활성 파생 인스턴스도 함께 soft delete |
| `scope=only&occurrenceDate=YYYY-MM-DD` | 204 | 해당 occurrence를 NORMAL 인스턴스로 실체화 후 soft delete |
| `scope=from&occurrenceDate=YYYY-MM-DD` | 204 | 마스터 `endDate`를 `occurrenceDate - 1`로 줄이고 이후 파생 인스턴스 soft delete |

`scope=only` 로 삭제된 NORMAL 파생 인스턴스는 `isDeleted=true` 상태로 남아 캘린더 가상 occurrence 생성을 차단한다. 응답에는 포함되지 않는다.

### `PATCH /api/todos/{todoId}` 반복 scope

기본 응답은 `TodoDetailResp` 이다.

| Query | 응답 대상 | 비고 |
|---|---|---|
| 없음 | 수정된 기존 TODO | 기존 단건 수정 |
| `scope=only&occurrenceDate=YYYY-MM-DD` | 수정된 NORMAL 인스턴스 | 해당 occurrence만 실체화 후 수정 |
| `scope=from&occurrenceDate=YYYY-MM-DD` | 새 RECURRING 마스터 | 기존 마스터를 전날 종료하고 수정 내용으로 새 마스터 생성 |

`scope=from` 수정 응답의 `todoId` 는 새 마스터 ID 다. FE는 이후 같은 반복 흐름을 조작할 때 이 새 `todoId`를 사용해야 한다.

### 카테고리 스냅샷 정책 (2026-05-12 도입)

- **저장**: `todos.category_name` / `todos.category_color_id` 두 컬럼에 카테고리 이름·색 스냅샷을 저장한다.
- **rename / 색 변경**: 카테고리 update 시 해당 카테고리를 쓰는 활성 todo 들의 스냅샷이 일괄 update 된다.
- **삭제**: 카테고리 delete 시 `category_id` 는 NULL 로 detach 되고 이름·색 스냅샷은 잔여 → todo 응답의 `category` 는 그대로 유지된다.
- **응답 colorHex**: 동일 이름의 활성 카테고리가 있으면 그 카테고리의 색이 override, 없으면 todo 의 스냅샷 색.
- **필터**: `GET /api/todos?category=공부` 는 `todos.category_name` 스냅샷 기반으로 매칭. 동일 이름의 카테고리를 다시 만들면 옛 todo 도 함께 잡힌다 (의도된 동작).

### `PATCH /api/todos/{todoId}/status` 요청

```json
{
  "status": "DONE",
  "occurrenceDate": "2026-05-12"
}
```

| 필드 | 타입 | 비고 |
|---|---|---|
| `status` | `TodoStatus` | 필수. TODO / IN_PROGRESS / DONE |
| `occurrenceDate` | `LocalDate` | nullable. `todoId` 가 RECURRING 마스터일 때만 필수이며, 해당 날짜의 NORMAL 인스턴스를 찾거나 생성한 뒤 상태를 변경한다. NORMAL/PERIOD/SOMEDAY 요청에서는 무시된다. |

## 8. `TodoCalendarResp` 필드

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
| `category` | `String` | 카테고리 이름 스냅샷, nullable. 삭제된 카테고리도 todo 에 남아있던 이름이 노출된다. |
| `colorHex` | `String` | 카테고리 색상 hex, nullable. 동일 이름의 활성 카테고리 색이 우선, 없으면 스냅샷 색. |
| `type` | `TodoType` | NORMAL / RECURRING / PERIOD |
| `priority` | `Integer` | |
| `startDate` | `LocalDate` | 가상 인스턴스는 occurrenceDate 와 동일 |
| `endDate` | `LocalDate` | nullable |
| `daysOfWeek` | `String` | nullable. RECURRING 마스터의 요일 집합 CSV (예: `"MON,WED,FRI"`) |
| `status` | `TodoStatus` | 가상 인스턴스는 항상 `TODO` |
| `updatedAt` | `LocalDateTime` | 가상 인스턴스는 마스터 `updatedAt` |
| `snoozedDays` | `int` | 가상 인스턴스는 `0` |

반복 TODO의 가상 인스턴스 생성 차단 규칙:

- `type=NORMAL`, `master_todo_id=<RECURRING 마스터 ID>`, `start_date=<occurrenceDate>` 인 파생 row가 있으면 해당 날짜의 가상 인스턴스를 만들지 않는다.
- 이 차단 판단에는 `isDeleted=true` row도 포함한다.
- `isDeleted=true` row는 응답 `items[]` 에 포함하지 않는다.

## 9. `CharacterActionUrlResp` 필드 (뚜레딧 적립 Stage 3+)

`POST /api/characters/me/actions/{actionType}` 응답:

| 필드 | 타입 | 비고 |
|---|---|---|
| `actionUrl` | `String` | 재생할 캐릭터 애니메이션 URL. 일반 액션은 쿨다운/cap 관계없이 정상 반환. `POOP` 은 등록된 애니메이션 row 가 없으면 `null` |
| `earnedAmount` | `int` | 이번 호출에서 지급된 뚜레딧 (적립 불가 시 0) |
| `balanceAfter` | `int` | 호출 직후 지갑 잔액 |

`actionType` 이 캐릭터 액션 enum 에 포함되고 활성 캐릭터의 `character_actions` row 가 등록되어 있으면 등록 액션은 터치 적립 흐름에 진입한다. 쿨다운/cap 으로 적립되지 않는 경우에도 `actionUrl` 은 반환하고 `earnedAmount=0` 으로 응답한다.

`actionType=POOP` 은 `CurrentCharacterResp.poop=true` 일 때만 50 뚜레딧을 `POOP_CLEAR` 로 적립하고, 오늘 처리 완료로 바꾼다. 활성 시각 전이거나 이미 치운 상태이면 409 `M09-004` 를 반환한다.

enum 에는 있지만 해당 캐릭터의 `character_actions` row 가 없는 액션은 404 `M09-002` 를 반환한다.

## 10. `UserStreakResp` 필드

`GET /api/users/me/streak` 응답:

| 필드 | 타입 | 비고 |
|---|---|---|
| `currentStreakCount` | `Integer` | 현재 연속 달성 일수 |
| `currentStreakStartDate` | `LocalDate` | 현재 연속 달성 시작일 |
| `lastActiveDate` | `LocalDate` | 마지막 활동일 |
| `longestStreakCount` | `Integer` | 최장 연속 달성 일수 |
| `longestStreakStartDate` | `LocalDate` | 최장 연속 달성 시작일 |
| `longestStreakEndDate` | `LocalDate` | 최장 연속 달성 종료일 |
| `canClaim` | `boolean` | 현재 streak 구간의 7일 단위 보상 수령 가능 여부 |

`canClaim` 은 현재 연속 달성 일수가 7의 배수이고, 같은 `currentStreakStartDate` / `currentStreakCount` 로 보상 수령 기록이 없을 때만 `true` 다.

## 11. 관련 문서

- 에러 코드 정의/네이밍: [`error-codes.md`](error-codes.md)
- Swagger 문서화: [`swagger.md`](swagger.md)
