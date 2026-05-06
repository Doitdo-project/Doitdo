# 버그 신고 API 설계안

- **연관 JIRA**: S14P31D107-442 (BE 구현), S14P31D107-392 (부모 스토리), S14P31D107-443 (FE 연동), S14P31D107-441 (FE 화면)
- **작성일**: 2026-04-30
- **작성 기준**: 코드 변경 없음. 설계 문서 전용.

---

## 1. 배경 / 목적

### 부모 스토리 의도 (S14P31D107-392)

> "사용자는 앱 사용 중 버그를 신고하고 싶다" — JIRA 본문 인용

버그 신고 기능은 명시적으로 **후순위** 기능으로 분류되어 있다(JIRA S14P31D107-392 본문: "후순위: 버그 신고 기능"). 팀이 이 스토리를 진행하기로 결정한 시점에서 최소 기능부터 구현하는 접근이 적절하다.

### 이 이슈에서 다루는 범위

- **포함**: 제목 + 내용(텍스트)을 저장하는 버그 신고 단건 생성 API (POST)
- **포함**: 인증된 사용자 식별(신고자 userId 저장)

### 다루지 않는 범위

- **이미지 업로드 제외**: JIRA S14P31D107-442 본문 "이미지 없이 제목/내용을 저장하는 버그 신고 API를 구현한다"에 명시됨
- **운영자 조회/상태 변경 API**: 운영자 대시보드는 후속 이슈
- **신고 목록 조회 (사용자용)**: 본 이슈 범위 외
- **알림(슬랙/이메일) 연동**: 후속 작업
- **익명 신고**: 인증 필수 설계 채택(상세는 §2 참고)

---

## 2. API 명세

### 2-1. 엔드포인트 비교

| 후보 | 경로 | 근거 | 판정 |
|---|---|---|---|
| **권장안** | `POST /api/bug-reports` | 복수형 + kebab-case. 기존 `/api/notifications`, `/api/users/me/streak` 패턴(`OpenApiConfig.java`) 정합. 도메인을 직접 표현 | **채택** |
| 대안 A | `POST /api/feedbacks` | 의미 범위가 넓어(기능 제안, 문의 포함) 버그 특정성 부족 | 비추 |
| 대안 B | `POST /api/user/bug-reports` | 사용자 서브리소스로 표현 가능하나 불필요한 중첩. 관리자가 대신 접근하는 시나리오 고려 시 비효율 | 비추 |

**채택 경로**: `POST /api/bug-reports`

---

### 2-2. HTTP 메서드

`POST` — 신규 리소스 생성

---

### 2-3. 인증 요구사항

**인증 필수** (`@AuthenticationPrincipal CustomUserDetails userDetails`). `@PublicApi` 미부착.

근거:
- 신고자 식별: `userId`를 신고 레코드에 저장해야 후속 답신/피드백 가능
- 어뷰징 방지: 비인증 허용 시 스팸성 신고 차단 수단 없음
- FE 화면(S14P31D107-441)이 로그인 후 진입 경로로 추정됨 (추측 — FE 이슈 본문에 명시 없음)

---

### 2-4. Request Body

Content-Type: `application/json`

| 필드명 | 타입 | 필수 | 길이 제약 | 비고 |
|---|---|---|---|---|
| `title` | `String` | 필수 | 1~100자 | `@NotBlank @Size(max=100)` |
| `content` | `String` | 필수 | 1~500자 | `@NotBlank @Size(max=500)`. **최종 확정: 500자** (초안 2000자 → 팀 합의로 500자로 변경) |

> ~~사용자 결정 필요: content 최대 길이를 2000자로 제안했으나, `Notification.message`(500자, `Notification.java:50`)보다 긴 근거는 "버그 재현 절차 기술 공간 필요" 추측. 팀 합의 후 확정할 것.~~ → **확정: 500자 (`Notification.message` 기준 통일)**

**예시 요청:**

```json
{
  "title": "할 일 완료 버튼 클릭 시 화면이 멈춤",
  "content": "1. 홈 화면에서 할 일 목록 접속\n2. 완료 버튼 클릭\n3. 화면이 3초간 멈추고 에러 메시지 없이 원상복구됨\n\n환경: Android 14, 앱 v1.2.3"
}
```

---

### 2-5. Response Body

`GlobalApiResponse<BugReportResp>` — 성공 시 `data` 필드에 아래 구조 (`docs/api/response-format.md` §2 `created` 팩토리 사용)

