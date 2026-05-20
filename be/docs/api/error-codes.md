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

## 3. 도메인 enum (11개)

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
| `NoticeErrorCode` | `O` | notice |

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
| `A04_001` | `A04-001` | 410 | 유효하지 않거나 만료된 비밀번호 재설정 요청 |

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

부팅 시점에 위 enum 을 모두 모아 `Map<String, ErrorCode>` 로 인덱싱한다. **중복 코드가 있으면 부팅 실패** (조기 발견).

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

### 뚜레딧 적립 정책값 (2026-05-13 Stage 1)

Stage 1 신규 에러코드는 없다. `PET_TOUCH`, `TODO_COMPLETION` 의 쿨타임 또는 일일 한도 초과는 예외가 아니라 `earnedAmount=0` 으로 처리한다.
Stage 5 출석 보상은 `GET /api/users/me` 호출 시 자동 적립하며, 이미 받은 날에는 에러 없이 `dailyAttendanceClaimed=true` 를 반환한다 (Stage 2 의 `POST /api/users/me/attendance` + `U07-001` 은 제거됨).
Stage 4 똥치우기 미션은 활성 시각 전이거나 이미 치운 상태에서 `POOP` action 을 호출하면 409 + `M09-004` 를 반환한다.

| 항목 | 정책값 |
|---|---|
| 7일 스트릭 보상 | 500 뚜레딧, 일일 cap 우회 |
| TODO 완료 보상 | 20 뚜레딧 / 1개당, 일일 5회 = 100 뚜레딧 |
| 캐릭터 터치 보상 | 50 뚜레딧 / 1회, 2시간 쿨타임, 일일 2회 = 100 뚜레딧 |
| 출석 보상 | 100 뚜레딧 / 1일 1회, 일일 cap 우회 |
| 똥치우기 보상 | 50 뚜레딧 / 1일 1회, 일일 cap 우회 |
| cap 대상 합산 한도 | `PET_TOUCH` + `TODO_COMPLETION` 일일 200 뚜레딧 |

### `TodoErrorCode` 추가 코드 (alert/recurrence redesign, 2026-04)

| 상수 | code | HTTP | 의미 |
|---|---|---|---|
| `TODO_RECURRING_DAYS_OF_WEEK_REQUIRED` | `T14-001` | 400 | 반복 TODO는 daysOfWeek가 필요함 |
| `TODO_RECURRING_START_DATE_DAY_MISMATCH` | `T14-002` | 400 | 반복 TODO의 startDate 요일이 daysOfWeek에 포함되어야 함 |

> **T14-002 수정 예외 (2026-05-15):** 기존 RECURRING 마스터 수정에서 `startDate` 를 보내지 않고
> `daysOfWeek` 만 변경하는 경우에는 기존 `startDate` 요일이 새 `daysOfWeek` 에 없어도 허용한다.
> `startDate` 는 반복 시작 경계로 유지되고, 캘린더 occurrence 는 그 이후 새 요일 기준으로 생성된다.

### `TamagotchiErrorCode` 추가 코드 (character action url, 2026-04)

| 상수 | code | HTTP | 의미 |
|---|---|---|---|
| `M09_001` | `M09-001` | 401 | 인증 토큰이 없거나 유효하지 않음 |
| `M09_002` | `M09-002` | 404 | 해당 캐릭터의 요청 액션을 찾을 수 없음 |
| `M09_003` | `M09-003` | 500 | 서버 내부 오류 |
| `M09_004` | `M09-004` | 409 | 캐릭터 똥 활성화 시간이 아님 |

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
| `THEME_NOT_FOUND` | `S03-001` | 404 | 테마를 찾을 수 없음 |
| `THEME_CATEGORY_DUPLICATED` | `S03-002` | 409 | 테마에 같은 카테고리 가구가 중복됨 |
| `THEME_EMPTY` | `S03-003` | 422 | 테마에 구매/배치할 가구가 없음 |
| `THEME_ALREADY_OWNED` | `S03-010` | 409 | 이미 테마 풀세트를 보유함 |
| `THEME_NOT_FULLY_OWNED` | `S03-011` | 409 | 테마 가구를 모두 보유하지 않음 |

### `AuthErrorCode` 추가 코드 (비밀번호 재설정 OTP, 2026-05)

A04 그룹은 OTP 6자리 인증번호 흐름에서 사용한다:
1. `POST /api/auth/password/reset-request` — 이메일로 OTP 발송
2. `POST /api/auth/password/reset/verify-code` — 이메일+OTP 검증 후 reset 토큰 발급
3. `POST /api/auth/password/reset` — reset 토큰으로 비번 변경

보안상 *invalid* 와 *expired* 를 A04-001 하나로 통합한다 (구분하면 추측 공격에 정보 제공).
시도 횟수 초과 시 OTP 키를 삭제하고 A04-005 로 응답해 사용자가 재요청하도록 강제한다.

| 상수 | code | HTTP | 의미 |
|---|---|---|---|
| `A04_001` | `A04-001` | 410 | 유효하지 않거나 만료된 재설정 요청 (OTP 미존재 또는 resetToken 무효/만료) |
| `A04_002` | `A04-002` | 422 | 필수 파라미터 누락 (email/code 또는 resetToken/newPassword) |
| `A04_003` | `A04-003` | 500 | 서버 내부 오류 |
| `A04_004` | `A04-004` | 410 | 인증번호 불일치 (attempts 카운트 +1) |
| `A04_005` | `A04-005` | 410 | 인증번호 시도 횟수 초과 → 키 삭제, 재요청 필요 |
| `A04_006` | `A04-006` | 409 | 소셜 계정으로 가입된 이메일 — 해당 IdP 로 로그인 안내 |
| `A04_007` | `A04-007` | 404 | 가입되지 않은 이메일 — 이메일 확인 또는 회원가입 안내 |

> **응답 정책** (`POST /password/reset-request` 기준 — UX 우선, 한국 모바일 앱 컨벤션):
> - 일반 가입자 → 200 OK + 메일 발송
> - 미가입 이메일 / 탈퇴 사용자(익명화돼있어 미가입과 사실상 동일) → 404 + A04-007
> - 소셜 가입자(password=null) → 409 + A04-006
> - account enumeration 일부 노출 트레이드오프 인지 — MVP·시연 단계에서 CS 감소 및 사용자 친화도 우선
> - 메일 발송 실패는 `@Async` Executor 내부에서 swallow 되고 사용자 응답에는 영향이 없다 — 발송 모니터링은 로그(`event=PASSWORD_RESET_MAIL_FAILED`)로 한다.

### `BugReportErrorCode` 신규 enum (bugreport, 2026-04, JIRA S14P31D107-442)

접두 letter `B`. `ErrorCodeRegistry.SOURCES` 에 등록됨.

| 상수 | code | HTTP | 의미 |
|---|---|---|---|
| `B00_001` | `B00-001` | 500 | 버그 신고 처리 중 서버 오류 |

> MVP 단계에서 비즈니스 검증 에러(`G00-006` 자동 부착)로 충분. Rate Limit(`B00-003` 429) 등은 후속 이슈에서 추가.

### `NoticeErrorCode` 신규 enum (notice, 2026-05)

접두 letter `O`. `ErrorCodeRegistry.SOURCES` 에 등록됨.

| 상수 | code | HTTP | 의미 |
|---|---|---|---|
| `O00_001` | `O00-001` | 404 | 공지사항을 찾을 수 없음 |

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
