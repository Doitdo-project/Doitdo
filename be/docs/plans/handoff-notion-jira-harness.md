# Handoff — Notion / JIRA 최신화 서브에이전트 하네스 엔지니어링

**상태**: NEW — 새 세션에서 착수 예정  
**원 세션 요청 일자**: 2026-04-24  
**작성**: Claude Opus 4.7 (원 세션 Head)

---

## 1. 한 줄 요약

> Notion / JIRA 최신화 작업을 서브에이전트에게 위임할 때, 기존 팀의 스타일·컨벤션을 **철저히** 준수하도록 사전 "하네스 (harness)" 를 설계·구축한다. 매 작업마다 프롬프트로 반복 설명하지 않아도 품질이 보장되는 재사용 가능한 구조를 만드는 게 목표.

---

## 2. 배경

프로젝트(doitdo) 는 BE / FE / INFRA 로 구성된 SSAFY 최종 프로젝트이며, 노션이 설계·API 명세·컨벤션의 SSOT (`be/CLAUDE.md` 명시), JIRA 는 스토리·태스크 트래킹의 SSOT. 지금까지 서브에이전트 위임 시 **프롬프트에 컨벤션을 매번 수작업으로 주입** 해왔고, 그 결과:

- MR 템플릿 무시 (2026-04-24 발생 — `feedback_mr_template.md` 메모리로 조치)
- JIRA 스토리 제목 컨벤션 위반 가능성 — `feedback_jira_story_title.md` 로 이미 1회 조치
- Notion 페이지 스타일은 문서화 전혀 안 됨

"최신화" 작업(스프린트 종료 시 JIRA 상태 동기화, Notion API 명세 갱신 등) 이 앞으로 반복될 예정이라, 일회성 프롬프트 조정이 아니라 **재사용 가능한 하네스** 가 필요하다.

---

## 3. 현재 확보된 자산

### 3.1 코드·스크립트

- `Jira/` 디렉터리: JIRA 이슈 조작용 Python 스크립트 (메모리 `reference_jira_tooling.md` 참조)
- `~/.codex/config.toml` 의 `[mcp_servers.notion]`: Notion MCP 엔드포인트 이미 등록 (`url = "https://mcp.notion.com/mcp"`)
- `/jira-sync` 슬래시 명령: 기존 JIRA 동기화 루틴 (Haiku 위임 패턴 — 메모리 참조)

### 3.2 메모리 (현 세션 기준, `~/.claude/projects/.../memory/`)

| 파일 | 한 줄 |
|---|---|
| `feedback_jira_story_title.md` | JIRA 스토리는 "사용자는 ~하고 싶다" 서술형. Feat/Fix prefix 는 하위작업·Task 전용 |
| `reference_jira_tooling.md` | `Jira/` Python 스크립트 + `/jira-sync` + Haiku 위임 패턴 |
| `project_mr_title_convention.md` | `[BE : type] 작업내용` (참고용, Git 쪽 컨벤션) |
| `feedback_mr_template.md` | `.gitlab/merge_request_templates/default.md` 섹션 그대로 (동일 원리 — 템플릿 무시 금지) |
| `feedback_language_korean.md` | 한국어 소통 |
| `feedback_head_agent_role.md` | Claude 는 총괄·판단. 분석·수정은 위임 |

### 3.3 없는 것 (gap)

- **Notion 페이지 스타일 문서화 전무**  
  - 헤딩 레벨 관습 / 속성(tags, status, owner, date) 사용법 / 이모지 헤더 / 체크박스 쓸 곳 / 테이블 포맷 / 링크 표기 등
- **JIRA 서브태스크·코멘트·상태전이 규칙 문서화 전무**  
  - 스토리 제목만 메모리로 있고 태스크·서브태스크·코멘트·상태 변경 코멘트 같은 하위 단위는 공식 규약 없음
- **자동 검증 훅 없음**  
  - 에이전트가 생성한 Notion/JIRA 출력이 컨벤션 준수했는지 사후 확인할 방법이 없음
- **하네스화된 슬래시 명령 없음**  
  - `/jira-sync` 외엔 JIRA / Notion 에 관한 재사용 가능한 명령 없음. 특히 Notion 쪽은 전무

---

## 4. 목표 결과물 (Desired State)

1. **컨벤션 문서** (SSOT 위치는 아래 "열린 결정" 참조)
   - Notion 스타일 가이드 (헤딩·속성·이모지·테이블·링크 규약)
   - JIRA 컨벤션 전체 (제목·본문·라벨·우선순위·상태 전이·코멘트 톤·서브태스크 구조)
2. **예시 팩** — 모방 가능한 풀텍스트 실례 5~10개씩 (Notion 페이지 / JIRA 이슈)
3. **슬래시 명령 또는 프롬프트 템플릿**
   - `/notion-update <page-id> <diff-summary>` — 페이지 갱신 시 컨벤션 자동 준수
   - `/jira-sync` 를 "사용자 의도 → JIRA 작업" 경로로 확장·고도화 (현재는 단순 동기화)
