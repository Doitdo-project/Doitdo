# JIRA Convention (doitdo / S14P31D107)

> **SSOT 경계**: 하네스·linter 규칙은 **이 파일이 authoritative** (세션 1 핸드오프 §1.1).
> 일반 가이드(요약·인덱스)는 노션 SSOT 참조.
> 노션: <https://www.notion.so/3448ab5fe9a980ff9da9ff5bc5094ec4>
> 근거 리포트: [`../plans/jira-pattern-report.md`](../plans/jira-pattern-report.md)
> Phase: 1 (2026-04-24)

---

## 1. 도구 진입점

- CLI: `jira` (Jaeboong/[Jira_automation](https://github.com/Jaeboong/Jira_automation))
- 설치 위치: `/home/cbkjh0225/project/ssafyTodo/Jira/.venv/bin/jira` (PATH 미등록 — venv 직접 호출 또는 pipx 추가 설치)
- `.env` 위치: `/home/cbkjh0225/project/ssafyTodo/Jira/.env` (CWD 가 `Jira/` 일 때 자동 로드)
- 프로젝트 키: `S14P31D107`
- 세션 첫 명령: `jira doctor`

### 사용 패턴

```bash
cd /home/cbkjh0225/project/ssafyTodo/Jira
./.venv/bin/jira doctor                                   # 설정/연결 진단
./.venv/bin/jira search --jql "..." --limit 30            # stdout: TEMP_FILE_PATH:/tmp/xxx.md + ISSUE_COUNT:N
./.venv/bin/jira create --summary "..." --type Story --points 3 --epic S14P31D107-3
./.venv/bin/jira update S14P31D107-XXX --status "Done" --comment "..."
./.venv/bin/jira link S14P31D107-XXX S14P31D107-3
```

### Read 계약

`jira search` stdout 의 `TEMP_FILE_PATH:` 줄을 capture → 그 .md 파일을 Read 도구로 읽는다. 터미널 출력 직접 파싱 금지 (UTF-8 깨짐 위험).

---

## 2. JQL 주의사항 (사실, 결정 아님)

### 상태 값 한↔영 이원화 ⚠️

UI 표시는 한글, JIRA 내부 값은 영문. **JQL은 반드시 영문 사용**:

| UI 표시 | JQL 사용 값 |
|---|---|
| 해야 할 일 | `To Do` |
| 진행 중 | `In Progress` |
| 완료 | `Done` |

```bash
# ❌ status = 완료 → 0 건 반환 (silent fail)
# ✅ status = Done → 정상 반환
./.venv/bin/jira search --jql "status = Done AND assignee = currentUser()"
```

### currentUser

본인(김재환) 이슈 조회 시 `assignee = currentUser()` 사용. `.env` 의 token 기준으로 자동 매핑.

### 라벨·컴포넌트·우선순위

본 프로젝트 60일 샘플 기준 **사용 0건**. CLI 출력에서도 표시되지 않음. 신규 이슈에서도 사용하지 않는다.

---

## 3. 이슈 타입별 제목 컨벤션

### 3.1 Epic (에픽) — 도메인 명사 단어

- 형식: 단어 1개. prefix 없음.
- enum: `TODO`, `다마고치`, `인증`, `유저`, `DOCS`, `INFRA`, `설정`
- 영문 대문자 약어(`TODO`, `INFRA`, `DOCS`) 또는 순한글(`다마고치`, `인증`, `유저`, `설정`) 모두 허용.
- **알림 도메인 (J-5 확정 B): 별도 에픽 신설 안 함. TODO 에픽(`S14P31D107-3`) 하위로 흡수.** 근거: 알림은 TODO 의 트리거(완료/리마인더) 기반 부속 기능.

### 3.2 Story (스토리) — `사용자는 ~ 싶다` 절대 규칙

> **결정 J-1 B: 마침표 없음.**
> **결정 J-4 A: `사용자는 ~하고 싶다` 절대 규칙. `~를 원한다` 등 변종 금지.**
> **결정 J-6 A: 초기 레거시 `[DOCS]` 스토리(`-9`, `-11`) grandfather (예외 인정).**

#### 정규식

```regex
^사용자는 .+ 싶다$
```

- 마침표·물음표·느낌표 금지 (linter 거부 대상).
- prefix(`[BE]`, `[DOCS]` 등) 금지.

#### 실례 (BE 도메인 6건)

1. `사용자는 받은 알림을 확인하고 관리하고 싶다` (`S14P31D107-345`)
2. `사용자는 저녁에 남은 TODO 를 리마인더로 받고 싶다` (`S14P31D107-346`)
3. `사용자는 푸시 알림을 한 번에 켜고 끄고 싶다` (`S14P31D107-300`)
4. `사용자는 자신의 연속 달성 기록(streak)을 확인하고 싶다` (`S14P31D107-359`)
5. `사용자는 카테고리 색상을 지정하고 싶다` (`S14P31D107-307`)
6. `사용자는 다크모드를 사용하고 싶다` (`S14P31D107-305`)

#### 안티패턴

- `사용자는 ~를 원한다` — `S14P31D107-308` 1건 위반 (Phase 2 에서 제목 수정 대상)
- 초기 마침표 형식: `사용자는 TODO를 생성하고 싶다.` — 신규 이슈에는 마침표 없음. 기존 `-32~-102` 는 grandfather, 수정 강제 안 함.
- 레거시 `[DOCS]` prefix + 비서술형: `[DOCS] ERD 설계 및 작성` (`-11`), `[DOCS] 와이어 프레임 설계` (`-9`) — grandfather, 신규 생성 금지.

### 3.3 Sub-task (하위 작업) — `[파트] {내용} {동사}`

#### 정규식

```regex
^\[(BE|FE|AI|DOCS|INFRA|DB)\] .+ (구현|연동|설정|처리|정비|분리|설계|적용)( \(.+\))?$
```

- 서두 `[파트]` 필수.
- 본문에 API 코드 참조(`N04`, `SET-008`, `T13`) 사용 권장.
- 마침 동사: `구현` 가장 흔함. 기타 `연동`, `설정`, `처리`.

#### 실례 (10건)

1. `[BE] TODO 생성 API 구현` (`S14P31D107-103`)
2. `[BE] TODO 상태 변경 API 구현` (`S14P31D107-104`)
3. `[BE] TODO 검색 API 구현` (`S14P31D107-110`)
4. `[BE] 반복 TODO 생성 API 구현` (`S14P31D107-112`)
5. `[BE] N04 알림 목록 조회 API 구현` (`S14P31D107-348`)
6. `[BE] N07 알림 삭제 API 구현` (`S14P31D107-351`)
7. `[BE] SET-008 설정 API 구현` (`S14P31D107-324`)
8. `[BE] Firebase Admin SDK 연동 및 FCM 송신 서비스 구현` (`S14P31D107-352`)
9. `[BE] 저녁 잔여 TODO 리마인더 스케줄러 구현 (TODO-009)` (`S14P31D107-353`)
10. `[FE] SET-004 설정 화면 구현` (`S14P31D107-315`)

### 3.4 Task (작업) — `[파트] {prefix:} {내용}` 또는 `[파트] {내용}`

> **결정 J-2 B: API 단위 이슈도 Task 허용** (스토리 없이 단발성일 때).
> **결정 J-3 B: `[파트]` prefix 향후 강제. 기존 누락(`-355`, `-356`) grandfather.**

#### 정규식 (둘 중 하나)

```regex
# 형식 1 (prefix 있음)
^\[(BE|FE|AI|DOCS|INFRA|DB)\] (Feat|Fix|Refactor|Docs|Style|Chore|Rename|Remove): .+$

# 형식 2 (prefix 없는 직접 서술)
^\[(BE|FE|AI|DOCS|INFRA|DB)\] [^:]+$
```

- 신규 Task 는 **반드시 `[파트]` 로 시작**.
- prefix(`Feat:`, `Refactor:` 등)는 선택 — 단발성 API 구현/리팩터·문서화 작업이면 권장.

#### 실례 (5건)

1. `[BE] Feat: T13 카테고리 조회 API (GET /categories)` (`S14P31D107-332`)
2. `[BE] Refactor: TodoService 분리 + CalendarOccurrenceGenerator static 전환` (`S14P31D107-334`)
3. `[BE] Docs: Swagger 자동 부착 + docs/api 정비` (`S14P31D107-335`)
4. `[BE] Spring Security 설정` (`S14P31D107-127`) — prefix 없는 형식 2
5. `[INFRA] 개발 서버 수동 배포 환경 구성` (`S14P31D107-47`) — prefix 없는 형식 2

#### 레거시 예외 (grandfather)

- `Feat: FCM 디바이스 토큰 해제 API (N02)` (`S14P31D107-355`)
- `Refactor: NotificationErrorCode 명세 기준 재정의 (N00~N07)` (`S14P31D107-356`)

→ 향후 신규 Task 는 `[BE]` prefix 강제. 위 2건은 그대로 유지.

### 3.5 Bug

- 60일 샘플 기준 **0건**.
- 신규 Bug 발생 시: `[파트] Fix: {증상}` Task 형식 권장 (별도 Bug 타입 사용 패턴 미정착).

---

## 4. 본문 템플릿

### 4.1 Sub-task — API 명세 인라인 (형식 A)

```
{HTTP 메서드} {경로}, {파라미터/Body 설명}.
Response {상태코드}: { {응답 필드} }.
ErrorCode: {코드}-001({HTTP}), {코드}-002({HTTP}), ...
API 기본 명세서 -> {섹션} 참조.
```

실례 (`S14P31D107-351`):
```
DELETE /notifications/{notificationId}, Response 204.
본인 소유 검증(403). ErrorCode: N07-001(401), N07-002(403), N07-003(404), N07-004(500).
API 기본 명세서 -> 알림 섹션 참조.
```

### 4.2 Task — 완료 조건 섹션 (형식 B)

```markdown
## ✅ 완료 조건
- {조건 1}
- {조건 2}

## 💬 기타
- 커밋: {SHA 또는 SHA 목록}
- (관련 MR 링크, 주의사항 등)
```

실례 (`S14P31D107-332`):
```
## ✅ 완료 조건
- GET /api/categories 엔드포인트 구현
- 본인 소유 카테고리 전체 조회 (isDeleted 조건 없음)
- 응답: { items: [{ categoryId, categoryName, colorId }] }
- TodoErrorCode 에 T13_001(UNAUTHORIZED) 추가

## 💬 기타
- 커밋: ...
```

### 4.3 Story — 사용자 관점 + 관련 API 코드 (형식 C)

```
{사용자 관점 1~2 문장 설명}. ({관련 API 코드 목록})
```

실례 (`S14P31D107-345`):
```
사용자는 받은 알림 목록을 확인하고 읽음 처리 및 삭제를 하고 싶다.
(N04~N07 알림 목록 조회/읽음/전체읽음/삭제 API)
```

### 4.4 Atlassian Wiki 마크업 (형식 D — 비권장)

다른 팀원 일부 이슈에서 `h3.`, `*` 사용. **신규 이슈는 Markdown 사용** (형식 A/B/C). 기존 wiki markup 이슈는 grandfather.

### 4.5 ErrorCode 참조 정규식

```regex
[A-Z]\d{2,3}[-_]\d{3}\(\d{3}\)
```

실례: `N07-001(401)`, `N06-002(500)`, `T13_001(...)`, `A03_003(409)`

---

## 5. 도메인 구분 — 트리거 기준

행동의 **트리거가 어느 도메인에서 발생하는지**로 일감 도메인을 정한다.

| 트리거 | 도메인 | 담당자 |
|---|---|---|
| 다마고치 성장 ← TODO 완료 | **TODO** | 김재환 |
| 알림 발송 ← TODO/리마인더 | **TODO** (J-5) | 김재환 |
| 캐릭터 이름 설정 ← 다마고치 자체 | 다마고치 | 전상훈 |
| 로그인/회원 탈퇴 | 인증 | 황예찬 |
| 프로필 변경 | 유저 | 황예찬 |

---

## 6. 도메인-담당자 매핑

| 도메인 | 담당자 |
|---|---|
| 인증 | 황예찬 |
| 유저 | 황예찬 |
| 다마고치 | 전상훈 |
| TODO | 김재환 |
| 알림 (TODO 하위) | 김재환 |
| 설정 | 김재환 |

---

## 7. 스토리 포인트 (피보나치)

> 노션 SSOT: `1, 2, 3, 5, 8 을 주로 사용`.

| SP | 의미 | 대표 사례 |
|---|---|---|
| 1 | 매우 단순 | TODO 삭제 스토리 (`-100`), Task 단발 카테고리 조회 (`-332`) |
| 2 | 단순 | TODO 상태 변경 API (`-104`), 설정 스토리 다수 |
| 3 | 명확 | TODO 생성 API (`-103`), 알림 읽음/삭제 API (`-349`, `-351`) |
| 5 | 표준 | 반복 TODO API (`-112`), 알림 목록 API (`-348`), 알림 스토리 (`-345`, `-346`) |
| 8 | 고난도 | Firebase Admin SDK 연동 (`-352`), 리마인더 스케줄러 (`-353`) |
| 9·10 | 대규모/위험 | **사용 시 분할 우선 검토.** 60일 샘플 0건 |
| 4·6·7 | 예외값 | 가능한 한 인접 피보나치로 환원 |

---

## 8. 상태 전이

```
해야 할 일 (To Do) → 진행 중 (In Progress) → 완료 (Done)
```

- Code Review 상태 없음 (코드 리뷰는 GitLab MR 단계에서).
- **스토리는 모든 하위작업이 완료(Done)인 경우에만** 완료 전환 (메모리 규칙).
- 본인(김재환) 담당이 아닌 이슈는 절대 건드리지 않는다 (메모리 규칙).
- 완료 전환 시 본문 `## 💬 기타` 섹션에 관련 커밋 SHA / MR 번호 기록.

### 코멘트 조회 제약

`jira` CLI 는 `{search, create, update, link, doctor}` 5개 subcommand 만 지원. **코멘트 본문은 CLI 로 조회 불가**. 분석 필요 시:

```bash
GET /rest/api/2/issue/{key}/comment   # 직접 REST 호출 (CLI 외부)
```

→ 본문 `## 💬 기타` 섹션이 사실상 코멘트 대체 역할. 향후 CLI 에 `comment` 서브커맨드 추가 검토 (Jira_automation upstream 이슈).

---

## 9. 생성·수정 전 체크리스트

1. `jira doctor` 통과 확인 (세션 첫 명령).
2. 본 문서(`jira.md`) 와 [`notion-style.md`](notion-style.md) 의 정규식 만족 확인.
3. 본인 담당 이슈인지 확인 (`assignee = currentUser()`).
4. 스토리 완료 전환이면 모든 하위 작업이 `Done` 인지 확인.
5. 본문에 `## ✅ 완료 조건` / `## 💬 기타` 섹션 포함 (Task 의 경우).
6. 완료 전환 시 커밋 SHA / MR 번호 기록.

---

## 10. Phase 2 이후 실행 대상

| # | 대상 | 작업 | 결정 근거 |
|---|---|---|---|
| 1 | `S14P31D107-308` | 제목 `~를 원한다` → `~하고 싶다` 변경 | J-4 A |
| 2 | `S14P31D107-345`, `-346` | TODO 에픽(`-3`) 하위로 link | J-5 B |
| 3 | 알림 관련 자식 7건 (`-348~-354`) | TODO 에픽 트리 일관성 검토 후 link | J-5 B |
| 4 | (검토) 노션 JIRA Convention 페이지 | 본 문서 결정사항 5건 (J-1·J-3·J-4·J-5·J-6) 반영 | 노션 SSOT 보강 |

레거시 grandfather (수정 안 함):
- `S14P31D107-9`, `-11` (`[DOCS]` 스토리)
- `S14P31D107-355`, `-356` (`[BE]` prefix 누락 Task)
- `S14P31D107-32~-102` 초기 마침표 스토리

실행은 `/jira-sync-v2` 슬래시 명령(Phase 3) 구축 후 일괄. 그 전까진 사용자 승인하에 수동.

---

## 11. 안티패턴 (linter 차단 대상)

1. **`status = 완료` JQL** → `status = Done` 사용
2. **`사용자는 ~를 원한다`** → `~하고 싶다` 만 허용
3. **신규 Story 제목 마침표** → 마침표 없음
4. **신규 Task `[파트]` prefix 누락** → `[BE]`, `[FE]` 등 필수
5. **신규 Story 에 prefix 사용** (`[BE] 사용자는 ...`) → prefix 금지
6. **본인 외 이슈 수정** → 절대 금지 (메모리 규칙)
7. **하위작업 미완료 상태에서 스토리 완료 전환** → 금지
8. **CLI 외 직접 REST 호출 (코멘트 외)** → CLI 로만

---

## 12. 참조

- 근거 리포트: [`../plans/jira-pattern-report.md`](../plans/jira-pattern-report.md)
- 핸드오프: [`../plans/handoff-notion-jira-harness.md`](../plans/handoff-notion-jira-harness.md), [`../plans/handoff-notion-jira-harness-session2.md`](../plans/handoff-notion-jira-harness-session2.md)
- CLI 레포: [`/home/cbkjh0225/project/ssafyTodo/Jira/`](file:///home/cbkjh0225/project/ssafyTodo/Jira/) (Jaeboong/Jira_automation)
- 자매 문서: [`notion-style.md`](notion-style.md), [`git.md`](git.md)
- 슬래시 명령: [`be/.claude/commands/jira-sync.md`](../../.claude/commands/jira-sync.md) (현행 v1)
