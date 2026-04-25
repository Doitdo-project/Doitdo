# Notion 스타일 가이드 (doitdo)

> **SSOT 경계**: 하네스·linter 규칙은 **이 파일이 authoritative** (세션 1 핸드오프 §1.1).
> 일반 설계/API 명세는 노션이 SSOT, 본 파일은 에이전트가 읽는 규칙 정의.
> 근거 리포트: [`../plans/notion-pattern-report.md`](../plans/notion-pattern-report.md)
> Phase: 1 (2026-04-24)
> 루트 페이지: 팀 프로젝트 관리 (page-id `cb98ab5f-e9a9-8245-8b92-81a741ef019a`)

---

## 1. 워크스페이스 구조

```
루트: 팀 프로젝트 관리
 ├─ [callout: megaphone/gray_background] 공지사항
 ├─ [column_list 25|75]
 │   ├─ 좌(25%) 사이드바
 │   │   ├─ H2 PROJECT
 │   │   │   ├─ 팀원 정보
 │   │   │   ├─ 팀 규칙 { Git Convention, JIRA Convention, BE, 에러코드 }
 │   │   │   ├─ 회의록 (DB: 프로젝트 회의록)
 │   │   │   └─ 스터디
 │   │   └─ H2 RESOURCES
 │   │       ├─ 아이디어 / 자료실 / 산출물
 │   │       ├─ API 기본 명세서 (DB: 엔드포인트(2))
 │   │       └─ 공유문서함
 │   └─ 우(75%) 메인
 │       ├─ H2 TO DO
 │       └─ DB: 프로젝트 일정
 ├─ KPT / 교보재 신청
 └─ API 기본 명세서(구) ← N-4 확정: 휴지통 이동 대상
```

- 좌우 분할은 루트에서만 사용. 하위 페이지는 단일 컬럼.
- `H2` 로 대그룹(`PROJECT` / `RESOURCES` / `TO DO`) 구분.

---

## 2. 페이지 명명 규칙

### 2.1 한국어/영어 혼용

- 일반 페이지: 순한글 명사 (`팀원 정보`, `회의록`, `산출물`)
- 기술 컨벤션: 영어 단독 (`Git Convention`, `JIRA Convention`, `BE`)
- 혼용: 기술 약어 + 한국어 (`API 기본 명세서`, `ERD`)

### 2.2 회의록 DB row 이름

```regex
^\d{6}( .+)?$
```

실례:
1. `260408`
2. `260409`
3. `260416 중간 발표 전 피드백`
4. `260422` (자유 — `YYMMDD` 만)
5. `컨님 첫 미팅` (예외: 자유형식, 정기회의 태그 없음)

### 2.3 URL 슬러그

노션 자동 생성. 제목 공백을 `-` 치환, 대문자 유지 — 추가 규칙 없음.

---

## 3. 헤딩·블록 규약

### 3.1 헤딩 레벨 의미

| 레벨 | 용도 | 실례 |
|------|------|------|
| H1 | 대섹션 제목 (이모지 prefix 허용) | `📚 Git Convention`, `🌿 Branch Strategy` |
| H2 | 중섹션, 번호 붙는 주제 | `1. 커밋 타입 (Type) 정의`, `2. 회의 내용`, `TO DO` |
| H3 | 소항목 | `형식`, `2.1. 기본 형식`, `주제 1: 캐릭터 컨셉` |
| H4 | 세세항목 (회의록 전용 이모지 넘버링) | `1️⃣ 형태`, `2️⃣ 테마` |

- 모든 헤딩 `is_toggleable: false` 고정.
- H4 는 회의록 한정. 일반 문서는 H3 까지.

### 3.2 블록 사용 가이드

| 블록 | 용도 | 규칙 |
|---|---|---|
| `paragraph` | 서술 | 빈 줄 분리는 rich_text 빈 paragraph 사용 |
| `heading_2` | 섹션 구분 | 앞뒤 `divider` 블록 권장 |
| `bulleted_list_item` | 규칙·URL 나열 | 기본 선택지 |
| `numbered_list_item` | 순서 있는 절차 | 이모지+내용 조합 가능 |
| `divider` | 섹션 분리 | H1·H2 이후 필수 |
| `callout` | 소제목 역할 | icon + `gray_background` 고정 |
| `quote` | 안내/설명 | 드물게 사용 |
| `table` | 명세 표 | `has_column_header: true`, `has_row_header: false` |
| `code` | 코드 블록 | language 속성 필수 |
| `child_database` | 인라인 DB | DB 묶음에서만 |
| `column_list` | 좌우 분할 | 루트 페이지·회의록 이미지 비교 한정 |
| `toggle` | **미사용** | 관찰된 사례 없음 |
| `to_do` | **미사용** | 진척도는 DB `상태(status)` 속성으로 |