| 필드명 | 타입 | 비고 |
|---|---|---|
| `bugReportId` | `Long` | 생성된 PK |
| `createdAt` | `LocalDateTime` | 생성 시각 (`BaseTimeEntity` 상속) |

**예시 성공 응답 (HTTP 201 Created):**

```json
{
  "status": 201,
  "message": "버그 신고가 접수되었습니다.",
  "data": {
    "bugReportId": 7,
    "createdAt": "2026-04-30T14:23:10"
  }
}
```

---

### 2-6. 응답 코드

| HTTP 상태 | 상황 | 코드 | 자동/명시 |
|---|---|---|---|
| 201 Created | 정상 접수 | — | — |
| 400 Bad Request | JSON 파싱 실패 | `G00-001` | 자동 (`BadRequestAutoCustomizer`) |
| 401 Unauthorized | 인증 토큰 없음/만료 | `G00-002` | 자동 (`AuthRequiredAutoCustomizer`) |
| 403 Forbidden | 인증은 됐으나 접근 거부 | `G00-003` | 자동 |
| 422 Unprocessable Entity | `@Valid` 검증 실패 (길이 초과 등) | `G00-006` | 자동 (`ValidationErrorAutoCustomizer`) |
| 500 Internal Server Error | DB 저장 실패 등 서버 오류 | `G99-999` | 자동 |

> 신규 `BugReportErrorCode`에서 명시적으로 선언할 비즈니스 에러는 §4 참고.

---

## 3. 도메인 / 패키지 / 엔티티 설계

### 3-1. 도메인 패키지명 비교

| 후보 | 비고 | 판정 |
|---|---|---|
| **`bugreport`** | 기존 단어 단수형 컨벤션(`todo`, `notification`, `streak`). 스코프 명확. | **채택** |
| `bug` | 너무 짧고 모호. 버그 관리 자체가 아닌 신고만 다룸 | 비추 |
| `feedback` | "기능 제안/문의" 등 버그 외 의미 포함 가능. 범위 불명확 | 비추 |

**채택 패키지 루트**: `com.doitdo.domain.bugreport`

---

### 3-2. 5종 디렉토리 패턴 (`docs/architecture/package-layout.md` §1)

```
domain/bugreport/
 ├ api/
 │   ├ controller/
 │   │   └ BugReportController.java
 │   └ dto/
 │       ├ req/
 │       │   └ CreateBugReportReq.java
 │       └ resp/
 │           └ BugReportResp.java
 ├ application/
 │   ├ BugReportService.java          (interface)
 │   └ impl/
 │       └ BugReportServiceImpl.java
 ├ entity/
 │   └ BugReport.java
 └ repository/
     └ BugReportRepository.java
```

---

### 3-3. 엔티티 클래스 설계 (`BugReport`)

**테이블명**: `bug_reports`

| 필드(Java) | 컬럼(DB) | 타입 | 제약 | 비고 |
|---|---|---|---|---|
| `bugReportId` | `bug_report_id` | `BIGINT` | PK, AUTO_INCREMENT | PK 컨벤션 `{테이블명Id}` 따름 |
| `userId` | `user_id` | `BIGINT` | NOT NULL | FK 직접 참조 금지, Long ID 보관(`naming.md` §2) |
| `title` | `title` | `VARCHAR(100)` | NOT NULL | |
| `content` | `content` | `VARCHAR(500)` | NOT NULL | **최종 확정: 500자** (초안 2000자에서 변경) |
| `isDeleted` | `is_deleted` | `TINYINT(1)` | NOT NULL DEFAULT 0 | **Soft Delete 도입 확정** (`Notification` 패턴 동일 적용) |
| `status` | `status` | `ENUM` | NOT NULL DEFAULT 'NEW' | **처리 상태 확정: NEW / REVIEWING / COMPLETE** |
| `createdAt` | `created_at` | `DATETIME` | NOT NULL | `BaseTimeEntity` 상속 |
| `updatedAt` | `updated_at` | `DATETIME` | NOT NULL | `BaseTimeEntity` 상속 |

**Lombok 어노테이션** (기존 엔티티 패턴, `naming.md` §2):

```java
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Builder
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@Entity
@Table(name = "bug_reports")
public class BugReport extends BaseTimeEntity { ... }
```

**정적 팩토리 메서드 제안**:

```java
public static BugReport create(Long userId, String title, String content) {
    return BugReport.builder()
        .userId(userId)
        .title(title)
        .content(content)
        .isDeleted(false)           // Soft Delete 기본값
        .status(BugReportStatus.NEW) // 처리 상태 기본값
        .build();
}
```

> `BugReportStatus` — `NEW`, `REVIEWING`, `COMPLETE` 3종 enum (§7-1 결정 #5)

---

### 3-4. 인덱스 / 제약조건

| 항목 | 필요 여부 | 근거 |
|---|---|---|
| `user_id` 인덱스 | 권장 | 사용자별 신고 목록 조회(운영자 대시보드 후속 작업) 대비 |
| UNIQUE 제약 | 불필요 | 동일 내용 중복 신고 가능(동일 사건을 여러 번 신고할 수 있음) |
| soft delete (`is_deleted`) | **도입 확정** | `Notification` 패턴 동일 적용. 운영 이력 보존. |
| 처리 상태 컬럼 (`status`) | **도입 확정** | `ENUM('NEW','REVIEWING','COMPLETE')` — 3종 확정 (`RESOLVED`/`DUPLICATE` 제외) |

---

### 3-5. 마이그레이션 SQL

개발(`dev`)은 `spring.jpa.hibernate.ddl-auto=update`라 자동 적용되나, 운영 머지 시 수동 실행 필요 (`docs/architecture/erd.md` §DDL 정책).

파일 위치 (기존 선례: `docs/ops/migrations/2026-04-todo-exp-system.sql`, `docs/ops/migrations/2026-04-alert-recurrence-redesign.sql`):

```
docs/ops/migrations/2026-04-bug-report.sql
```

내용 (확정):

```sql
CREATE TABLE IF NOT EXISTS bug_reports (
    bug_report_id BIGINT NOT NULL AUTO_INCREMENT,
    user_id       BIGINT NOT NULL,
    title         VARCHAR(100) NOT NULL,
    content       VARCHAR(500) NOT NULL,
    is_deleted    TINYINT(1) NOT NULL DEFAULT 0,
    status        ENUM('NEW','REVIEWING','COMPLETE') NOT NULL DEFAULT 'NEW',
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (bug_report_id),
    INDEX idx_bug_reports_user_id (user_id)
);
```

---

## 4. ErrorCode

### 4-1. 신규 prefix letter 비교

현재 사용 중인 letter (`docs/api/error-codes.md` §3): `G`, `A`, `U`, `T`, `M`, `I`, `S`, `N`, `C`

| 후보 letter | 의미 매칭 | 충돌 | 판정 |
|---|---|---|---|
| **`B`** | Bug Report의 B. 직관적 | 없음 | **채택** |
| `F` | Feedback의 F | 없음 | 의미 불명확 |
| `R` | Report의 R | 없음 | 일반적 |
| `E` | Error의 E (버그=오류) | 없음 | 혼동 가능(에러 코드 자체의 E로 오해) |

**채택 letter**: `B`

**새 enum**: `com.doitdo.global.exception.BugReportErrorCode` (구현 시 `ErrorCodeRegistry.SOURCES`에 등록 필수)

---

### 4-2. 신규 ErrorCode 목록 (초안)

> 자동 부착 코드(`G00-001`, `G00-006`, `G99-999` 등)는 `@ApiErrorCodes`에 명시 불필요 (`swagger.md` §3).

| 상수 | code | HTTP | 의미 | 필요 여부 |
|---|---|---|---|---|
| `B00_001` | `B00-001` | (미정) | 버그 신고 제목 누락 또는 형식 오류 | 추후 검토. `G00-006`(422) 자동 부착으로 대체 가능하므로 MVP에서는 생략 권장 |
| `B00_002` | `B00-002` | (미정) | 버그 신고 내용 누락 또는 형식 오류 | 추후 검토. 위와 동일 |
| `B00_003` | `B00-003` | 429 | 단시간 과다 신고 (rate limit) | rate limit 도입 결정 시 추가 |

> 추측: MVP 단계에서는 `G00-006` (`VALIDATION_FAILED`, 422 자동 부착)만으로 충분하며, `BugReportErrorCode` enum을 신설하되 초기에는 상수를 비워 두고 `ErrorCodeRegistry.SOURCES`만 등록하는 방안도 가능. 단, 후속 기능(rate limit, 중복 신고 감지 등) 대비 enum 파일 자체는 미리 생성 권장.

---

### 4-3. 기존 코드 재사용 여지

`CommonErrorCode.VALIDATION_FAILED` (`G00-006`, 422)가 자동 부착되므로, 입력 검증 실패를 별도 코드로 분리할 필요가 낮다.

`streak` 도메인 선례: `OpenApiConfig.java`에 `streak` GroupedOpenApi 빈이 존재하나 (`OpenApiConfig.java` `streak()` 빈), `ErrorCodeRegistry.java`의 `SOURCES` 리스트에는 `StreakErrorCode`가 없고 `UserErrorCode.U06-xxx`를 재사용. 즉 "신규 도메인 = 신규 ErrorCode enum 필수"가 아님. 그러나 `bugreport` 도메인은 향후 비즈니스 에러(rate limit, 상태 전환 등) 가능성이 높으므로 전용 enum 신설 권장.

---

## 5. Swagger / OpenAPI

### 5-1. 신규 그룹 추가

`OpenApiConfig.java`에 신규 빈 추가 필요:

```java
@Bean
public GroupedOpenApi bugreport() {
    return GroupedOpenApi.builder()
        .group("bugreport")
        .packagesToScan("com.doitdo.domain.bugreport.api.controller")
        .build();
}
```

현재 등록된 10개 그룹: `auth`, `user`, `todo`, `tamagotchi`, `streak`, `inventory`, `shop`, `notification`, `setting`, `global` (`OpenApiConfig.java` 전체 빈 목록).

> 참고: `docs/api/swagger.md` §1은 현재 "9개 그룹"으로 기록되어 있으며 `streak` 그룹이 누락된 상태 — stale 문서임. §8 참고.

---

### 5-2. 컨트롤러 어노테이션 패턴 (`swagger.md` §2)

```java
@Tag(name = "bugreport", description = "버그 신고 API")
@RestController
@RequestMapping("/api/bug-reports")
@RequiredArgsConstructor
public class BugReportController {

    private final BugReportService bugReportService;

    @Operation(summary = "버그 신고 접수", description = "제목과 내용을 입력해 버그를 신고한다. 이미지 첨부는 미지원(후속 이슈).")
    // @ApiErrorCodes({}) — 초기에는 B 계열 비즈니스 에러 없음. rate limit 도입 시 "B00-003" 추가
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public GlobalApiResponse<BugReportResp> create(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody CreateBugReportReq req) {
        return GlobalApiResponse.created(
                "버그 신고가 접수되었습니다.",
                bugReportService.create(userDetails.getUserId(), req));
    }
}
```

### 5-3. 자동 부착 응답 확인 항목 (`swagger.md` §3)

| 자동 부착 항목 | 확인 |
|---|---|
| 400 G00-001 | 자동 |
| 401 G00-002 / 403 G00-003 | `@PublicApi` 미부착 시 자동 |
| 422 G00-006 | `@Valid` 사용 시 자동 |
| 500 G99-999 | 자동 |

---

## 6. 보안 / 검증

### 6-1. 입력 검증 정책

| 항목 | 정책 | 구현 방법 |
|---|---|---|
| `title` nullable | 불가 | `@NotBlank` |
| `title` 길이 | 최대 100자 | `@Size(max = 100)` |
| `content` nullable | 불가 | `@NotBlank` |
| `content` 길이 | 최대 500자 **[확정]** | `@Size(max = 500)` |
| HTML/스크립트 인젝션 | 불필요 **[확정]** — 운영자 전용 내부 데이터, XSS 필터 미도입 | — |
| 욕설 필터 | 불필요 **[확정]** (MVP 미도입) | — |

### 6-2. XSS 방지

**확정: 미도입.** 버그 신고 내용은 운영자만 조회하는 내부 데이터. MVP 단계에서 서버 측 이스케이프 불필요. 운영자 대시보드 구현 시 해당 이슈에서 별도 검토.

### 6-3. Rate Limiting (어뷰징 방지)

**확정: MVP 미도입.** 인증 필수이므로 완전 무제한은 아님. 어뷰징 발생 시 후속 이슈에서 Bucket4j 등 도입.

| 방안 | 세부 | 권장 여부 |
|---|---|---|
| 서비스 레이어 검증 | DB에 저장된 최근 신고 건수 조회 | 간단하지만 DB 부하 |
| Spring 레벨 rate limiter (Bucket4j 등) | 라이브러리 추가 필요 | 추후 도입 |
| **MVP: 미도입** | 최소 구현. 스팸 발생 시 대응 | **채택 확정** |

### 6-4. 개인정보 / 보안

- 신고 내용에 민감 정보(비밀번호, 카드번호 등)가 포함될 수 있음. 운영자 접근 시 별도 열람 권한 정책 필요(후속).
- 신고자 `userId` 저장 → 사용자가 자신의 신고 철회 기능 요구 시 GDPR/개인정보보호법 고려 필요(후속).

---

## 7. 확정 의사결정 / 후속 작업

### 7-1. 확정 의사결정 (2026-04-30)

아래 7가지 항목은 팀 합의로 확정됨. 설계안 전체에 반영 완료.

| # | 항목 | 결정값 | 비고 |
|---|---|---|---|
| 1 | 익명(비로그인) 신고 허용 | **불허 — 인증 필수** | `@PublicApi` 미부착. `userId` NOT NULL. |
| 2 | `content` 최대 길이 | **500자** | 초안 2000자에서 변경. `Notification.message` 기준 통일. `VARCHAR(500)`. |
| 3 | 앱 메타정보 자동 수집 | **미수집** | `title` + `content` 만 저장. `appVersion` 등 범위 확장 없음. |
| 4 | Soft Delete (`is_deleted`) | **도입** | `TINYINT(1) DEFAULT 0`. `Notification` 패턴 동일 적용. |
| 5 | 처리 상태 컬럼 (`status`) | **도입 — NEW / REVIEWING / COMPLETE** | `ENUM('NEW','REVIEWING','COMPLETE') DEFAULT 'NEW'`. 3종 확정. |
| 6 | Rate Limiting | **MVP 미도입** | 인증 필수로 최소 제어. 어뷰징 발생 시 후속 이슈 대응. |
| 7 | XSS / 욕설 필터 | **불필요** | 운영자 전용 내부 데이터. MVP 미도입. |

### 7-2. 확정된 후속 작업 (이슈 범위 외)

| 항목 | 상태 |
|---|---|
| 이미지 첨부 업로드 | 후속 이슈 (JIRA S14P31D107-442 명시: "이미지 없이") |
| 운영자 대시보드 — 목록 조회, 상태 변경 | 별도 이슈 필요 |
| 알림 (슬랙/이메일) 연동 | 별도 이슈 필요 |
| 사용자 신고 목록/삭제 | 별도 이슈 필요 |

---

## 8. 영향받는 docs 목록 (코드 머지 시 동시 갱신)

코드 구현 PR 머지 시 아래 문서를 **같은 PR 안에서 갱신**한다 (`CLAUDE.md` 규칙).

| 문서 | 갱신 내용 |
|---|---|
| `docs/architecture/package-layout.md` | 등록된 도메인 목록에 `bugreport` 추가. 도메인 5종 디렉토리 패턴 표 항목 추가. |
| `docs/architecture/erd.md` | 도메인 ↔ 테이블 매핑 표에 `bugreport \| bug_reports` 행 추가 |
| `docs/api/error-codes.md` | `BugReportErrorCode` 신규 enum 추가. 접두 letter `B` 선언. 상수 목록 추가. |
| `docs/api/swagger.md` | (1) 현재 누락된 `streak` 그룹 추가 ("9개" → "11개", 또는 그룹 목록에 streak·bugreport 동시 추가). (2) `bugreport` 그룹 신규 등재. |
| `docs/ops/migrations/2026-04-bug-report.sql` | 신규 파일. `bug_reports` 테이블 DDL (§3-5 참고) |
| `global/config/OpenApiConfig.java` | `GroupedOpenApi bugreport()` 빈 추가 (코드 변경) |
| `global/exception/ErrorCodeRegistry.java` | `SOURCES`에 `BugReportErrorCode.class` 추가 (코드 변경) |

---

## 부록 — 권장안 요약

| 항목 | 권장안 |
|---|---|
| 엔드포인트 | `POST /api/bug-reports` |
| HTTP 메서드 | `POST` |
| 도메인 패키지 | `com.doitdo.domain.bugreport` |
| 엔티티 / 테이블 | `BugReport` / `bug_reports` |
| PK 필드 | `bugReportId` / `bug_report_id` |
| ErrorCode prefix | `B` (신규 `BugReportErrorCode` enum) |
| 인증 | 필수 (`@AuthenticationPrincipal`, `@PublicApi` 미부착) |
| 응답 상태 | 201 Created |
| MVP 범위 | 제목 + 내용 저장. 이미지/상태/조회 API는 후속. |
