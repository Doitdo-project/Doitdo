# doitdo BE — Claude entry point

이 파일은 호환성 stub 입니다. **실제 가이드는 [`AGENTS.md`](AGENTS.md) 를 읽으세요.**

- BE 작업 진입점: [`AGENTS.md`](AGENTS.md)
- 상세 가이드: [`docs/`](docs/)
- 변경된 컨벤션은 항상 노션이 SSOT.

---

## ⚠️ 항상 따라야 할 규칙 (별도 파일로 빼지 말 것)

**docs/ 의 모든 문서(아키텍처 / 컨벤션 / API / ops)에 영향을 주는 코드·설계 변경이 발생하면, 같은 PR 안에서 관련 docs 를 무조건 갱신한다.**

- 코드만 머지하고 docs 갱신을 후속 PR로 미루지 않는다 (실제 상태와 docs 가 어긋나면 다른 에이전트·동료가 잘못된 정보로 작업한다).
- 갱신 대상 예시:
  - 패키지 구조 / 새 도메인 추가 → `docs/architecture/package-layout.md`, `docs/architecture/overview.md`
  - 응답 포맷 / 정적 팩토리 변경 → `docs/api/response-format.md`
  - ErrorCode 추가·삭제·코드 형식 변경 → `docs/api/error-codes.md`
  - Swagger 어노테이션·자동 부착 동작 변경 → `docs/api/swagger.md`
  - 환경 변수 / 부팅 절차 변경 → `docs/ops/env-setup.md`, `docs/ops/run-local.md`
  - 컨벤션(Git/JIRA/네이밍) 변경 → `docs/conventions/*` (단, 노션이 SSOT 면 노션 먼저)
- 변경이 노션 페이지에도 영향을 주면 노션 갱신과 docs 갱신을 같이 한다.