4. **검증 훅**
   - 제목 정규식 linter (예: `^사용자는 .+ 싶다$` for 스토리)
   - 속성 완전성 체크 (Notion: 필수 속성 미기입 시 거부 / JIRA: assignee·label 누락 거부)
   - 선택: GitHub Actions 또는 로컬 pre-commit 훅으로 구동
5. **"하지 말 것" 리스트** (memory 누적)
   - 이번 하네스 구축 중·이후 에이전트가 저지른 실수들을 `feedback_*.md` 로 계속 적재

---

## 5. 경로 옵션

### 옵션 A — 빠른 경로 ("그냥 돌리고 메모리 누적")

- 지금 당장 Notion/JIRA 최신화 작업 시, 서브에이전트 프롬프트에:
  1. 기존 메모리 규칙 5~6개 포인터 나열
  2. 참고할 기존 샘플 URL 5개 "이 스타일 모방하라" 명시
  3. 결과 검증은 사용자가 수동
- 실수 발견 시 `feedback_*.md` 로 메모리에 꽂기만 하고 다음 작업에 반영
- **적합**: 최신화가 월 1회 수준이고 일회성 성격이면 이게 ROI 높음

### 옵션 B — 하네스 우선 경로 (권장, 사용자 요청에 더 가까움)

Phase 1 → Phase 4 순서.

**Phase 1. 읽기 전용 탐색 (subagent-ro)**
- 최근 머지·유의미한 JIRA 이슈 20~30개 샘플링
- Notion 루트 페이지 트리 순회 → 주요 페이지 10~20개 샘플링
- 패턴 추출: 제목 / 본문 구조 / 속성 사용 / 이모지 / 테이블 / 링크 포맷 / 수정 이력 톤
- 결과물: `be/docs/conventions/notion-style.md`, `be/docs/conventions/jira-style.md` 초안

**Phase 2. 컨벤션 문서 확정 (사용자 리뷰)**
- Phase 1 초안 읽고 미진한 규칙 보강, 애매한 항목 결정
- SSOT 경계 확정 — 아래 "열린 결정" 참조
- MR 로 코드베이스에 머지 (CLAUDE.md 규칙 — docs 는 코드와 같이 머지)

**Phase 3. 하네스 프롬프트 빌더 (slash command 설계)**
- `/notion-update`, `/jira-sync-v2` 같은 slash command 또는 subagent definition 추가
- 시스템 프롬프트에 Phase 2 문서 **전문 로드**
- "컨벤션 문서 위반 출력 금지" 가드 + 출력 자가검증 단계 포함

**Phase 4. 자동 검증 훅**
- Python/bash linter 스크립트 (정규식 + 필수속성 체크)
- 에이전트 출력이 linter 통과할 때까지 재시도, 3회 실패 시 사용자 에스컬레이트
- 선택: pre-commit 또는 GitHub Actions 로 다른 사람이 수동 편집한 것도 검사

**옵션 B 권장 이유**
- 사용자가 명시적으로 "하네스 엔지니어링" 요구
- Notion 쪽 컨벤션이 문서화 전무 — 한 번 투자하면 FE·INFRA 팀원도 혜택
- 한 번 구축하면 Haiku 같은 저비용 모델로도 고품질 출력 기대

---

## 6. 새 세션 즉시 착수 체크리스트 (Phase 1 기준)

1. [ ] 이 파일 전문 읽기 + 참조 메모리들 로드
2. [ ] 사용자와 **열린 결정 3가지** 확정 (아래 §7)
3. [ ] JIRA 샘플링 범위 확정 (프로젝트 키, 기간, 이슈 타입 분포)
4. [ ] Notion 샘플링 범위 확정 (루트 페이지 URL, 깊이)
5. [ ] 읽기 전용 subagent 위임 프롬프트 작성 — 출력 포맷까지 명시
6. [ ] Subagent 결과 수령 → 사용자 리뷰 → Phase 2 진입 결정

---

## 7. 열린 결정 (반드시 사용자와 확정 후 착수)

### 7.1 SSOT 경계

- **시나리오 A**: 노션이 컨벤션 SSOT → `be/docs/conventions/notion-style.md` 는 링크만 담는 shim
- **시나리오 B**: 레포가 SSOT (Git 이 authoritative), 노션에 요약만 복제
- **시나리오 C**: 영역별로 분할 (예: API 스펙 = 노션, 프로젝트 컨벤션 = Git)

기존 `be/CLAUDE.md` 에 "노션이 SSOT" 명시 있음 → 디폴트는 A. 단 컨벤션처럼 "자주 변하지 않고 기계가 읽어야 하는" 문서는 B 가 적합할 수 있음.

### 7.2 최신화 작업의 빈도와 규모

