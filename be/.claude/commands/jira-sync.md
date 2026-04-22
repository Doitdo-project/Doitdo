---
description: JIRA 이슈 조회·생성·상태변경을 Haiku 서브에이전트에 위임 (프로젝트 JIRA 스크립트 사용)
---

# /jira-sync — JIRA 하네스

사용자가 `/jira-sync` 를 호출하면 JIRA 이슈 상태 동기화 작업을 수행한다.
Claude(Head)는 **계획·검증만** 하고, 실제 JIRA 스크립트 호출은 **Haiku 서브에이전트에 위임**한다.

---

## Phase 0 — Jira 도구 위치 탐색 (필수)

동료마다 레포 클론 위치가 다를 수 있으므로 **절대 경로를 하드코딩하지 말고** 매 호출 시 탐색한다.

### 탐색 순서

1. 환경변수 `JIRA_SKILL_DIR` 이 설정돼 있고 `$JIRA_SKILL_DIR/LLM_GUIDE.md` 가 존재하면 그걸 사용
2. 아래 후보를 순서대로 `LLM_GUIDE.md` 존재 여부로 확인:
   - `./Jira`
   - `../Jira`
   - `../../Jira`
   - `$(git rev-parse --show-toplevel 2>/dev/null)/Jira`
   - `$(git rev-parse --show-toplevel 2>/dev/null)/../Jira`
3. 후보 중 어느 하나라도 맞으면 그 절대 경로를 확정
4. 모두 실패하면 **사용자에게 질문**: "Jira 스킬 디렉터리 (`LLM_GUIDE.md` 가 들어있는 곳) 의 절대 경로를 알려주세요. (예: `/home/you/project/Jira`)". 사용자가 답한 경로도 마찬가지로 검증

### 참고용 Bash 스니펫

```bash
JIRA_DIR=""
for cand in "$JIRA_SKILL_DIR" "./Jira" "../Jira" "../../Jira" \
            "$(git rev-parse --show-toplevel 2>/dev/null)/Jira" \
            "$(git rev-parse --show-toplevel 2>/dev/null)/../Jira"; do
  [ -n "$cand" ] && [ -f "$cand/LLM_GUIDE.md" ] && { JIRA_DIR=$(cd "$cand" && pwd); break; }
done
[ -z "$JIRA_DIR" ] && echo "JIRA_DIR not found — 사용자에게 경로 문의 필요"
```

이후 모든 명령에서 `"$JIRA_DIR"` 를 사용한다.

### Python 런타임 확인

`$JIRA_DIR/.venv/bin/python` 이 존재하는지 체크.

- 있으면: 그대로 사용
- 없으면: 사용자에게 안내 ("먼저 `cd $JIRA_DIR && python3 -m venv .venv && ./.venv/bin/pip install -r requirements.txt` 를 실행해주세요") 후 중단

### `.env` 확인

`$JIRA_DIR/.env` 가 없거나 placeholder 값이 남아있으면 **작업 중단 + 사용자에게 안내**:
> `$JIRA_DIR/.env` 를 `$JIRA_DIR/.env.example` 에서 복사해 본인 값(`JIRA_URL`, `JIRA_EMAIL`, `JIRA_API_TOKEN`, `JIRA_PROJECT_KEY`)을 채워주세요.

**Claude 가 `.env` 를 자동 생성하면 안 된다.**

---

## Phase 1 — 핵심 스크립트

```bash
cd "$JIRA_DIR"
./.venv/bin/python search_issues.py --jql "<JQL>"        # 조회: TEMP_FILE_PATH 출력 → Read
./.venv/bin/python create_issues.py --project "$JIRA_PROJECT_KEY" --summary "..." --type Task
./.venv/bin/python update_issues.py --key "$JIRA_PROJECT_KEY-XXX" --status "완료" --comment "..."
./.venv/bin/python link_epic.py --issue STORY_KEY --epic EPIC_KEY
```

- 프로젝트 키는 `$JIRA_DIR/.env` 의 `JIRA_PROJECT_KEY` 사용 (하드코딩 금지)
- 상태 전환 값: `해야 할 일`, `진행 중`, `완료`
- `search_issues.py` stdout 은 `TEMP_FILE_PATH:` 가 포함됨. 터미널 파싱하지 말고 **md 파일을 Read**

### JQL 예시

- 내 담당 미완료: `project = <KEY> AND assignee = currentUser() AND status != "완료"`
- 상위 스토리의 하위작업: `parent = <KEY>-XXX`

---

## Phase 2 — 작업 규칙 (Head 가 판단하여 Haiku 에 전달)

1. **내 담당(`assignee = currentUser()`)이 아닌 이슈는 절대 건들지 않음**
2. **상위 스토리는 모든 하위작업이 완료일 때만 완료 전환**. FE 하위작업 등이 남아 있으면 스토리는 보류
3. **실구현 없는 이슈는 건들지 않음** — 코드/커밋 매칭을 Head 가 먼저 검증
4. **완료 전환 시 코멘트 필수**: 관련 커밋 SHA / MR 번호 포함

---

## Phase 3 — Haiku 서브에이전트 위임

- `Agent` tool with `subagent_type: "general-purpose"`, `model: "haiku"`, `run_in_background: true`
- 프롬프트에 포함할 것:
  - Phase 0 에서 확정한 **`$JIRA_DIR` 절대 경로**
  - `cd "$JIRA_DIR" && ./.venv/bin/python ...` 형태의 구체 명령 나열
  - 각 이슈별 코멘트 본문(커밋 SHA / MR 번호)
  - Phase 2 규칙 1~4 명시
  - "건들지 말 이슈 키" 명시 (실수 방지)
  - CDP MCP 사용 금지

---

## Phase 4 — Head 검증

Haiku 완료 후:

```bash
cd "$JIRA_DIR"
./.venv/bin/python search_issues.py --jql "key in (...)"
```

출력된 md 파일 Read 로 상태 재확인. 실패 이슈는 사유 요약해서 사용자에게 보고.

---

## 이슈 제목 컨벤션 (신규 생성 시)

`$JIRA_DIR/jiraconvention.md` 를 먼저 Read 하고 준수. 핵심 prefix:

- 회의: `Meeting: ...`
- 문서: `Docs: ...`
- 기능: `Feat: ...`
- 버그: `Fix: ...`
- 리팩토링: `Refactor: ...`
- 파일명 변경: `Rename: ...`
- 삭제: `Remove: ...`

설명 템플릿:

```markdown
## ✅ 완료 조건
- 

## 💬 기타
- 
```

---

## 주의

- `./.venv/bin/python` 대신 `python3` 쓰지 말 것 — 의존성 누락 가능
- 경로를 절대 하드코딩하지 말 것 — 동료 환경마다 레포 위치 다름
- `search_issues.py` 출력은 반드시 `TEMP_FILE_PATH` 의 md 파일을 Read 로 확인
- `.env` 가 없으면 **Claude 가 생성하지 말고** 사용자에게 안내만
