# 에러 코드 (`ErrorCode`)

위치: `com.doitdo.global.exception`

## 1. 인터페이스

```java
public interface ErrorCode {
    String getCode();
    HttpStatus getHttpStatus();
    String getDefaultMessage();
}
```

모든 도메인 에러 코드는 이 인터페이스를 구현하는 enum 으로 관리한다.

## 2. 코드 형식

```
{LETTER}{NN}-{NNN}
```

- `LETTER` — 도메인 식별자 (1글자)
- `NN` — 도메인 내부 카테고리 (2자리, `00` 부터)
- `NNN` — 카테고리 내 일련번호 (3자리, `001` 부터)

예: `A00-001` (auth / 로그인 카테고리 / 1번)

## 3. 도메인 enum (10개)

| Enum | 접두 letter | 도메인 |
|---|---|---|
| `CommonErrorCode` | `G` (G99 = 서버 오류) | global / common |
| `AuthErrorCode` | `A` | auth |
| `UserErrorCode` | `U` | user |
| `TodoErrorCode` | `T` | todo |
| `TamagotchiErrorCode` | `M` | tamagotchi |
| `InventoryErrorCode` | `I` | inventory |
| `ShopErrorCode` | `S` | shop |
| `NotificationErrorCode` | `N` | notification |
| `SettingErrorCode` | `C` | setting |
| `BugReportErrorCode` | `B` | bugreport |

각 enum 의 실제 값 (코드/status/메시지) 은 enum 파일 자체가 SSOT.

> **T05-004 재정의 (2026-04-22):** `TodoErrorCode.T05_004` 메시지를
> "반복 TODO 는 현재 미루기 미지원 (인스턴스 설계 후 추가 예정)" → "반복 TODO 미루기 시 occurrenceDate 필수" 로 변경.
> RECURRING 타입 TODO 에 snooze 를 시도할 때 `occurrenceDate` 가 없거나 유효한 발생일이 아니면 422 + T05-004 가 반환된다.
>
> **T03-004 반복 상태 변경 (2026-05-12):** `PATCH /api/todos/{todoId}/status` 에서
> `todoId` 가 RECURRING 마스터이면 `occurrenceDate` 가 필요하다. 값이 있으면 해당 날짜의 NORMAL 인스턴스를
> 찾거나 생성한 뒤 상태를 변경하고, 값이 없거나 반복 규칙에 맞지 않으면 422 + T03-004 를 반환한다.

대표 예시:

### `CommonErrorCode`

| 상수 | code | HTTP |
|---|---|---|
| `BAD_REQUEST` | `G00-001` | 400 |
| `UNAUTHORIZED` | `G00-002` | 401 |
| `FORBIDDEN` | `G00-003` | 403 |
| `NOT_FOUND` | `G00-004` | 404 |
| `CONFLICT` | `G00-005` | 409 |
| `VALIDATION_FAILED` | `G00-006` | 422 |
| `INTERNAL_SERVER_ERROR` | `G99-999` | 500 |

### `AuthErrorCode` (발췌)

| 상수 | code | HTTP | 의미 |
|---|---|---|---|
| `A00_001` | `A00-001` | 401 | 아이디 또는 비밀번호 불일치 |
| `A00_002` | `A00-002` | 423 | 잠긴 계정 |
| `A01_001` | `A01-001` | 401 | 리프레시 토큰 무효 |
| `A03_003` | `A03-003` | 409 | 이미 가입된 소셜 계정 |

전체는 `AuthErrorCode.java` 참고. 다른 도메인 enum 도 동일한 형식.

### `NotificationErrorCode` (N00~N07 전체)

