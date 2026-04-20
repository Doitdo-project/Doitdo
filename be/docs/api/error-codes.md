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

## 3. 도메인 enum (9개)

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

각 enum 의 실제 값 (코드/status/메시지) 은 enum 파일 자체가 SSOT.
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

## 7. 관련 문서

- 응답 객체: [`response-format.md`](response-format.md)
- Swagger 자동 문서화: [`swagger.md`](swagger.md)