### 3.3 이모지 prefix 매핑

| 이모지 | 맥락 | 실례 |
|---|---|---|
| `📚` | 문서/컨벤션 제목 | `📚 Git Convention` |
| `🌿` | 브랜치 전략 | `🌿 Branch Strategy` |
| `📂` | 디렉터리/구조 | `📂 Branch Structure` |
| `📌` | 역할/핀포인트 | `📌 Branch 역할` |
| `🏷` | 네이밍 룰 | `🏷 Branch Naming Rule` |
| `🔄` | 워크플로우 | `🔄 Branch Workflow` |
| `🚨` | 규칙/주의 | `🚨 Branch 규칙` |
| `🧠` | 이유/배경 | `🧠 이거 왜써요?` |
| `1️⃣`~`9️⃣` | 순서 있는 H4 | `1️⃣ 형태` (회의록 H4 전용) |
| `📍` | 최종 결정 강조 | `📍 mvp: 알 - 슬라임 - 애기슬라임 - 성체` |

### 3.4 페이지·DB 아이콘 규격

| 아이콘 name | color | 용도 |
|---|---|---|
| `document` | `gray` | 회의록 DB row 기본 |
| `push-pin` | `gray` | 프로젝트 일정 DB row |
| `electric-plug` | `purple` | API 엔드포인트 DB row |
| `megaphone` | `gray` | 공지사항 callout |
| `flag-swallowtail` | `gray` | 협업 원칙 callout |
| `calendar` | `gray` | 일정 관리 callout |
| `link` | `gray` | 프로젝트 리소스 callout |
| `compressed-document` | `gray` | 자료실 DB row |

Callout 배경색: `gray_background` 고정.

---

## 4. 데이터베이스 속성 스키마

### 4.1 엔드포인트 (2) — API 명세 SSOT

**DB id**: `3428ab5f-e9a9-81dd-b525-ddb2bffebe85`
**data_source_id**: `3428ab5f-e9a9-81fc-b47f-000be0cbe93a`

| 속성 | 타입 | 필수 | 값/enum |
|---|---|---|---|
| `기능` | title | ✅ | 한국어 동사형 ("로그인 하기", "TODO 삭제") |
| `설명` | rich_text | 권장 | 1~2줄 서술 |
| `Method` | select | ✅ | `GET`(pink) / `POST`(green) / `DELETE`(red) / `PATCH`(default) |
| `URL` | url | ✅ | `/todos/{todoId}` 형식 (PK: `{테이블명}Id`) |
| `param` | rich_text | 옵션 | path variable 명 (`todoId`) |
| `카테고리` | multi_select | ✅ | `TODO`(blue) / `인증`(green) / `유저`(yellow) / `다마고치`(purple) |
| `담당자` | select | ✅ | `황예찬`(blue) / `김재환`(orange) / `전상훈`(yellow) |
| `사용자` | multi_select | ✅ | `유저`(purple) |
| `코드` | rich_text | 권장 | 정규식 `^[A-Z]\d{2}$` ※ 인라인 코드 서식 (`annotations.code: true`) |
| `기타` | rich_text | 옵션 | 비즈니스 로직 보충 |

**코드 enum** (도메인 letter):
- `A` = 인증 (Auth) — `A00` 로그인, `A01`…
- `T` = TODO — `T00` 상세, `T01` 삭제…
- `M` = 다마고치 — `M00` 독립 승인, `M01` 캐릭터 이름…
- `U` = 유저 (User) — `U00` 회원 탈퇴…
- (알림은 `N` — JIRA 컨벤션에서 `N04~N07` 관찰. 본 DB 반영 필요 여부는 Phase 2 검토)

**실례 5건**:
1. `로그인 하기` / `/auth/login` / `POST` / `A00`
2. `회원 탈퇴` / `/users/me` / `DELETE` / `U00`
3. `TODO 상세 조회` / `/todos/{todoId}` / `GET` / `T00`
4. `TODO 삭제` / `/todos/{todoId}` / `DELETE` / `T01`
5. `독립 승인` / `/characters/me/farewell` / `POST` / `M00`

페이지 아이콘: `electric-plug / purple` (신규 생성 시 필수).

### 4.2 프로젝트 회의록 DB

**DB id**: `98e8ab5f-e9a9-8354-9b69-8194a76ecbfb`
**data_source_id**: `e2b8ab5f-e9a9-834a-8267-074c42b20ba5`

