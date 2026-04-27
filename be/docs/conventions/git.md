# Git Convention (doitdo)

> **SSOT 경계**: 하네스·linter 규칙은 **이 파일이 authoritative** (세션 1 핸드오프 §1.1).
> 일반 가이드는 노션 SSOT.
> 노션: <https://www.notion.so/3448ab5fe9a98068bf77d1f7a8164045>
> 근거 리포트: [`../plans/notion-pattern-report.md`](../plans/notion-pattern-report.md) §8.1, §8.2
> Phase: 1 (2026-04-24)

---

## 1. 브랜치 전략

- `main` (운영) ← `dev` (개발 통합) ← feature 브랜치
- **`dev` 직접 push 금지.** feature 브랜치에서 작업 → MR 코드 리뷰 → dev 머지.
- 운영 핫픽스는 `hotfix/{내용}` 브랜치 → main + dev 양쪽 머지.

## 2. 브랜치 네이밍

### 정규식

```regex
^(fe|be)/(feat|fix|chore|docs|refactor)/.+$
```

대체 예외 (운영·문서 전용):
```regex
^(hotfix|docs)/.+$
```

### 실례 8건

1. `be/feat/auth-api`
2. `be/feat/todo-exp-system`
3. `be/feat/user-character-history`
4. `be/fix/jwt-refresh-error`
5. `be/fix/withdraw-detached-entity`
6. `be/chore/e2e-sync-current-apis`
7. `fe/feat/login-ui`
8. `docs/notion-jira-harness-plan`

### 안티패턴
- prefix 누락 (`feat/auth-api`) — 파트 자동 분류 실패.
- 한국어 슬러그 (`be/feat/로그인`) — ASCII slug 만 사용.

---

## 3. 커밋 메시지 (N-1 확정)

> **결정 N-1: A — `feat : 내용` 형식. 콜론 양쪽 공백 1개 필수.**
> 근거: 실제 BE 커밋 100% 일관, JIRA Convention 페이지 본문 예시와 일치. Git Convention 페이지 설명문(`: `)은 오타로 간주, Phase 2 에서 노션 갱신.

### 정규식

```regex
^(feat|fix|add|refactor|docs|style|chore|build|ci|perf|revert|test|rename|remove) : .{1,50}$
```

- type 과 `:` 사이 공백 **1개** 필수.
- `:` 과 subject 사이 공백 **1개** 필수.
- subject 한국어 50자 이내, 마침표 금지.

### Type enum

| type | 용도 |
|---|---|
| `feat` | 새 기능 |
| `fix` | 버그 수정 |
| `add` | 클래스/파일 추가 (기능 외) |
| `refactor` | 리팩토링 |
| `docs` | 문서 |
| `style` | 포맷팅 / 세미콜론 |
| `chore` | 빌드 / 설정 / 잡일 |

> 노션 Git Convention 페이지에 `comment` type 이 정의되어 있으나 실제 git history (`git log --all`) 에 0건 — 사용 안 함. linter enum 에서도 제외. 향후 사용 시 본 문서·노션 동시 갱신.

### 실례 6건 (실제 BE 커밋)

1. `feat : tamagotchi/user-character history 로그 테이블 추가` (`e4ae32b`)
2. `feat : auth/login 로그인 API 구현` (노션 컨벤션 예시)
3. `fix : withdraw detached entity 버그 수정`
4. `docs : withdraw-token-bug 문서 제거`
5. `chore : e2e 스크립트 동기화`
6. `refactor : TodoService 분리 + CalendarOccurrenceGenerator static 전환`

### 안티패턴 (linter 차단 대상)

| 패턴 | 이유 |
|---|---|
| `feat: 내용` | 콜론 앞 공백 누락 |
| `feat:내용` | 양쪽 공백 누락 |
| `feat : 내용.` | subject 마침표 |
| `feat : login API` | 영문 subject (한국어 원칙) |
| `[BE] feat : 내용` | 커밋 메시지에 `[파트]` prefix 사용 (그건 JIRA·MR 제목 컨벤션) |

---

## 4. Merge Request

### 제목 형식

```regex
^\[BE : (feat|fix|chore|docs|refactor|style|test)\] .+$
```

- 한국어 권장. 기술 용어는 영어 가능.
- 커밋 메시지·JIRA 제목과 **다른 컨벤션**임에 주의 (메모리 `project_mr_title_convention.md`).

실례:
- `[BE : feat] TODO 카테고리 조회 API 구현`
- `[BE : fix] withdraw detached entity 버그 수정`
- `[BE : chore] e2e 스크립트 동기화`

### 본문 템플릿

[`.gitlab/merge_request_templates/default.md`](../../../.gitlab/merge_request_templates/default.md) 의 섹션 그대로 사용. **자체 포맷 금지** (메모리 `feedback_mr_template.md`).

대상 브랜치: feature → **dev**.

---

## 5. JIRA 이슈 연결

- MR 본문 footer 또는 커밋 본문에 `Closes #123`, `Related to #456` 형식 (Git Convention 노션 페이지 명시).
- JIRA 이슈 완료 시 본문 `## 💬 기타` 섹션에 머지된 커밋 SHA 또는 MR 번호 기록 ([`jira.md`](jira.md) §8).

---

## 6. 자주 빠뜨리는 항목

- 브랜치 prefix (`be/feat/...`) 누락 → 자동 분류 안 됨.
- 커밋 type 과 설명 사이 콜론 양쪽 공백 1개 (` : `) 누락 → 컨벤션 위반.
- 작업 단위가 너무 크면 commit 분할.
- MR 제목에 `[BE : type]` 대괄호+콜론 형식 누락.
- MR 템플릿 섹션 임의 변경.

---

## 7. Phase 2 이후 실행 대상

| # | 대상 | 작업 | 결정 근거 |
|---|---|---|---|
| 1 | 노션 Git Convention 페이지 | 본문 설명 `Type과 Subject 사이는 콜론(` : `)과 공백(` `)으로 구분` 으로 수정 (현재 표기 누락 또는 `: ` 만) | N-1 A |

---

## 8. 참조

- 자매 문서: [`jira.md`](jira.md), [`notion-style.md`](notion-style.md), [`naming.md`](naming.md)
- MR 템플릿: [`.gitlab/merge_request_templates/default.md`](../../../.gitlab/merge_request_templates/default.md)
- 핸드오프: [`../plans/handoff-notion-jira-harness.md`](../plans/handoff-notion-jira-harness.md), [`../plans/handoff-notion-jira-harness-session2.md`](../plans/handoff-notion-jira-harness-session2.md)
