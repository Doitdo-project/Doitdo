# 컨벤션 (conventions/) 인덱스

팀 규칙은 노션이 SSOT (단일 진실 출처). 이 디렉토리는 노션 내용을 백엔드 작업에 필요한 만큼 요약/직역한다.
**노션과 이 문서가 어긋나면 노션이 우선.**

## 노션 SSOT

| 영역 | 노션 페이지 |
|---|---|
| 팀 규칙 (허브) | https://www.notion.so/e158ab5fe9a983ab9e2d014ea5209a51 |
| Git Convention | https://www.notion.so/3448ab5fe9a98068bf77d1f7a8164045 |
| JIRA Convention | https://www.notion.so/3448ab5fe9a980ff9da9ff5bc5094ec4 |
| BE Convention (패키지/네이밍) | https://www.notion.so/3458ab5fe9a980b7a026f4652db8b2c8 |
| API 기본 명세서 | https://www.notion.so/3428ab5fe9a980c790a6f9161a900f22 |

## 로컬 요약 문서

- [`git.md`](git.md) — 브랜치 전략 / 커밋 메시지 / Merge Request
- [`jira.md`](jira.md) — 일감 종류 / 작업 제목 / 도메인 구분 / 스토리 포인트
- [`naming.md`](naming.md) — Controller / Service / Repository / Entity / DTO 네이밍 + 엔티티 규칙

## 갱신 절차

노션이 바뀌면:

1. 노션에서 변경 합의/확정.
2. 이 디렉토리의 해당 `.md` 파일 갱신 (PR `docs/` 브랜치).
3. `be/AGENTS.md` 의 §2 표 변경 여부 확인.
