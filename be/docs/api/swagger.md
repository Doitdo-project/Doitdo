# Swagger / OpenAPI — 컨트롤러 작성 가이드

이 문서는 새 컨트롤러를 작성하거나 수정하는 모든 작업의 **체크리스트**다.

## 1. 개요

- 의존성: `springdoc-openapi-starter-webmvc-ui:2.7.0` (`be/build.gradle`)
- 활성 프로파일: **`dev` / `local` 한정** (운영 보안)
- 설정 위치: `com.doitdo.global.config.OpenApiConfig`
- 11개 그룹: `auth`, `user`, `todo`, `tamagotchi`, `streak`, `inventory`, `shop`, `notification`, `setting`, `bugreport`, `global`
- 인증: JWT BearerAuth (Swagger UI 의 Authorize 버튼)
- UI: <http://localhost:8080/swagger-ui.html> (부팅 후)

각 그룹은 `OpenApiConfig` 의 `GroupedOpenApi` 빈에 의해 `packagesToScan = "com.doitdo.domain.{group}.api.controller"` 로 잡힌다. 새 컨트롤러는 반드시 이 경로 아래 위치해야 그룹에 노출된다.

## 2. 컨트롤러 작성 템플릿 (복붙 가능)

```java
@Tag(name = "auth", description = "인증/인가")
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @Operation(summary = "로그인", description = "이메일/비밀번호로 액세스 토큰 발급")
    @ApiErrorCodes({"A00-001", "A00-002"})  // 도메인 비즈니스 에러만 명시
    @PublicApi                              // 인증 불필요한 endpoint (자동 401/403 부착 제외)
    @PostMapping("/login")
    public GlobalApiResponse<LoginResp> login(@Valid @RequestBody LoginReq req) {
        return GlobalApiResponse.ok(authService.login(req));
    }
}
```

핵심 포인트:

- `@Tag` — Swagger UI 그룹 내부 섹션 표시.
- `@Operation` — endpoint 요약/설명. 작성 권장.
- `@ApiErrorCodes({...})` — 도메인 비즈니스 에러 코드 **명시** (자세한 규칙은 §4).
- `@PublicApi` — 인증 불필요 endpoint 마커 (자세한 규칙은 §5).
- 반환 타입은 `GlobalApiResponse<T>` 로 정확히. Swagger 가 200 응답 스키마를 여기서 추론.

## 3. 자동 부착 응답 표

작성자가 직접 적지 않아도 Swagger 에 자동으로 붙는 에러 응답들:

| 응답 | 조건 | 작성자 작업 |
|---|---|---|
| 200 / 201 | 메서드 반환 타입 (`GlobalApiResponse<T>`) | 자동 |
| 400 G00-001 | 모든 endpoint | 자동 (`BadRequestAutoCustomizer`) |
| 401 G00-002 / 403 G00-003 | `@PublicApi` 없을 때 | 자동 (`AuthRequiredAutoCustomizer`) |
| 422 G00-006 | `@Valid` / `@Validated` 파라미터 있을 때 | 자동 (`ValidationErrorAutoCustomizer`) |
| 500 G99-999 | 모든 endpoint | 자동 (`InternalServerErrorAutoCustomizer`) |
| 도메인 비즈니스 에러 (A00-001 등) | 명시 | `@ApiErrorCodes({...})` |

`@ApiErrorCodes` 로 명시된 코드들은 HTTP status 별로 그룹핑되어 응답 예시가 자동 주입된다 (`ApiErrorCodesCustomizer`). 같은 status 의 자동 부착 응답이 이미 있으면 `examples` 가 병합된다 (`SwaggerResponseUtils`).

## 4. `@ApiErrorCodes` 사용 규칙

위치: `com.doitdo.global.swagger.ApiErrorCodes` — 메서드 레벨 어노테이션.

```java
@ApiErrorCodes({"A00-001", "A00-002"})
```

규칙:

- `value` 는 **`ErrorCode.getCode()` 가 반환하는 문자열 코드** 배열 (예: `"A00-001"`).
  - **enum 이름 (`"A00_001"`, `"LOGIN_FAILED"`) 을 적으면 안 된다.**
- 모르는 코드를 입력하면 부팅 시점에 `IllegalArgumentException` 으로 즉시 실패 (오타 조기 발견).
- ErrorCode enum 이 SSOT — 메시지/status 가 enum 에서 바뀌면 Swagger 응답 예시가 자동 갱신된다.
- 글로벌 코드 (`G00-xxx` 계열) 는 **명시 불필요** — 자동 부착 대상이거나 자동 부착 예정.
  - 예외: 비즈니스 의도로 특정 글로벌 코드를 명시하고 싶을 때만 적는다 (예: `G00-004` Not Found).

내부 동작: `ApiErrorCodesCustomizer` 가 `ErrorCodeRegistry.find(code)` 로 해석 → HTTP status 별로 그룹핑 → 동일 status 에 여러 코드가 있으면 `examples` 안에 코드별 예시로 표현.

## 5. `@PublicApi` 마커

위치: `com.doitdo.global.swagger.PublicApi` — 메서드 또는 클래스 레벨에 부착.

규칙:

- 인증이 필요 없는 endpoint 임을 표시.
- 자동 부착되는 `401 G00-002 / 403 G00-003` 응답에서 제외된다 (`AuthRequiredAutoCustomizer`).
- `SecurityConfig` 의 `PUBLIC_ENDPOINTS` 와 정합성 유지 책임은 컨트롤러 작성자에게 있다 (마커만 붙이고 SecurityConfig 안 풀면 실제 호출은 401/403 이 됨).
- 클래스 레벨 1번이면 그 컨트롤러의 모든 endpoint 에 적용 (예: `HealthController`).

## 6. 흔한 실수

1. **`@PublicApi` 빠뜨림** → 의도와 다른 401/403 응답이 Swagger 에 노출 (또는 SecurityConfig 와 불일치).
2. **`@ApiErrorCodes` 에 enum 이름** (예: `"LOGIN_FAILED"`) **적음** → 항상 `getCode()` 문자열 (예: `"A00-001"`).
3. **200 응답 스키마가 비어 보임** → 메서드 반환 타입을 `GlobalApiResponse<T>` 로 정확히 적었는지 확인. 원시 DTO 만 반환하면 표준 포맷이 깨진다.
4. **dev / local 외 프로파일에서 Swagger 안 뜸** → 의도된 동작 (운영 보안).
5. **그룹에 컨트롤러가 안 잡힘** → 컨트롤러가 `OpenApiConfig` 의 `packagesToScan` 경로 (`com.doitdo.domain.{group}.api.controller`) 에 있는지 확인.
6. **`@ApiErrorCodes` 코드 오타** → 부팅 즉시 `IllegalArgumentException` 으로 알려준다. 스택트레이스에 메서드 이름과 잘못된 코드가 같이 나오니 그걸 보고 수정.

## 7. 검증 절차 (컨트롤러 작성 후)

1. 부팅: `./gradlew bootRun --args='--spring.profiles.active=dev'` ([`../ops/run-local.md`](../ops/run-local.md)).
2. <http://localhost:8080/swagger-ui.html> 접속.
3. 해당 그룹 (예: `auth`) 선택 → 새 endpoint 의 모든 응답 확인.
4. 명시한 ErrorCode 들이 모두 정확한 코드/메시지로 노출되는지 확인.
5. 500 G99-999 가 자동으로 붙어 있는지 확인.
6. 인증 필요 endpoint 라면 Swagger UI 의 `Authorize` 로 JWT 넣고 실제 호출까지 확인.

## 8. 관련 문서

- 응답 객체 사양: [`response-format.md`](response-format.md)
- 에러 코드 정의/Registry: [`error-codes.md`](error-codes.md)
- 패키지 위치 규약: [`../architecture/package-layout.md`](../architecture/package-layout.md)