| 상수 | code | HTTP | 의미 |
|---|---|---|---|
| `N00_001` | `N00-001` | 401 | 설정 변경 인증 실패 |
| `N00_002` | `N00-002` | 422 | 설정 변경 시간 형식 오류 |
| `N00_003` | `N00-003` | 500 | 설정 변경 서버 오류 |
| `N01_001` | `N01-001` | 401 | 설정 조회 인증 실패 |
| `N01_002` | `N01-002` | 404 | 알림 설정 없음 |
| `N01_003` | `N01-003` | 500 | 설정 조회 서버 오류 |
| `N02_001` | `N02-001` | 401 | 토큰 해제 인증 실패 |
| `N02_002` | `N02-002` | 404 | 등록되지 않은 FCM 토큰 |
| `N02_003` | `N02-003` | 500 | 토큰 해제 서버 오류 |
| `N03_001` | `N03-001` | 401 | 토큰 등록 인증 실패 |
| `N03_002` | `N03-002` | 422 | 필수 파라미터 누락 |
| `N03_003` | `N03-003` | 500 | 토큰 등록 서버 오류 |
| `N04_001` | `N04-001` | 401 | 목록 조회 인증 실패 |
| `N04_002` | `N04-002` | 500 | 목록 조회 서버 오류 |
| `N05_001` | `N05-001` | 401 | 읽음 인증 실패 |
| `N05_002` | `N05-002` | 403 | 타 사용자 알림 |
| `N05_003` | `N05-003` | 404 | 알림 없음 |
| `N05_004` | `N05-004` | 500 | 읽음 서버 오류 |
| `N06_001` | `N06-001` | 401 | 전체 읽음 인증 실패 |
| `N06_002` | `N06-002` | 500 | 전체 읽음 서버 오류 |
| `N07_001` | `N07-001` | 401 | 삭제 인증 실패 |
| `N07_002` | `N07-002` | 403 | 타 사용자 알림 |
| `N07_003` | `N07-003` | 404 | 알림 없음 |
| `N07_004` | `N07-004` | 500 | 삭제 서버 오류 |

## 4. `ErrorCodeRegistry` — 정적 인덱스

위치: `com.doitdo.global.exception.ErrorCodeRegistry`

부팅 시점에 위 9개 enum 을 모두 모아 `Map<String, ErrorCode>` 로 인덱싱한다. **중복 코드가 있으면 부팅 실패** (조기 발견).

API:

```java
ErrorCodeRegistry.find("A00-001")        // Optional<ErrorCode>
ErrorCodeRegistry.findOrThrow("A00-001") // ErrorCode (없으면 NoSuchElementException)
ErrorCodeRegistry.all()                  // Collection<ErrorCode>
ErrorCodeRegistry.byPrefix("A")          // List<ErrorCode> (해당 접두 전체)
ErrorCodeRegistry.size()                 // int
ErrorCodeRegistry.sources()              // List<Class<? extends ErrorCode>>
```

`@ApiErrorCodes` 어노테이션이 이 Registry 를 통해 코드를 해석하므로, 새 enum 을 추가하면 반드시 `ErrorCodeRegistry.SOURCES` 에도 등록한다.

### `TamagotchiErrorCode` 추가 코드 (exp system, 2026-04)

| 상수 | code | HTTP | 의미 |
|---|---|---|---|
| `M05_006` | `M05-006` | 409 | 아직 진화할 수 없음 — 경험치 부족 |

### `UserErrorCode` 추가 코드 (exp system, 2026-04)

| 상수 | code | HTTP | 의미 |
|---|---|---|---|
| `U00_005` | `U00-005` | 500 | 회원가입 초기화 실패 — EGG Character row 누락 등 운영 이슈 |
| `U00_006` | `U00-006` | 403 | 만 14세 미만 회원가입 차단 (정보통신망법) |

### `UserErrorCode` 추가 코드 (약관 동의, 2026-04)

| 상수 | code | HTTP | 의미 |
|---|---|---|---|
| `U00_007` | `U00-007` | 400 | 이용약관 미동의로 회원가입 차단 |
| `U00_008` | `U00-008` | 400 | 개인정보처리방침 미동의로 회원가입 차단 |

### `UserErrorCode` 추가 코드 (온보딩 API, 2026-04)

| 상수 | code | HTTP | 의미 |
|---|---|---|---|
| `U00_009` | `U00-009` | 403 | 온보딩 미완료 사용자가 보호 API 호출 시 차단 |

### `UserErrorCode` 추가 코드 (내 잔액 조회, 2026-05)

| 상수 | code | HTTP | 의미 |
|---|---|---|---|
| `U05_001` | `U05-001` | 404 | 지갑 데이터를 찾을 수 없음 |

