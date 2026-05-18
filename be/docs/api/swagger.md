# Swagger / OpenAPI — 컨트롤러 작성 가이드

이 문서는 새 컨트롤러를 작성하거나 수정하는 모든 작업의 **체크리스트**다.

## 1. 개요

- 의존성: `springdoc-openapi-starter-webmvc-ui:2.7.0` (`be/build.gradle`)
- 활성 프로파일: **`dev` / `local` 한정** (운영 보안)
- 설정 위치: `com.doitdo.global.config.OpenApiConfig`
- 12개 그룹: `auth`, `user`, `todo`, `tamagotchi`, `streak`, `inventory`, `shop`, `notification`, `setting`, `bugreport`, `notice`, `global`
- 인증: JWT BearerAuth (Swagger UI 의 Authorize 버튼)
- UI: <http://localhost:8080/swagger-ui.html> (부팅 후)

각 그룹은 `OpenApiConfig` 의 `GroupedOpenApi` 빈에 의해 `packagesToScan = "com.doitdo.domain.{group}.api.controller"` 로 잡힌다. 새 컨트롤러는 반드시 이 경로 아래 위치해야 그룹에 노출된다.

### TODO API 응답 정책 메모

- `GET /api/todos` 응답은 `type=SOMEDAY`, `status=DONE`, `done_date < 오늘(KST)` 인 항목을 제외한다.
- `done_date IS NULL` 인 기존 `SOMEDAY DONE` 데이터는 제외하지 않는다.
- `GET /api/todos/search`, `GET /api/todos/calendar` 응답에는 이 제외 정책을 적용하지 않는다.
- `GET /api/todos/calendar` 는 soft-deleted RECURRING 파생 NORMAL 인스턴스를 응답하지 않지만, 같은 `master_todo_id + start_date` 의 가상 occurrence 생성을 차단하는 마커로 사용한다.

### 반복 TODO 수정/삭제 scope

TODO 생성/수정 Request body 의 카테고리는 `categoryId` 또는 `category`(이름)를 지원한다. 둘 다 있으면 `categoryId` 가 우선한다.

`DELETE /api/todos/{todoId}`:

| Query | 의미 |
|---|---|
| 없음 | 기존 단건 soft delete |
| `scope=all` | RECURRING 마스터와 활성 파생 인스턴스 전체 soft delete |
| `scope=only&occurrenceDate=YYYY-MM-DD` | 해당 occurrence만 NORMAL 인스턴스로 실체화 후 soft delete |
| `scope=from&occurrenceDate=YYYY-MM-DD` | 기존 RECURRING 마스터 `endDate`를 전날로 줄이고, 이후 파생 인스턴스 중 `status != DONE` 인 항목만 soft delete |

`PATCH /api/todos/{todoId}`:

| Query | 의미 |
|---|---|
| 없음 | 기존 단건 수정. RECURRING 마스터면 일괄수정 |
| `scope=only&occurrenceDate=YYYY-MM-DD` | 해당 occurrence만 NORMAL 인스턴스로 실체화 후 수정 |
| `scope=from&occurrenceDate=YYYY-MM-DD` | 2026-05-15 변경: 새 마스터 생성 없이 기존 RECURRING 마스터 일괄수정 |

`scope=only` 은 `todoId` 가 RECURRING 마스터일 때 `occurrenceDate` 가 필수다.
`scope=only` 의 `occurrenceDate` 는 마스터 반복 규칙에 포함된 날짜여야 한다.
`scope=from` 삭제는 완료된 NORMAL 파생 인스턴스(`status=DONE`)를 완료 기록으로 보존한다.
RECURRING 마스터 수정은 기존 마스터 TODO 를 직접 수정하고, 이미 실체화된 NORMAL 파생 인스턴스 중 `status != DONE` 인 항목만 제목/내용/카테고리/알림 스냅샷을 갱신한다. `DONE` 항목은 완료 당시 기록 보존을 위해 수정하지 않는다.

### 출석 보상 자동 적립 (2026-05-13 Stage 5)

`GET /api/users/me`:

| 항목 | 내용 |
|---|---|
| 인증 | 필요 |
| 요청 body | 없음 |
| 성공 응답 | `GlobalApiResponse<UserInfoResp>` |
| 그날 첫 호출 | `dailyAttendanceClaimed=false` 반환 후 100 뚜레딧 자동 적립 |
| 그날 두 번째 이후 호출 | `dailyAttendanceClaimed=true` 반환, 지갑 변동 없음 |
| 기준 시각 | `Asia/Seoul` 자정 |

별도 출석 보상 POST 엔드포인트는 없다. 출석 보상은 `WalletEarnSource.DAILY_ATTENDANCE` 로 `wallet_earn_logs` 에 기록하며, `PET_TOUCH` / `TODO_COMPLETION` 합산 일일 cap 에 포함하지 않는다.