- 월 1회 / 스프린트 종료마다 / 매 MR 머지마다?
- 한 번에 갱신할 페이지·이슈 평균 개수?
- 이에 따라 옵션 A 와 B 의 ROI 가 갈림

### 7.3 검증 엄격도

- "lint 실패 시 3회 재시도 후 에스컬레이트" 가 적절한가, 아니면 사용자 수동 검토 항상 필수인가?
- 출력이 Notion/JIRA 에 publish 되기 전 별도 승인 단계 필요?

---

## 8. 반드시 참조할 기존 자료

### 8.1 메모리 (필수 로드 — 특히 항상 적용되는 feedback 류)

- `~/.claude/projects/-home-cbkjh0225-project-ssafyTodo-S14P31D107/memory/MEMORY.md` 인덱스 먼저 훑기
- 다음 파일들 본문 로드:
  - `feedback_jira_story_title.md`
  - `reference_jira_tooling.md`
  - `feedback_mr_template.md`
  - `feedback_head_agent_role.md`
  - `feedback_session_claude_subagent.md`
  - `feedback_subagent_model_sonnet.md`
  - `feedback_codex_no_cdp.md`
  - `feedback_language_korean.md`

### 8.2 레포 내 참고 경로

- `be/CLAUDE.md` — docs 동시 갱신 규칙, 노션 SSOT 원칙
- `be/AGENTS.md` — BE 작업 진입점
- `be/docs/` 전체 — 현 문서 스타일 참고
- `Jira/` — 기존 Python 스크립트 스타일
- `.gitlab/merge_request_templates/default.md` — MR 템플릿 예시 (Notion/JIRA 쪽도 유사한 탑레벨 템플릿 필요할 수 있음)

### 8.3 외부 시스템 접근

- Notion MCP: `~/.codex/config.toml` 의 `[mcp_servers.notion]` (Claude Code 세션에선 `mcp__notion__API-*` 도구로 노출 — `ToolSearch` 로 스키마 로드 필요)
- JIRA: `Jira/` Python CLI (토큰 위치는 메모리 `reference_jira_tooling.md` 확인)

---

## 9. 안티패턴 (하지 말 것)

1. **프롬프트에 컨벤션 한 줄로 요약만 넣기** — "JIRA 제목은 서술형" 만으론 에이전트가 "사용자는 ~하고 싶어한다" vs "사용자는 ~하고싶다" 같은 미묘한 편차를 만든다. 규칙은 정규식 또는 5개 이상 실례로 고정.
2. **검증 없이 publish** — Notion/JIRA 는 외부 시스템이라 되돌리기 번거로움. 하네스 완성 전까진 사용자 승인 단계 필수.
3. **이 핸드오프 문서 자체를 commit 안 하고 잊기** — 아래 "커밋 정책" 참조.
4. **Codex CDP MCP 사용** — 이번 작업은 Claude Code 쪽 MCP (`mcp__notion__*`) 로 수행. Codex 위임 시엔 무조건 "CDP MCP 금지" 명시.
5. **MR 템플릿 무시** — `.gitlab/merge_request_templates/default.md` 섹션 그대로 사용. Notion/JIRA 쪽도 비슷한 템플릿 체계 만들면 동일 원칙.

---

## 10. 커밋 정책

이 핸드오프 문서 자체는 **세션 간 인수인계용**. 선택지:

- **선호**: 별도 브랜치 `be/docs/notion-jira-harness-plan` 에 단독 커밋 후 MR 로 dev 머지 — 팀원도 볼 수 있고 영구 보존
- **대안**: 로컬 파일로만 두고 새 세션이 workspace 진입 시 Read 로 로드 — 빠르지만 휘발 위험

**권장**: 선호 경로. Phase 1 착수 전 또는 Phase 2 문서들과 함께 머지하면 자연스러움.

---

## 11. 컨텍스트 이동 시 한 줄 프롬프트 예시

새 세션에서 이 작업을 집을 때 사용자가 주면 되는 프롬프트:

> `be/docs/plans/handoff-notion-jira-harness.md` 읽고 Phase 1 착수. 열린 결정 3가지 먼저 물어보고 내 답 받은 뒤 subagent 위임.

---

## 12. 원 세션에서 병렬 진행 중이던 작업 (상호 간섭 없음, 참고만)

- `be/chore/e2e-sync-current-apis` — MR !86 (e2e 스크립트 동기화), 머지 대기
- `be/fix/withdraw-detached-entity` — MR !84 (withdraw detached entity 버그 수정), 머지 대기
- MR 순서 전략: !84 먼저 → !86 을 dev 로 rebase → step_withdraw 401 assertion 추가 → !86 머지

Notion/JIRA 하네스 작업은 위 브랜치들과 파일 경로가 겹치지 않아 병행 가능. 단 `be/docs/plans/` 아래는 둘 다 건드리므로 머지 순서만 주의.