### `TodoErrorCode` 추가 코드 (alert/recurrence redesign, 2026-04)

| 상수 | code | HTTP | 의미 |
|---|---|---|---|
| `TODO_RECURRING_DAYS_OF_WEEK_REQUIRED` | `T14-001` | 400 | 반복 TODO는 daysOfWeek가 필요함 |
| `TODO_RECURRING_START_DATE_DAY_MISMATCH` | `T14-002` | 400 | 반복 TODO의 startDate 요일이 daysOfWeek에 포함되어야 함 |

### `TamagotchiErrorCode` 추가 코드 (character action url, 2026-04)

| 상수 | code | HTTP | 의미 |
|---|---|---|---|
| `M09_001` | `M09-001` | 401 | 인증 토큰이 없거나 유효하지 않음 |
| `M09_002` | `M09-002` | 404 | 해당 캐릭터의 요청 액션을 찾을 수 없음 |
| `M09_003` | `M09-003` | 500 | 서버 내부 오류 |

`AnimationAction` enum 전환 후에도 enum 에는 있지만 `character_actions` row 가 등록되지 않은 액션 호출은 `M09_002` 를 재사용한다. enum 자체에 없는 `actionType` 은 컨트롤러 바인딩 단계의 400 으로 처리한다.

### `ShopErrorCode` 추가 코드 (가구 상점/방 배치, 2026-05)

| 상수 | code | HTTP | 의미 |
|---|---|---|---|
| `FURNITURE_NOT_FOUND` | `S00-001` | 404 | 가구를 찾을 수 없음 |
| `FURNITURE_ALREADY_OWNED` | `S00-002` | 409 | 이미 보유한 가구 |
| `INSUFFICIENT_BALANCE` | `S00-003` | 409 | 잔액 부족 |
| `FURNITURE_NOT_ON_SALE` | `S00-004` | 409 | 판매 중이 아닌 가구 |
| `WALLET_NOT_FOUND` | `S00-005` | 404 | 월렛을 찾을 수 없음 |
| `USER_FURNITURE_NOT_FOUND` | `S01-001` | 404 | 보유 가구를 찾을 수 없음 |
| `PLACEMENT_NOT_FOUND` | `S02-001` | 404 | 배치 정보를 찾을 수 없음 |

### `BugReportErrorCode` 신규 enum (bugreport, 2026-04, JIRA S14P31D107-442)

접두 letter `B`. `ErrorCodeRegistry.SOURCES` 에 등록됨.

| 상수 | code | HTTP | 의미 |
|---|---|---|---|
| `B00_001` | `B00-001` | 500 | 버그 신고 처리 중 서버 오류 |

> MVP 단계에서 비즈니스 검증 에러(`G00-006` 자동 부착)로 충분. Rate Limit(`B00-003` 429) 등은 후속 이슈에서 추가.

## 5. 새 코드 추가 절차

1. 노션 API 명세서에서 코드 충돌 여부 확인 (외부 SSOT).
2. 해당 도메인 enum 에 상수 추가 — `getCode()` 가 반환할 문자열을 정확히 형식에 맞춤.
3. `HttpStatus`, `defaultMessage` 지정.
4. (새 도메인 enum 인 경우) `ErrorCodeRegistry.SOURCES` 에 클래스 등록.
5. 컨트롤러에 `@ApiErrorCodes({"X00-NNN"})` 로 노출 (필요 시).

## 6. 예외 던지기

서비스/컨트롤러에서 비즈니스 예외:

```java
throw new CustomException(AuthErrorCode.A00_001);
// 또는 메시지 override
throw new CustomException(AuthErrorCode.A00_001, "외부 사용자 친화 메시지");
```

`GlobalExceptionHandler` 가 위 예외를 잡아 `GlobalApiResponse.fail(errorCode)` 로 변환한다.
`CustomException` 로그는 `uri="{method} {requestURI}" code={errorCode} status={httpStatus} message="{message}"` 포맷을 사용하며, 5xx 는 stack trace 를 포함한다.

## 7. 관련 문서

- 응답 객체: [`response-format.md`](response-format.md)
- Swagger 자동 문서화: [`swagger.md`](swagger.md)