| 속성 | 타입 | 필수 | 값 |
|---|---|---|---|
| `이름` | title | ✅ | `YYMMDD` 또는 `YYMMDD 특이사항` |
| `날짜` | date | ✅ | `YYYY-MM-DD` |
| `태그` | select | ✅ | `정기회의`(yellow) |
| `참석자` | people | 옵션 | |
| `해야할 일` | relation | 옵션 | |

페이지 아이콘: `document / gray`.

### 4.3 프로젝트 일정 DB

**DB id**: `c6a8ab5f-e9a9-835d-8c84-81bcb1dc9a2d`
**data_source_id**: `0428ab5f-e9a9-8257-8ba7-8744cb498ba6`

| 속성 | 타입 | 필수 | 값 |
|---|---|---|---|
| `내용` | title | ✅ | 작업 내용 요약 |
| `기간` | date | ✅ | `YYYY-MM-DD` 단일 |
| `상태` | status | ✅ | `완료`(green) / `시작 전`(default) |
| `담당자` | people | 옵션 | |
| `관련 회의록` | relation | 옵션 | 프로젝트 회의록 DB |

페이지 아이콘: `push-pin / gray`.

### 4.4 기능 명세 하위 도메인 DB

기능 명세 페이지(`3418ab5f-e9a9-8079-8f0a-fb6dd3e7c497`) 하위 child_database:
`다마고치`, `유저 `, `TODO `, `설정`, `미정 `, `기타`

각 스키마는 엔드포인트 DB 와 유사 구조로 추정 — 세부 확인은 Phase 2 에서.

---

## 5. 링크·코드·표 관습

### 5.1 링크

- 내부 페이지: `child_page` 블록 (목록화). 본문 내 `@ 멘션` 은 드묾.
- 외부 URL: `bulleted_list_item` 안에 bold+underline 라벨 + `[링크]` 플레이스홀더:
  ```
  배포 URL: [서비스 링크]
  API 문서: [링크]
  ```
- Figma: `embed` 블록 (`https://embed.figma.com/design/...`).

### 5.2 코드 블록 language

| language | 용도 |
|---|---|
| `plain text` | 커밋 메시지 포맷 정의 |
| `json` | API Request/Response Body 템플릿 |
| `markdown` | BE 패키지 구조 가이드 |

### 5.3 표 기본값

- `has_column_header: true`, `has_row_header: false` 고정.
- API 공통양식 4컬럼 표: `파라미터명 / 타입 / 필수여부 / 설명` (Query/Path/Fields/TurnItemFields 동일 구조).

### 5.4 인라인 코드 서식 대상

`rich_text.annotations.code: true` 적용:
- API 코드 필드값 (`A00`, `T00`, `M00`)
- 기술 키워드: `request`, `params`, `response`, `example`, `status`

---

## 6. 텍스트 톤·문체

| 구분 | 규칙 |
|---|---|
| 공식 컨벤션 | `~한다` 체 (평서 단언) |
| 컨벤션 규칙 | 명령형 ("직접 dev 브랜치 push 금지") |
| 회의록 | 구어체 허용 ("한번에 한마리", "안돼 ㅜㅜ") |
| bold | 핵심 키워드·규칙 강조 |
| strikethrough | 기각 아이디어 |
| yellow_background | 최종 결정 강조 (회의록 결론) |
| `→` | 결론·연결 표시 ("→ 누르면 보따리 싸들고 떠남") |

영어 약어 사용: PR, MR, dev, feat, fix, BE, FE, DOCS, INFRA, API, DTO, JPA, HTTP, JWT, MVP 는 그대로 사용.

---

## 7. 커밋 메시지 표기 (N-1 확정)

> **결정 N-1: A — `feat : 내용` 형식. 콜론 양쪽 공백 필수.**
> 근거: JIRA Convention 페이지 본문 + 실제 커밋 일관. Git Convention 페이지 본문 설명(`: `)은 오타로 간주, Phase 2 에서 노션 갱신.

### 정규식

**Canonical: [git.md §3](git.md)** — type enum, subject 길이, 공백 규칙 모두 거기서 단일 정의. 본 문서는 N-1 결정(공백 있음) 과 노션 쪽 반영 TODO 만 명시.

- type과 `:` 사이, `:`과 subject 사이 **둘 다 공백 1개 필수**.
- subject 는 한국어, 50자 이내, 마침표 금지.

### 실례 5건 (실제 커밋 기준)