### 다마고치 똥치우기 미션 API (2026-05-13 Stage 4)

`GET /api/characters/me`:

| 항목 | 내용 |
|---|---|
| 신규 응답 필드 | `poop: boolean` |
| Lazy 갱신 | `user_character.poop_time_date` 가 오늘(KST)이 아니면 10:00~22:00 사이 분 단위 `poop_time` 을 새로 결정 |
| 활성 조건 | 현재 시각(KST) >= `poop_time` 이고 `poop_cleared_date` 가 오늘이 아님 |

`POST /api/characters/me/actions/POOP`:

| 항목 | 내용 |
|---|---|
| 성공 응답 | `GlobalApiResponse<CharacterActionUrlResp>` |
| 보상 | `earnedAmount=50`, `WalletEarnSource.POOP_CLEAR`, `bypassDailyCap=true` |
| 처리 후 | `user_character.poop_cleared_date=오늘(KST)`, 이후 `poop=false` |
| 비활성/중복 | 409 + `M09-004` |

`CharacterActionUrlResp` 는 `actionUrl`, `earnedAmount`, `balanceAfter` 만 노출한다. `POOP` 은 등록된 애니메이션 row 가 없으면 `actionUrl=null` 로 보상 처리만 수행한다. 기존 `dailyTouchCount`, `nextAvailableAt` 응답 필드는 제거됐으며, `user_character.daily_touch_count` 컬럼은 터치 쿨타임/한도 검사용으로 유지한다.

`{actionType}` 은 `CharacterActionType` enum (EYE/IDLE/WALK/SLEEP/HAPPY/SAD/POOP) 으로 Swagger 에서 자동 노출되며 입력 예시는 POOP.

### 가구 테마 구매/배치 API (2026-05-14)

`GET /api/shop/themes`:

| 항목 | 내용 |
|---|---|
| 인증 | 필요 |
| 성공 응답 | `GlobalApiResponse<FurnitureThemeListResp>` |
| 응답 확장 | `ownedCount`, `totalPrice`, `purchasePrice`, `alreadyOwned`, `furnitures[]` |
| 가구 인라인 | `furnitureId`, `name`, `price`, `thumbnailUrl`, `owned` |

`POST /api/shop/themes/{themeCode}/purchase`:

| 항목 | 내용 |
|---|---|
| 인증 | 필요 |
| 요청 body | 없음 |
| 성공 응답 | `GlobalApiResponse<PurchaseThemeResp>` |
| 처리 | 미보유 테마 가구만 구매, 자동 배치 없음 |
| 에러 | `S03-001`, `S03-002`, `S03-003`, `S03-010`, `S00-003`, `S00-005` |

`POST /api/users/me/room/themes/{themeCode}/placements`:

| 항목 | 내용 |
|---|---|
| 인증 | 필요 |
| 요청 body | 없음 |
| 성공 응답 | `GlobalApiResponse<PlaceThemeResp>` |
| 처리 | 보유한 테마 가구를 일괄 배치, 같은 카테고리 기존 배치는 제거 |
| 응답 | `themeCode`, `themeName`, `placedCount`, `items[]` |
| 에러 | `S03-001`, `S03-002`, `S03-003`, `S03-011`, `S00-001` |

프론트의 "바로 배치하기"는 테마 구매 API 성공 후 테마 일괄 배치 API를 추가 호출한다. 이미 풀세트를 보유한 경우 구매 API를 건너뛰고 배치 API만 호출한다.

### 공지사항 API (2026-05-15)

`GET /api/notices/latest-popup`:

| 항목 | 내용 |
|---|---|
| 인증 | 필요 |
| 성공 응답 | `GlobalApiResponse<NoticePopupResp>` |
| 처리 | 활성 공지 중 최신 1개를 조회하고, 현재 사용자가 다시 안보기 한 공지면 `show=false` 반환 |
| 공지 없음 | `show=false`, `notice=null` |

`GET /api/notices`:

| 항목 | 내용 |
|---|---|
| 인증 | 필요 |
| 성공 응답 | `GlobalApiResponse<NoticeListResp>` |
| 처리 | 활성 공지사항 목록을 최신순으로 반환 |

`GET /api/notices/{noticeId}`:

| 항목 | 내용 |
|---|---|
| 인증 | 필요 |
| 성공 응답 | `GlobalApiResponse<NoticeResp>` |
| 에러 | `O00-001` |

`POST /api/notices/{noticeId}/dismiss`:

| 항목 | 내용 |
|---|---|
| 인증 | 필요 |
| 요청 body | 없음 |
| 성공 응답 | 204 `GlobalApiResponse<Void>` |
| 처리 | `(user_id, notice_id)` 기준으로 다시 안보기 저장. 이미 저장된 경우도 성공 처리 |
| 에러 | `O00-001` |

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
