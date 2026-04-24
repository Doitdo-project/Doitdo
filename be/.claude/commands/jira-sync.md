---
description: JIRA 이슈 조회·생성·상태변경을 Haiku/Sonnet 서브에이전트에 위임 (Jaeboong/Jira_automation CLI)
---

# /jira-sync — JIRA 하네스

사용자가 `/jira-sync` 를 호출하면 JIRA 이슈 상태 동기화 작업을 수행한다.
Claude(Head)는 **계획·검증만** 하고, 실제 JIRA CLI 호출은 **Haiku/Sonnet 서브에이전트에 위임**한다.

> 컨벤션 SSOT: [`be/docs/conventions/jira.md`](../../docs/conventions/jira.md) (정규식·실례·결정 추적). 본 슬래시 명령은 그 SSOT 의 운영 절차.

---

## Phase 0 — Jira CLI 위치 탐색 (필수)

동료마다 레포 클론 위치가 다를 수 있으므로 **절대 경로를 하드코딩하지 말고** 매 호출 시 탐색한다.

### 탐색 순서

1. 환경변수 `JIRA_DIR` 이 설정돼 있고 `$JIRA_DIR/.venv/bin/jira` 가 존재하면 그걸 사용
2. 아래 후보를 순서대로 `pyproject.toml` (project name = `jira-automation`) 또는 `.venv/bin/jira` 존재 여부로 확인:
   - `./Jira`
   - `../Jira`
   - `../../Jira`
   - `$(git rev-parse --show-toplevel 2>/dev/null)/Jira`
   - `$(git rev-parse --show-toplevel 2>/dev/null)/../Jira`
3. 후보 중 어느 하나라도 맞으면 그 절대 경로를 확정
4. 모두 실패하면 **사용자에게 질문**: "Jira_automation 디렉터리(`pyproject.toml` 의 `name = jira-automation` 가 들어있는 곳) 의 절대 경로를 알려주세요. (예: `/home/you/project/Jira`)". 사용자가 답한 경로도 마찬가지로 검증

### 참고용 Bash 스니펫

```bash
JIRA_DIR=""
for cand in "$JIRA_DIR" "./Jira" "../Jira" "../../Jira" \
            "$(git rev-parse --show-toplevel 2>/dev/null)/Jira" \
            "$(git rev-parse --show-toplevel 2>/dev/null)/../Jira"; do
  [ -n "$cand" ] && [ -x "$cand/.venv/bin/jira" ] && { JIRA_DIR=$(cd "$cand" && pwd); break; }
done
[ -z "$JIRA_DIR" ] && echo "JIRA_DIR not found — 사용자에게 경로 문의 필요"
```

이후 모든 명령에서 `"$JIRA_DIR"` 를 사용한다.

### 환경 검증

세션 첫 명령으로 반드시 `jira doctor` 호출:

```bash
cd "$JIRA_DIR" && ./.venv/bin/jira doctor
```

기대 출력:
```
[CONFIG]   env file   = $JIRA_DIR/.env
[CONFIG]   JIRA_URL   = https://...
[CONFIG]   project    = S14P31D107
[CONNECT]  OK, as 김재환
[FIELD]    story points = customfield_10031 (auto)
[FIELD]    epic link    = customfield_10014 (auto)
```

실패 시(`.env` 누락·인증 실패·필드 ID 미탐색) **작업 중단 + 사용자 안내**. Claude 가 `.env` 를 자동 생성하면 안 된다.

---

## Phase 1 — 핵심 CLI 명령

```bash
cd "$JIRA_DIR"

./.venv/bin/jira doctor                                          # 환경 진단
./.venv/bin/jira search --jql "<JQL>" --limit 30                 # 조회: TEMP_FILE_PATH:/tmp/xxx.md + ISSUE_COUNT:N → md 파일 Read
./.venv/bin/jira create --summary "..." --type Task --points 3 --epic S14P31D107-3
./.venv/bin/jira update S14P31D107-XXX --status "Done" --comment "..." --assign me
./.venv/bin/jira link S14P31D107-XXX S14P31D107-3
```

