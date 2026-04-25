# Session 2 Kickoff — Notion/JIRA 하네스 Phase 1 착수

**원 핸드오프**: [`handoff-notion-jira-harness.md`](handoff-notion-jira-harness.md) (반드시 같이 읽기)
**이 파일**: 1차 세션 결정·진행 사항 + 2차 세션 즉시 착수 지침
**전 세션 일자**: 2026-04-24

---

## 1. 1차 세션에서 확정된 결정 (§7 답)

### 1.1 SSOT 경계 — 레포(Git) authoritative
- 하네스 산출물(컨벤션 문서·slash command·linter)은 무조건 `be/docs/conventions/` 에 머지
- 근거: 다른 팀원 로컬 에이전트도 동일 컨벤션으로 동작해야 함 → 노션 fetch 의존이 아니라 Git 체크아웃으로 즉시 확보 가능해야 함
- 노션 SSOT 원칙(`be/CLAUDE.md`)은 일반 설계·API 명세에만 적용. 하네스 인프라엔 적용 안 됨
- 메모리: [feedback_harness_artifacts_in_git.md](../../../.claude/projects/-home-cbkjh0225-project-ssafyTodo-S14P31D107/memory/feedback_harness_artifacts_in_git.md) (자동 로드됨)

### 1.2 빈도·규모 — 1회 큰 최신화 + 이후 미정
- 함의: 그 1회 작업과 하네스 구축을 병행. 실전 작업이 곧 하네스 검증

### 1.3 검증 정책 — Linter 자동 + 사용자 승인 후 publish
- 가장 보수적. Phase 4 linter(정규식 + 필수속성 체크) 필수
- 외부 시스템(Notion/JIRA) publish 직전엔 항상 사용자 한 번 확인

---

## 2. 1회 큰 최신화의 대상 영역

- **JIRA**: 이슈 상태/코멘트 동기화 (코드·MR 매칭 후 완료 전환)
- **Notion**: API 명세 / 설계 페이지 갱신

이 두 영역이 곧 Phase 1 샘플링·스타일 추출의 우선 영역이며 Phase 3 slash command(`/jira-sync-v2`, `/notion-update`) 의 첫 적용 대상.

---

## 3. Phase 1 샘플링 범위 (확정)

### JIRA
- 프로젝트 키: `S14P31D107`
- 필터: **BE 에픽 한정** + **김재환(cbkjh0225@gmail.com) 담당** + **최근 60일 활동**
- 도구: `Jira/.venv/bin/python search_issues.py --jql "..."` → `TEMP_FILE_PATH` md Read
- 보조 문서: `Jira/jiraconvention.md`, `Jira/LLM_GUIDE.md`
- 메모리: [reference_jira_tooling.md](../../../.claude/projects/-home-cbkjh0225-project-ssafyTodo-S14P31D107/memory/reference_jira_tooling.md), [feedback_jira_story_title.md](../../../.claude/projects/-home-cbkjh0225-project-ssafyTodo-S14P31D107/memory/feedback_jira_story_title.md)

### Notion
- 단일 워크스페이스 루트 하나 있음 (1차 세션에선 URL 미공유)
- 접근: **Notion MCP**(2차 세션부터 노출). `mcp__notion__API-search` 로 "doitdo" 키워드 검색해서 워크스페이스 루트 자동 탐색 → 거기서 페이지 트리 순회

---

## 4. Notion MCP 셋업 결과 (1차 세션 완료)

- 등록: `~/.claude.json` user scope, name=`notion`, transport=stdio
- Command: [/home/cbkjh0225/.local/bin/notion-mcp-launcher](/home/cbkjh0225/.local/bin/notion-mcp-launcher) (WSL 에서 Windows `node.exe` 가 `env node` 로 잡히는 함정 회피용 wrapper)
- 토큰: env `OPENAPI_MCP_HEADERS` 에 평문. **`~/.claude.json` 에만 존재**, wrapper·메모리·docs·커밋 어디에도 없음
- 1차 검증: `claude mcp get notion` → `Status: ✓ Connected`
- **2차 세션 첫 검증**: `ToolSearch "notion"` 으로 `mcp__notion__API-*` 도구 스키마 노출 확인. 안 보이면 사용자에게 즉시 보고

---

## 5. 2차 세션 즉시 착수 액션

