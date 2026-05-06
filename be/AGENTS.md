# doitdo BE — Agent Guide

> 모든 LLM 에이전트(Claude / Codex / Cursor 등) 와 새 합류자는 BE 작업 전에 이 문서를 먼저 읽는다.
> 상세 규칙은 `docs/` 하위에 있고, 변경된 컨벤션은 항상 노션이 SSOT (단일 진실 출처) 다.

---

## 0. 가장 먼저 (체크리스트)

- [ ] 작업 시작 전 노션 컨벤션 1회 확인 (§ 2 표).
- [ ] 새 컨트롤러 작성 시: [`docs/api/swagger.md`](docs/api/swagger.md) 필독.
- [ ] 새 도메인 패키지 추가 시: [`docs/architecture/package-layout.md`](docs/architecture/package-layout.md) 의 5종 디렉토리 패턴 따르기.
- [ ] ErrorCode 추가 시: [`docs/api/error-codes.md`](docs/api/error-codes.md) — `ErrorCodeRegistry.SOURCES` 등록 잊지 말기.
- [ ] 커밋/MR 전: [`docs/conventions/git.md`](docs/conventions/git.md) 형식 준수, **`dev` 직접 push 금지**.

---

## 1. 프로젝트 한눈에

- 서비스: **doitdo** (TODO + 다마고치)
- 스택: Spring Boot 3.5.13 / Java 21 / Gradle / MariaDB / JPA / Redis / Spring Security
- 패키지 루트: `com.doitdo`
- 진입점: `com.doitdo.DoitdoApplication`
- 활성 프로파일: `dev` (원격 테스트 DB)
- 빠른 실행: → [`docs/ops/run-local.md`](docs/ops/run-local.md)
- 환경 셋업: → [`docs/ops/env-setup.md`](docs/ops/env-setup.md)

---

## 2. 노션 컨벤션 (SSOT)

| 영역 | 노션 |
|---|---|
| 팀 규칙 (허브) | <https://www.notion.so/e158ab5fe9a983ab9e2d014ea5209a51> |
| Git Convention | <https://www.notion.so/3448ab5fe9a98068bf77d1f7a8164045> |
| JIRA Convention | <https://www.notion.so/3448ab5fe9a980ff9da9ff5bc5094ec4> |
| BE Convention | <https://www.notion.so/3458ab5fe9a980b7a026f4652db8b2c8> |
| API 기본 명세서 | <https://www.notion.so/3428ab5fe9a980c790a6f9161a900f22> |

요약 미러: [`docs/conventions/README.md`](docs/conventions/README.md).

---

## 3. 상세 가이드 (`docs/`)

- 아키텍처: [`overview`](docs/architecture/overview.md) / [`package-layout`](docs/architecture/package-layout.md) / [`erd`](docs/architecture/erd.md)
- 컨벤션: [`git`](docs/conventions/git.md) / [`jira`](docs/conventions/jira.md) / [`naming`](docs/conventions/naming.md)
- API: [`response-format`](docs/api/response-format.md) / [`error-codes`](docs/api/error-codes.md) / [`swagger`](docs/api/swagger.md)
- 운영: [`env-setup`](docs/ops/env-setup.md) / [`run-local`](docs/ops/run-local.md) / [`deployment`](docs/ops/deployment.md)

전체 인덱스: [`docs/README.md`](docs/README.md).

---

## 4. 새 컨트롤러 작성 워크플로 (필독)

1. 도메인 패키지 5종 디렉토리 위치 확인 (`api/{controller, dto/{req, resp}}`, `application/impl/`, `entity/`, `repository/`).
2. ErrorCode 추가 필요 시 도메인 enum 에 추가 + 노션 SSOT 동기화 + 새 enum 이면 `ErrorCodeRegistry.SOURCES` 등록.
3. Controller 작성 — [`docs/api/swagger.md`](docs/api/swagger.md) §2 의 템플릿 복붙.
4. 반환 타입은 반드시 `GlobalApiResponse<T>` (성공/실패 모두). 실패는 `CustomException` 던지면 `GlobalExceptionHandler` 가 변환.
5. 부팅 후 Swagger UI (<http://localhost:8080/swagger-ui.html>) 에서 모든 응답이 의도대로 노출되는지 확인.

---

## 5. 흔한 실수 / 안티패턴

1. **`@ApiErrorCodes` 에 enum 이름 사용** — 항상 `getCode()` 문자열 (`"A00-001"`), 절대 `"A00_001"` 이나 enum 이름 X.
2. **`dev` 브랜치 직접 push** — 모든 변경은 feature 브랜치 → MR.
3. **FK를 `@ManyToOne` 으로 매핑** — 도메인 격리 위해 Long ID 필드로만 보관.
4. **반환 타입을 raw DTO 로 노출** — 응답은 항상 `GlobalApiResponse<T>` 로 감싼다.
5. **새 ErrorCode enum 추가 후 Registry 등록 누락** — `ErrorCodeRegistry.SOURCES` 에 클래스 추가 안 하면 `@ApiErrorCodes` 에서 코드 인식 안 됨.
6. **컨트롤러 위치 오류** — `com.doitdo.domain.{group}.api.controller` 경로가 아니면 Swagger 그룹에 안 잡힌다.

---

## 6. 다른 LLM/에이전트용 노트

- **`AGENTS.md` = 모든 모델 표준 진입점.** Claude / Codex / Cursor 모두 이 파일을 먼저 읽도록 컨벤션 통일.
- `CLAUDE.md` 는 호환성 stub — 이 파일을 가리키기만 한다.
- 작업 분배 권장:
  - 단순 복제/편집/리팩토링: Sonnet 급.
  - 무거운 분석/설계/리뷰: Opus / Codex 급.
- 새 컨벤션이 도입되면 갱신 순서: **노션 → `docs/` → `AGENTS.md` 의 §2 표 / 체크리스트**.
- 본 문서는 라우터로 짧게 유지 (목표 80~120줄). 실제 내용은 `docs/` 로 분산.