- 프로젝트 키는 `$JIRA_DIR/.env` 의 `JIRA_PROJECT_KEY` 사용 (하드코딩 금지)
- **상태 JQL/transition 은 영문 사용**: `To Do` / `In Progress` / `Done`. ⚠️ `status = 완료` JQL 은 0건 반환 (silent fail)
- `jira search` stdout 의 `TEMP_FILE_PATH:` 줄을 capture → 그 md 파일을 Read 도구로 읽기 (UTF-8 안전)
- CLI subcommand 5개 한정: `{search, create, update, link, doctor}`. **코멘트 조회는 CLI 미지원** — 필요 시 REST 직접 호출 (`GET /rest/api/2/issue/{key}/comment`)

### JQL 예시

- 내 담당 미완료: `project = S14P31D107 AND assignee = currentUser() AND status != Done`
- 상위 스토리의 하위작업: `parent = S14P31D107-XXX`
- 최근 60일 본인 활동: `assignee = currentUser() AND updated >= -60d ORDER BY updated DESC`

---

## Phase 2 — 작업 규칙 (Head 가 판단하여 서브에이전트에 전달)

1. **내 담당(`assignee = currentUser()`)이 아닌 이슈는 절대 건들지 않음**
2. **상위 스토리는 모든 하위작업이 완료(Done)일 때만 완료 전환**. FE 하위작업 등이 남아 있으면 스토리는 보류
3. **실구현 없는 이슈는 건들지 않음** — 코드/커밋 매칭을 Head 가 먼저 검증
4. **완료 전환 시 본문 `## 💬 기타` 섹션에 관련 커밋 SHA / MR 번호 기록** (CLI 코멘트 미지원이므로 본문 update)
5. 신규 이슈 생성 시 [`be/docs/conventions/jira.md`](../../docs/conventions/jira.md) 의 정규식·결정사항(J-1~J-6) 준수

---

## Phase 3 — 서브에이전트 위임

- `Agent` tool, `subagent_type: "general-purpose"`, `model: "haiku"` (단순 호출) 또는 `"sonnet"` (탐색·패턴 추출), `run_in_background: true`
- 프롬프트에 포함할 것:
  - Phase 0 에서 확정한 **`$JIRA_DIR` 절대 경로**
  - `cd "$JIRA_DIR" && ./.venv/bin/jira ...` 형태의 구체 명령 나열
  - 각 이슈별 본문 update payload (`## ✅ 완료 조건` / `## 💬 기타` 섹션 + 커밋 SHA / MR 번호)
  - Phase 2 규칙 1~5 명시
  - "건들지 말 이슈 키" 명시 (실수 방지)
  - CDP MCP 사용 금지 (Codex / Claude Code 양쪽)

---

## Phase 4 — Head 검증

서브에이전트 완료 후:

```bash
cd "$JIRA_DIR"
./.venv/bin/jira search --jql "key in (S14P31D107-XXX, ...)"
```

출력된 md 파일 Read 로 상태·본문 재확인. 실패 이슈는 사유 요약해서 사용자에게 보고.

---

## 이슈 제목·본문 컨벤션 (신규 생성 시)

[`be/docs/conventions/jira.md`](../../docs/conventions/jira.md) §3, §4 의 정규식 준수. 핵심:

- **Story**: `^사용자는 .+ 싶다$` (마침표 없음, prefix 없음)
- **Sub-task**: `^\[(BE|FE|AI|DOCS|INFRA|DB)\] .+ (구현|연동|설정|처리|...)$`
- **Task**: `^\[(BE|FE|AI|DOCS|INFRA|DB)\] (Feat|Fix|Refactor|Docs|...): .+$` 또는 prefix 없는 직접 서술

본문 템플릿:

```markdown
## ✅ 완료 조건
- 

## 💬 기타
- 커밋: 
```

---

## 주의

- `./.venv/bin/jira` 대신 `python3 -m jira_automation` 쓰지 말 것 — venv pip install -e 의존성 우회 위험. 또는 PATH 의 `jira` (pipx 설치 시) 사용
- 경로를 절대 하드코딩하지 말 것 — 동료 환경마다 레포 위치 다름
- `jira search` 출력은 반드시 `TEMP_FILE_PATH` 의 md 파일을 Read 로 확인
- `.env` 가 없으면 **Claude 가 생성하지 말고** 사용자에게 안내만
- 라벨·컴포넌트·우선순위 필드는 본 프로젝트 미사용
- `Jira/legacy/` 디렉터리는 지원 대상 아님
