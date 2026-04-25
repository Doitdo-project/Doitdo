# 컨벤션 (conventions/) 인덱스

## SSOT 정책 (이원화)

| 영역 | SSOT |
|---|---|
| 일반 가이드(요약·인덱스) | **노션** (`be/CLAUDE.md` 명시) |
| 하네스·linter 규칙 (정규식 + 실례) | **레포(Git)** — 본 디렉토리 (세션 1 핸드오프 §1.1) |

근거: 다른 팀원·에이전트가 노션 fetch 의존 없이 Git 체크아웃만으로 동일 컨벤션을 즉시 적용해야 함.
하네스 산출물(컨벤션 문서·slash command·linter)은 노션 SSOT 와 별개로 무조건 Git 머지.
**노션과 본 문서가 어긋나면**: 일반 가이드 영역은 노션 우선, 정규식·linter 규칙은 본 디렉토리 우선.

## 노션 SSOT 페이지

| 영역 | 노션 페이지 |
|---|---|
| 팀 규칙 (허브) | https://www.notion.so/e158ab5fe9a983ab9e2d014ea5209a51 |
| Git Convention | https://www.notion.so/3448ab5fe9a98068bf77d1f7a8164045 |
| JIRA Convention | https://www.notion.so/3448ab5fe9a980ff9da9ff5bc5094ec4 |
| BE Convention (패키지/네이밍) | https://www.notion.so/3458ab5fe9a980b7a026f4652db8b2c8 |
| API 기본 명세서 | https://www.notion.so/3428ab5fe9a980c790a6f9161a900f22 |

## 로컬 문서

| 파일 | 역할 | Phase |
|---|---|---|
| [`notion-style.md`](notion-style.md) | 노션 페이지·DB·블록·이모지 규약 (정규식 + 실례) | 1 |
| [`jira.md`](jira.md) | JIRA 이슈 타입·제목·본문·상태 컨벤션 (CLI 사용법 포함) | 1 |
| [`git.md`](git.md) | 브랜치·커밋·MR 컨벤션 (정규식 + 실례) | 1 |
| [`naming.md`](naming.md) | Controller / Service / Repository / Entity / DTO 네이밍 | 0 |
| [`domain-events.md`](domain-events.md) | 도메인 이벤트 네이밍·payload 규약 | 0 |

## Phase 1 결정 추적 (Notion/JIRA 하네스 세션 2, 2026-04-24)

| # | 결정 | 선택 | 반영 위치 |
|---|---|---|---|
| N-1 | 커밋 prefix 공백 | A — `feat : 내용` | [`git.md`](git.md) §3, [`notion-style.md`](notion-style.md) §7 |
| N-2 | BE 패키지 최상위명 | `com.doitdo` | [`notion-style.md`](notion-style.md) §8 (노션 갱신 TODO) |
| N-3 | 에러코드 페이지 | Phase 2 이후 | [`notion-style.md`](notion-style.md) §10 |
| N-4 | API 명세서 구버전 | 휴지통 이동 | [`notion-style.md`](notion-style.md) §10 |
| J-1 | Story 제목 마침표 | 없음 | [`jira.md`](jira.md) §3.2 |
| J-2 | API 단위를 Task 로 만든 건 | Task 도 허용 | [`jira.md`](jira.md) §3.4 |
| J-3 | `[파트]` prefix 누락 | 향후 강제, 기존 grandfather | [`jira.md`](jira.md) §3.4 |
| J-4 | Story 변종 `~를 원한다` | `~하고 싶다` 절대 규칙 | [`jira.md`](jira.md) §3.2 |
| J-5 | 알림 도메인 에픽 부재 | TODO 에픽 하위 흡수 | [`jira.md`](jira.md) §3.1 |
| J-6 | 레거시 `[DOCS]` 스토리 | grandfather 인정 | [`jira.md`](jira.md) §3.2 |

## 갱신 절차

### 일반 컨벤션 (노션 SSOT)

1. 노션에서 변경 합의/확정.
2. 이 디렉토리의 해당 `.md` 파일 갱신 (PR `docs/` 브랜치).
3. `be/AGENTS.md` 의 §2 표 변경 여부 확인.

### 하네스 규칙 (Git authoritative)

1. 본 디렉토리에서 직접 변경 (정규식·실례 추가).
2. 필요 시 노션에 역방향 반영 (사용자 승인 필수, `/notion-update` Phase 3).
3. linter 스크립트(Phase 4) 가 본 문서를 읽으므로 정규식 변경은 linter 회귀 테스트 동반.

## 관련 핸드오프

- [`../plans/handoff-notion-jira-harness.md`](../plans/handoff-notion-jira-harness.md) — 1차 세션 원안
- [`../plans/handoff-notion-jira-harness-session2.md`](../plans/handoff-notion-jira-harness-session2.md) — 2차 세션 결정·진행
- [`../plans/notion-pattern-report.md`](../plans/notion-pattern-report.md) — Notion 패턴 추출 리포트
- [`../plans/jira-pattern-report.md`](../plans/jira-pattern-report.md) — JIRA 패턴 추출 리포트
