# doitdo BE — docs/ 인덱스

`be/AGENTS.md` 가 진입점이다. 상세 문서는 모두 이 디렉토리 아래 있다.
변경된 컨벤션은 항상 노션이 SSOT (단일 진실 출처).

## 카테고리

### architecture/ — 시스템 구조
- [`overview.md`](architecture/overview.md) — 모듈/계층 개요
- [`package-layout.md`](architecture/package-layout.md) — `com.doitdo` 패키지 + DDD 5종 디렉토리 패턴
- [`erd.md`](architecture/erd.md) — ERD 위치 + 도메인 ↔ 테이블 매핑

### conventions/ — 팀 규칙
- [`README.md`](conventions/README.md) — 노션 SSOT 표 + 상세 문서 라우팅
- [`git.md`](conventions/git.md) — 브랜치 / 커밋 / MR
- [`jira.md`](conventions/jira.md) — 일감 / 제목 / 도메인
- [`naming.md`](conventions/naming.md) — Controller / Service / Repository / DTO / Entity 네이밍 + 엔티티 규칙

### api/ — API 작성 규약
- [`response-format.md`](api/response-format.md) — `GlobalApiResponse<T>` 사양
- [`error-codes.md`](api/error-codes.md) — `ErrorCode` 인터페이스 + 9개 도메인 enum + Registry
- [`swagger.md`](api/swagger.md) — 컨트롤러 작성 가이드 (핵심 산출물)

### ops/ — 환경/실행
- [`env-setup.md`](ops/env-setup.md) — JDK 21 + `env/.env.dev` 셋업
- [`run-local.md`](ops/run-local.md) — `bootRun` + 헬스체크 + Swagger UI
- [`deployment.md`](ops/deployment.md) — 배포 절차 (placeholder, INFRA 팀 자료 후속 정리)

## 자주 찾는 항목

| 작업 | 문서 |
|---|---|
| 새 컨트롤러 작성 | [`api/swagger.md`](api/swagger.md) |
| 새 도메인 패키지 추가 | [`architecture/package-layout.md`](architecture/package-layout.md) |
| 새 ErrorCode 추가 | [`api/error-codes.md`](api/error-codes.md) |
| 커밋 메시지 형식 | [`conventions/git.md`](conventions/git.md) |
| 로컬 부팅 | [`ops/run-local.md`](ops/run-local.md) |