1. `feat : tamagotchi/user-character history 로그 테이블 추가` (커밋 `e4ae32b`)
2. `feat : auth/login 로그인 API 구현` (노션 컨벤션 예시)
3. `fix : withdraw detached entity 버그 수정`
4. `docs : withdraw-token-bug 문서 제거`
5. `chore : e2e 스크립트 동기화`
6. `refactor : TodoService 분리 + CalendarOccurrenceGenerator static 전환`

### 안티패턴

- `feat: 내용` (콜론 뒤만 공백) — **금지**
- `feat:내용` (공백 없음) — **금지**
- `feat : 내용.` (마침표) — **금지**
- 영문 subject — **금지** (한국어 원칙)

---

## 8. BE 패키지 최상위명 (N-2 확정)

> **결정 N-2: `com.doitdo`.**
> 노션 BE 규칙 페이지 코드 블록(`com.woojudraw` 잔재)은 Phase 2 에서 `com.doitdo` 로 일괄 치환.

- BE 코드 경로: [`be/src/main/java/com/doitdo/`](../../src/main/java/com/doitdo/)
- 패키지 구조 상세: [`../architecture/package-layout.md`](../architecture/package-layout.md)
- 엔티티 네이밍: [`naming.md`](naming.md)

---

## 9. 컨벤션 페이지 SSOT 포인터

| 영역 | 페이지 ID | URL |
|---|---|---|
| 팀 규칙 허브 | `e158ab5f-e9a9-83ab-9e2d-014ea5209a51` | https://www.notion.so/e158ab5fe9a983ab9e2d014ea5209a51 |
| Git Convention | `3448ab5f-e9a9-8068-bf77-d1f7a8164045` | https://www.notion.so/3448ab5fe9a98068bf77d1f7a8164045 |
| JIRA Convention | `3448ab5f-e9a9-80ff-9da9-ff5bc5094ec4` | https://www.notion.so/3448ab5fe9a980ff9da9ff5bc5094ec4 |
| BE Convention | `3458ab5f-e9a9-80b7-a026-f4652db8b2c8` | https://www.notion.so/3458ab5fe9a980b7a026f4652db8b2c8 |
| API 기본 명세서 | `3428ab5f-e9a9-80c7-90a6-f9161a900f22` | https://www.notion.so/3428ab5fe9a980c790a6f9161a900f22 |
| 에러코드 | `3488ab5f-e9a9-8067-832d-d663e195115e` | (빈 상태 — N-3 Phase 2 이후) |

---

## 10. Phase 2 이후 실행 대상

본 문서 확정과 동시에 노션에 반영해야 할 항목:

| # | 대상 | 내용 | 결정 근거 |
|---|---|---|---|
| 1 | Git Convention 페이지 | 본문 설명을 `Type과 Subject 사이는 콜론(` : `)과 공백(` `)으로 구분` 으로 수정 (현재 `: ` 만) | N-1 A |
| 2 | BE 규칙 페이지 코드 블록 | `com.woojudraw` → `com.doitdo` 일괄 치환 | N-2 |
| 3 | `API 기본 명세서(구)` | 휴지통 이동 (archive) | N-4 A |
| 4 | 에러코드 페이지 | Phase 2 이후 별도 페이즈 — BE `ErrorCode` enum 마이그레이션 슬래시 명령 설계 | N-3 B |

실행은 `/notion-update` 슬래시 명령(Phase 3) 구축 후 일괄 처리. 그 전까진 사용자 승인하에 수동 업데이트.

---

## 11. 안티패턴 (하지 말 것)

1. **toggle 블록 남발** — 관찰 0건. 신규 사용 시 팀 합의 필요.
2. **to_do 체크박스로 진척도 추적** — DB `상태` 속성 사용.
3. **callout 배경색 변경** — `gray_background` 고정.
4. **이모지 없는 H1** — 컨벤션·문서 페이지는 이모지 prefix 권장.
5. **API DB row 에 아이콘 누락** — `electric-plug / purple` 필수.
6. **한 줄 요약 컨벤션** — 정규식 + 실례 5개 이상 없이 규칙 도입 금지 (세션 1 핸드오프 §9-1).

---

## 12. 참조

- 근거 리포트: [`../plans/notion-pattern-report.md`](../plans/notion-pattern-report.md)
- 핸드오프: [`../plans/handoff-notion-jira-harness.md`](../plans/handoff-notion-jira-harness.md), [`../plans/handoff-notion-jira-harness-session2.md`](../plans/handoff-notion-jira-harness-session2.md)
- 자매 문서: [`jira.md`](jira.md), [`git.md`](git.md)