1. 본 파일 + 원 핸드오프 두 개 모두 Read
2. 핵심 메모리 본문 로드 (원 핸드오프 §8.1 목록 + 신규 `feedback_harness_artifacts_in_git.md`)
3. **ToolSearch "notion"** → MCP 도구 스키마 확인. 실패 시 stop & 사용자 호출
4. `mcp__notion__API-search` 로 "doitdo" 검색 → 워크스페이스 루트 page-id 확보
5. 위임 라우팅 (병렬):
   - **JIRA 패턴 추출** → Sonnet 서브에이전트, `run_in_background: true`
     - 프롬프트: BE 에픽 + 김재환 담당 + 최근 60일 이슈 메타·본문·코멘트 수집 → 제목/본문/라벨/상태전이/코멘트 톤 패턴 도출 → 마크다운 보고
     - 도구: Bash(Jira/.venv/bin/python search_issues.py …), Read
   - **Notion 패턴 추출** → Sonnet 서브에이전트, `run_in_background: true`
     - 프롬프트: 4번에서 받은 루트 page-id 부터 트리 순회 → 헤딩 레벨/속성/이모지/테이블/링크/체크박스 패턴 도출 → 마크다운 보고
     - 도구: `mcp__notion__API-*` 직접 호출
6. 두 결과 합성 → 컨벤션 문서 초안 작성:
   - [`be/docs/conventions/notion-style.md`](../conventions/notion-style.md)
   - [`be/docs/conventions/jira-style.md`](../conventions/jira-style.md)
   - 각 문서에 **정규식 규칙 + 풀텍스트 실례 5~10개** 포함 (안티패턴 §9-1 방지)
7. 사용자 리뷰 받고 Phase 2 진입 결정

---

## 6. 위임 라우팅 명세 (1차 세션 메모리 기준)

- **단순 탐색·패턴 추출** → Sonnet (`model: "sonnet"`), 항상 `run_in_background: true`
- **다수 파일 동시 작성·linter 코드(Phase 3·4)** → Codex (`--background --write`, plan 파일 선행 필수, "CDP MCP 절대 금지" 문구 필수, `docs/logs/codex.txt` 기록)
- **합성·판단·컨벤션 초안 작성** → Claude 본인(head agent 역할). 단 1~3줄 편집 외엔 위임 우선
- 메모리: [feedback_session_claude_subagent.md](../../../.claude/projects/-home-cbkjh0225-project-ssafyTodo-S14P31D107/memory/feedback_session_claude_subagent.md), [feedback_subagent_model_sonnet.md](../../../.claude/projects/-home-cbkjh0225-project-ssafyTodo-S14P31D107/memory/feedback_subagent_model_sonnet.md), [feedback_codex_no_cdp.md](../../../.claude/projects/-home-cbkjh0225-project-ssafyTodo-S14P31D107/memory/feedback_codex_no_cdp.md)

---

## 7. 산출물 위치 (확정)

| 산출물 | 위치 | Phase |
|---|---|---|
| Notion 스타일 가이드 | `be/docs/conventions/notion-style.md` | 1·2 |
| JIRA 스타일 가이드 | `be/docs/conventions/jira-style.md` | 1·2 |
| 예시 팩 | `be/docs/conventions/examples/` | 1·2 |
| Notion slash command | `be/.claude/commands/notion-update.md` | 3 |
| JIRA slash command v2 | `be/.claude/commands/jira-sync-v2.md` | 3 |
| Linter 스크립트 | `be/scripts/lint/` 또는 `Jira/lint/` | 4 |

---

## 8. 안티패턴 재확인 (원 핸드오프 §9)

1. 한 줄 요약 컨벤션 금지 → **정규식 + 5개 이상 실례** 로 고정
2. 검증 없이 publish 금지 → Linter 통과해도 사용자 승인 필수
3. 핸드오프 문서 미커밋 금지 → 본 파일과 원 핸드오프는 별도 브랜치(`be/docs/notion-jira-harness-plan` 권장) 에 묶어 MR 가능
4. Codex CDP MCP 사용 금지 → 위임 프롬프트 끝에 항상 "CDP MCP 절대 금지" 명시
5. MR 템플릿 무시 금지 → `.gitlab/merge_request_templates/default.md` 섹션 그대로

---

## 9. 1차 세션에서 진행하지 않은 항목

- 컨벤션 문서 초안 (Phase 1 결과물)
- Slash command 작성 (Phase 3)
- Linter 작성 (Phase 4)
- 핸드오프 파일 commit (1차 세션은 untracked 로 남김 — 2차 세션에서 별도 브랜치로 묶어 commit 권장)

---

## 10. 한 줄 프롬프트 (새 세션 시작 시 사용)

> `be/docs/plans/handoff-notion-jira-harness.md` 와 `handoff-notion-jira-harness-session2.md` 둘 다 읽고 session2 §5 즉시 착수 액션부터 진행. ToolSearch "notion" 으로 MCP 검증 먼저, 실패 시 stop & 보고.
