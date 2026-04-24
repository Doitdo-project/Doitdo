# Notion 패턴 리포트 — Phase 1 (2026-04-24)

> 분석 대상: 팀 프로젝트 관리 워크스페이스 (page-id: `cb98ab5f-e9a9-8245-8b92-81a741ef019a`)
> 분석 일시: 2026-04-24
> 분석 페이지 수: 약 18개 페이지, 데이터베이스 수: 6개

---

## 1. 워크스페이스 트리 (root → 1·2 depth)

```
루트: 팀 프로젝트 관리
 ├─ [callout] 공지사항 (icon: megaphone, color: gray_background)
 ├─ [paragraph] 팀원: 김재환, 신우혁, 오우택, 이새롬, 전상훈
 ├─ [paragraph] 팀장: 황예찬
 ├─ [column_list] 25% | 75% 분할 레이아웃
 │   ├─ 좌(25%) — 사이드바 역할
 │   │   ├─ [heading_2] PROJECT
 │   │   │   ├─ child_page: 팀원 정보
 │   │   │   ├─ child_page: 팀 규칙
 │   │   │   │   ├─ child_page: Git Convention
 │   │   │   │   ├─ child_page: JIRA Convention
 │   │   │   │   ├─ child_page: BE
 │   │   │   │   └─ child_page: 에러코드
 │   │   │   ├─ child_page: 회의록
 │   │   │   │   └─ child_database: 프로젝트 회의록
 │   │   │   └─ child_page: 스터디
 │   │   └─ [heading_2] RESOURCES
 │   │       ├─ child_page: 아이디어
 │   │       ├─ child_page: 자료실
 │   │       ├─ child_page: 산출물
 │   │       │   ├─ child_page: 프로젝트 개요
 │   │       │   ├─ child_page: 기능 명세 (child_databases: 다마고치/유저/TODO/설정/미정/기타)
 │   │       │   ├─ child_page: 요구사항 명세
 │   │       │   └─ child_page: ERD
 │   │       ├─ child_page: API 기본 명세서
 │   │       │   ├─ child_database: 엔드포인트 (2) — 메인 API DB
 │   │       │   ├─ child_page: 공통양식
 │   │       │   └─ child_page: 글로벌
 │   │       └─ child_page: 공유문서함
 │   └─ 우(75%) — 메인 콘텐츠 역할
 │       ├─ [heading_2] TO DO
 │       └─ child_database: 프로젝트 일정
 ├─ child_page: KPT
 ├─ child_page: 교보재 신청
 └─ child_page: API 기본 명세서(구)
```

**실례 (URL)**
- 루트: `https://www.notion.so/cb98ab5fe9a982458b9281a741ef019a`
- API 명세서: `https://www.notion.so/API-3428ab5fe9a980c790a6f9161a900f22`
- Git Convention: page-id `3448ab5f-e9a9-8068-bf77-d1f7a8164045`
- JIRA Convention: page-id `3448ab5f-e9a9-80ff-9da9-ff5bc5094ec4`
- 커밋 컨벤션 가이드: `https://www.notion.so/Git-3428ab5fe9a98186a7e2d59dbf61e5c7`
- 회의록 (260409): `https://www.notion.so/260409-33d8ab5fe9a980309ff9d6b0fb807be5`

---

## 2. 페이지 계층 명명 패턴

### 2.1 한국어/영어 혼용 비율

- **한국어 우세**: 페이지 제목의 약 80%가 한국어
- **영어 단독**: 컨벤션 문서, 기술 용어에 한정 — `Git Convention`, `JIRA Convention`, `BE`
- **혼용**: 기술적 맥락에서만 한국어+영어 병기 — `API 기본 명세서`, `ERD`

### 2.2 명명 관습

| 패턴 | 예시 | 빈도 |
|------|------|------|
| 순수 한국어 명사 | 팀원 정보, 자료실, 산출물, 회의록, 아이디어 | 높음 |
| 영어 약어 + 한국어 | API 기본 명세서, API 기본 명세서(구) | 중간 |
| 날짜 prefix (YYMMDD) | 260408, 260409, 260416 중간 발표 전 피드백 | 회의록에 집중 |
| 영어 단독 | Git Convention, JIRA Convention, ERD, BE | 낮음 |
| 구분자 (구) suffix | API 기본 명세서(구) — 구버전 표기 | 낮음 |

**실례 5개**
1. `팀원 정보` — child_page, 순수 한국어
2. `260416 중간 발표 전 피드백` — 회의록 DB row, YYMMDD + 설명
3. `API 기본 명세서(구)` — 구버전 suffix 패턴
4. `Git Convention` — 영어 단독
5. `에러코드` — 한국어 약어식

### 2.3 URL 슬러그 패턴

노션 자동 생성 URL은 제목을 그대로 slug화하되 공백은 `-`로 변환:
- `https://www.notion.so/TODO-3428ab5fe9a98128a270f64e06149f75` (기능명 앞 배치)
- `https://www.notion.so/260409-33d8ab5fe9a980309ff9d6b0fb807be5` (날짜 prefix)
- `https://www.notion.so/Git-3428ab5fe9a98186a7e2d59dbf61e5c7`

---

## 3. 헤딩·블록 사용 규약

### 3.1 헤딩 의미 구분

| 헤딩 레벨 | 용도 | 실례 |
|-----------|------|------|
| H1 | 대섹션 제목 (컨벤션 문서에서 주제 구분) | `📚 Git Convention`, `🌿 Branch Strategy`, `📂 Branch Structure` |
| H2 | 중섹션, 번호가 붙는 세부 항목 | `1. 커밋 타입 (Type) 정의`, `2. 회의 내용`, `사용 예시 및 사용법`, `TO DO`, `PROJECT`, `RESOURCES` |
| H3 | 소항목, 서브토픽 | `형식`, `예시`, `2.1. 기본 형식`, `주제 1: 캐릭터 컨셉`, `커스텀 예시` |
| H4 | 세세항목, 열거 구분 | `1️⃣ 형태`, `2️⃣ 테마`, `1️⃣ 성장 과정`, `*️⃣ 중복 여부에 따른 도감 구성` |

**특이사항**: H2에 `is_toggleable: false` 고정. H4는 회의록 전용으로 이모지 넘버링 사용.

**실례 5개**
1. H1: `📚 Git Convention` (Git Convention 페이지)
2. H2: `1️⃣ dev 브랜치에서 작업 브랜치 생성` (Git 워크플로우, 이모지 넘버링)
3. H2: `1. 회의 정보` / `2. 회의 내용` (회의록 표준 구조)
4. H3: `주제 1: 캐릭터 컨셉` with `color: default_background` (회의록 상세)
5. H3: `🧠 이거 왜써요?` with `color: blue_background` (API 명세서 공유문서함)

### 3.2 블록 유형별 사용 빈도 및 용도

| 블록 타입 | 빈도 | 주요 용도 |
|-----------|------|-----------|
| `paragraph` | 매우 높음 | 본문 서술, 구분용 빈 줄 (rich_text가 비어있는 경우 많음) |
| `heading_2` | 높음 | 섹션 구분, 번호 붙은 주제 구분 |
| `heading_3` | 높음 | 소주제, 서브 섹션 |
| `bulleted_list_item` | 높음 | 항목 열거, 규칙 나열, URL 링크 |
| `numbered_list_item` | 중간 | 순서 있는 절차, 스토리 포인트 목록, 이모지+내용 열거 |
| `divider` | 높음 | 섹션 간 구분선 (H1/H2 이후 반드시 divider 패턴) |
| `callout` | 중간 | 카테고리 소제목 역할 (icon+배경색 조합), 협업 원칙·일정 관리·프로젝트 리소스 |
| `quote` | 낮음 | 커밋 메시지 요약 설명, 안내 문구 |
| `table` | 중간 | 커밋 타입 정의, 브랜치 역할, API Query Parameters/Fields 명세 |
| `code` | 중간 | JSON body, plain text 형식, markdown (BE 패키지 구조) |
| `child_database` | 중간 | 인라인 DB (회의록, API 엔드포인트, 프로젝트 일정) |
| `child_page` | 중간 | 하위 페이지 링크 |
| `column_list` | 낮음 | 좌우 분할 레이아웃 (루트 25/75, 회의록 내 이미지 비교) |
| `embed` | 매우 낮음 | Figma 디자인 임베드 |
| `file` | 매우 낮음 | 외부 파일 링크 (대부분 비어있음) |
| `heading_4` | 낮음 | 회의록 내 세세항목 이모지 넘버링 |

### 3.3 toggle 사용

분석된 페이지에서 `is_toggleable: true`는 관찰되지 않음. 모든 헤딩은 `is_toggleable: false`.

---

## 4. 이모지·아이콘 사용 매핑

### 4.1 페이지/DB 아이콘 (icon 속성)

| 아이콘 name | color | 용도 | 실례 |
|-------------|-------|------|------|
| `document` | `gray` | 회의록 DB row 기본 아이콘 | 프로젝트 회의록 DB 모든 row |
| `push-pin` | `gray` | 프로젝트 일정 DB row | 문서, 기획, 문서 3 등 |
| `electric-plug` | `purple` | API 엔드포인트 DB row | 독립 승인, TODO 상세 조회, 로그인 하기 등 |
| `megaphone` | `gray` | 공지사항 callout | 루트 페이지 상단 |
| `flag-swallowtail` | `gray` | 협업 원칙 callout | 팀 규칙 페이지 |
| `calendar` | `gray` | 일정 관리 callout | 팀 규칙 페이지 |
| `link` | `gray` | 프로젝트 리소스 callout | 팀 규칙 페이지 |
| `compressed-document` | `gray` | 자료실 DB row | 발표자료 항목들 |

### 4.2 헤딩 prefix 이모지 패턴

| 이모지 | 맥락 | 실례 |
|--------|------|------|
| `📚` | 문서/컨벤션 제목 | `📚 Git Convention` |
| `🌿` | 브랜치 전략 | `🌿 Branch Strategy` |
| `📂` | 디렉터리/구조 | `📂 Branch Structure` |
| `📌` | 역할/핀포인트 | `📌 Branch 역할` |
| `🏷` | 네이밍 룰 | `🏷 Branch Naming Rule` |
| `🔄` | 워크플로우 | `🔄 Branch Workflow` |
| `🚨` | 규칙/주의 | `🚨 Branch 규칙` |
| `😎` | 소개 (캐주얼) | `😎소개` (API 명세서 공유문서함) |
| `🧠` | 이유/배경 | `🧠 이거 왜써요?` |
| `1️⃣` `2️⃣` `3️⃣` | 순서 있는 단계 | `1️⃣ 형태`, `2️⃣ 테마` (H4 레벨) |
| `*️⃣` | 부가 설명 | `*️⃣ 중복 여부에 따른 도감 구성` |
| `🗂️` `🔖` `👓` `💫` `⏱️` | numbered_list 내 이모지 | API 명세서 기능 설명 list |
| `📍` | MVP 결정 강조 | `📍 mvp: 알 - 슬라임 - 애기슬라임 - 성체` (회의록) |

### 4.3 callout 아이콘 패턴

callout 블록의 `icon.type = "icon"` 사용 (이모지 X, 노션 내장 아이콘 사용):
- 공지사항: `megaphone / gray`
- 협업 원칙: `flag-swallowtail / gray`
- 일정 관리: `calendar / gray`
- 프로젝트 리소스: `link / gray`

callout 배경색: `gray_background` 고정.

---

## 5. 데이터베이스 속성 스키마 (DB 별)

### 5.1 엔드포인트 (2) — API 명세 DB

**DB ID**: `3428ab5f-e9a9-81dd-b525-ddb2bffebe85`
**URL**: `https://www.notion.so/3428ab5fe9a981ddb525ddb2bffebe85`
**Public URL**: `https://confused-gray-a16.notion.site/3428ab5fe9a981ddb525ddb2bffebe85`

| 속성명 | 타입 | 필수 여부 | 옵션/비고 |
|--------|------|-----------|----------|
| `기능` | title | 필수 | 한국어 동사형 명사: "로그인 하기", "TODO 삭제", "독립 승인" |
| `설명` | rich_text | 권장 | 1~2줄 한국어 서술형 |
| `Method` | select | 필수 | GET(pink), POST(green), DELETE(red), PATCH(default) |
| `URL` | url | 필수 | `/todos/{todoId}`, `/auth/login`, `/characters/me/farewell` |
| `param` | rich_text | 옵션 | path variable 명: `todoId` |
| `카테고리` | multi_select | 필수 | TODO(blue), 인증(green), 유저(yellow), 다마고치(purple) |
| `담당자` | select | 필수 | 황예찬(blue), 김재환(orange), 전상훈(yellow), 신우혁(?), 오우택(?) |
| `사용자` | multi_select | 필수 | 유저(purple) — 현재 단일값만 관찰 |
| `코드` | rich_text | 권장 | `A00`, `T00`, `T01`, `T02`, `M00`, `M01`, `M02`, `U00` 형식 (`code` 인라인) |
| `기타` | rich_text | 옵션 | 비즈니스 로직 보충 설명 |

**Method select 색상 enum**
- `GET` → color: `pink`
- `POST` → color: `green`
- `DELETE` → color: `red`
- `PATCH` → color: `default` (회색)
- `PUT` → 관찰 없음 (정의됐을 가능성 있음)

**코드 필드 명명 규칙**: `{도메인코드}{순번}` (2자리)
- A = 인증(Auth), T = TODO, M = 다마고치(Mascot?), U = 유저(User)

**페이지 아이콘**: `electric-plug / purple` 고정 (일부 row는 null)

**실례 5개 (기능 → URL → Method → 코드)**
1. `로그인 하기` → `/auth/login` → POST → `A00`
2. `회원 탈퇴` → `/users/me` → DELETE → `U00`
3. `TODO 상세 조회` → `/todos/{todoId}` → GET → `T00`
4. `TODO 삭제` → `/todos/{todoId}` → DELETE → `T01`
5. `독립 승인` → `/characters/me/farewell` → POST → `M00`

---

### 5.2 프로젝트 회의록 DB

**DB ID**: `98e8ab5f-e9a9-8354-9b69-8194a76ecbfb`
**DB Name**: 프로젝트 회의록

| 속성명 | 타입 | 필수 여부 | 옵션/비고 |
|--------|------|-----------|----------|
| `이름` | title | 필수 | 날짜코드 또는 특이사항 기재: "260408", "260416 중간 발표 전 피드백", "컨님 첫 미팅" |
| `날짜` | date | 필수 | `YYYY-MM-DD` 형식 단일 날짜 |
| `태그` | select | 필수 | 정기회의(yellow) — 현재 단일 옵션만 관찰 |
| `참석자` | people | 옵션 | 관찰된 row 모두 비어있음 (미기입 상태) |
| `해야할 일` | relation | 옵션 | 다른 DB와의 관계 (비어있음) |

**페이지 아이콘**: `document / gray` 고정

**이름 패턴 실례**
1. `260408` — YYMMDD 단독
2. `260409` — YYMMDD 단독
3. `260416 중간 발표 전 피드백` — YYMMDD + 상황 설명
4. `컨님 첫 미팅` — 특이사항 기재
5. `회의록` — 초기 템플릿 기본값

---

### 5.3 프로젝트 일정 DB

**DB ID**: `c6a8ab5f-e9a9-835d-8c84-81bcb1dc9a2d`

| 속성명 | 타입 | 필수 여부 | 옵션/비고 |
|--------|------|-----------|----------|
| `내용` | title | 필수 | 작업 내용 요약 |
| `기간` | date | 필수 | 단일 날짜 (`YYYY-MM-DD`) |
| `상태` | status | 필수 | 완료(green), 시작 전(default) |
| `담당자` | people | 옵션 | 관찰된 row 모두 비어있음 |
| `관련 회의록` | relation | 옵션 | 프로젝트 회의록 DB와 연결 |

**페이지 아이콘**: `push-pin / gray` 고정

**상태(status) enum**
- `완료` → color: `green`
- `시작 전` → color: `default`
- `진행 중` → 관찰 없음 (정의됐을 가능성 있음)

**내용 실례**: "문서", "기획", "문서 3", "모바일 (피그마)", "모바일 UI 화면 구성 완성"

---

### 5.4 기능 명세 (구버전 포함) DB들

기능 명세 페이지(`3418ab5f-e9a9-8079-8f0a-fb6dd3e7c497`) 하위에 **도메인별 child_database**가 인라인 삽입됨:
- `다마고치`, `유저 `, `TODO `, `설정`, `미정 `, `기타`

각 DB의 스키마 상세는 조회되지 않았으나, "엔드포인트 (2)" DB와 유사한 속성 구조로 추정됨 (동일 페이지에서 파생).

---

## 6. 링크·멘션·코드·표·체크박스 관습

### 6.1 내부 링크·멘션

- **child_page** 블록으로 하위 페이지를 목록화 (별도 멘션 없이 블록 자체가 링크)
- 본문 내 직접 page 멘션 사례는 분석 범위에서 관찰되지 않음
- **JIRA 이슈 링크 표기**: Footer에 `Closes #123`, `Related to #456` 형식 (Git Convention 문서에 텍스트로 명시)

### 6.2 외부 URL

- `bulleted_list_item` 안에 `bold+underline` 텍스트 뒤 `[링크]` 플레이스홀더 패턴:
  ```
  배포 URL: [서비스 링크]
  API 문서: [링크]
  ```
- Figma embed: `embed` 블록 타입 사용 (`https://embed.figma.com/design/...`)

### 6.3 코드 블록

| language 속성 | 사용 맥락 | 실례 |
|---------------|-----------|------|
| `plain text` | 커밋 메시지 포맷 정의 | `[Type]: [Subject]\n[Body]\n[Footer]` |
| `json` | API Request/Response Body 템플릿 | 공통양식 내 빈 JSON |
| `markdown` | 백엔드 패키지 구조 가이드 전체 | BE 규칙 페이지의 대형 코드블록 |

### 6.4 표(table)

**헤더 관습**: `has_column_header: true`, `has_row_header: false` 고정

**관찰된 표 구조**
| 표 위치 | 컬럼 수 | 컬럼 헤더 예시 |
|---------|--------|----------------|
| 커밋 타입 정의 | 3 | Type / 설명 / 예시 |
| 브랜치 역할 | 2 | 브랜치 / 역할 |
| API 공통양식 Query Parameters | 4 | 파라미터명 / 타입 / 필수여부 / 설명 |
| API 공통양식 Path Variables | 4 | 동일 구조 |
| API 공통양식 Fields | 4 | 동일 구조 |
| API 공통양식 Turn Item Fields | 4 | 동일 구조 |
| IntelliJ 단축키 | 2 | 기능 / 단축키 |

### 6.5 체크박스(to_do)

분석된 페이지에서 `to_do` 블록은 관찰되지 않음. 진척도 추적은 프로젝트 일정 DB의 `상태(status)` 속성으로 대체.

### 6.6 인라인 코드 서식

코드 필드 값(`코드` 속성)의 경우 `rich_text` 내 `annotations.code: true`로 인라인 코드 서식 적용:
- 실례: `A00`, `T00`, `M00` — code 인라인
- API 명세 설명에서 `request`, `params`, `response`, `example`, `status` — code 인라인

---

## 7. 텍스트 톤·문체 패턴

### 7.1 전반적 문체

| 구분 | 관찰 패턴 |
|------|-----------|
| 존댓말/평어 | **혼재** — 공식 문서(~합니다/~한다), 회의록(~이야/~해) |
| 공식 문서 | ~한다 체 (평서형, 비격식 존댓말 없음): "사용한다", "정의한다", "포함한다" |
| 컨벤션 규칙 | 명령형+단언: "직접 dev 브랜치 push 금지", "PR을 통해서만 merge" |
| 회의록 | 구어체 혼입: "한번에 한마리", "그리고 이별 후 도감에 저장", "안돼 ㅜㅜ" |
| bold 활용 | 핵심 키워드, 규칙 강조 (`bold: true`) |
| 취소선 | 논의 중 기각된 아이디어 표시: `strikethrough: true` (실례: 납골당(사망) - 안돼 ㅜㅜ) |
| 형광펜 | `color: yellow_background` — 최종 결정 내용 강조 (회의록 결론 부분) |
| → 표기 | 결론/연결 표시: "→ 누르면 보따리 싸들고 떠남", "→ 서두에 [BE], [FE]..." |

### 7.2 영어 약어 사용 빈도

- **높음**: PR, MR, dev, feat, fix, BE, FE, DOCS, INFRA, API, DTO, JPA, HTTP, JWT, MVP
- **중간**: CRUD 패턴, DDD, Layered Architecture, Epic, Sprint, Story, Sub-Task
- **낮음**: breaking change, hotfix

### 7.3 서술 스타일별 실례

**공식 컨벤션 (~한다 체)**
- "본 문서는 프로젝트에서 사용하는 Branch 전략과 Commit Message 규칙을 정의한다."
- "본 프로젝트는 Frontend / Backend 작업을 구분하되 하나의 개발 브랜치(dev)에서 통합하는 방식을 사용한다."

**커밋 메시지 규칙 (~합니다 혼용)**
- "커밋 메시지는 Type: Subject 형식으로 작성하며, 팀원 간의 효율적인 코드 리뷰와 프로젝트 히스토리 파악을 위해 사용합니다."
- "Subject는 한글로 작성하며, 간결하게 50자 이내로 작성합니다."

**회의록 (구어체)**
- "📍 mvp: 알 - 슬라임 - 애기슬라임 - 성체"
- "취업( 요리사, 헬스트레이너, 선생님, 연구원, ~~이제 TODO 기반으로 취업 해서 독립 ~~)"

**스토리 포인트 설명 (~인 작업 패턴)**
- "10 : [매우 위험/복잡] 어떻게 시작해야 할지 전혀 모르겠고..."
- "1 : [매우 단순] 오타 수정, 문서 한 줄 수정 등 고민 없이 바로 끝낼 수 있는 작업"

---

## 8. 추출된 정규식 후보 + 실례 풀텍스트

### 8.1 Git 브랜치 명명 규칙

```
정규식: ^(fe|be)\/(feat|fix|chore|docs|refactor)\/.+$
대체 예외: ^(hotfix|docs)\/.+$

실례:
  1. fe/feat/login-ui
  2. fe/feat/emotion-canvas
  3. be/feat/auth-api
  4. be/feat/drawing-upload
  5. fe/fix/canvas-touch-bug
  6. be/fix/jwt-refresh-error
  7. docs/git-convention
  8. docs/api-spec
```

### 8.2 커밋 메시지 포맷

```
정규식: ^(feat|fix|docs|style|refactor|test|chore|build|ci|perf|revert)\s?:\s.{1,50}$
  (Type과 : 사이 공백은 옵션으로 관찰됨)

실례:
  1. feat : auth/login 로그인 API 구현
  2. (Type): (Subject) — 기본 형식
  3. Type 목록 (표에서 추출): feat, fix, docs, style, refactor, test, chore 포함 (추정)
```

**주의**: 실제 커밋 예시는 `"feat : auth/login 로그인 API 구현"` 형식으로 `: ` 앞뒤 공백 있음.

### 8.3 회의록 이름 패턴

```
정규식: ^\d{6}(\s.+)?$  (YYMMDD 또는 YYMMDD 설명)
         또는 특이사항 기재 (자유형식)

실례:
  1. 260408
  2. 260409
  3. 260416 중간 발표 전 피드백
  4. 컨님 첫 미팅  (자유형식)
  5. 회의록  (기본값)
```

### 8.4 API 코드 필드 패턴

```
정규식: ^[A-Z]\d{2}$

실례:
  1. A00 — 인증 로그인
  2. T00 — TODO 상세 조회
  3. T01 — TODO 삭제
  4. T02 — TODO 목록 조회
  5. M00 — 독립 승인
  6. M01 — 캐릭터 이름 설정
  7. M02 — 알 깨기
  8. U00 — 회원 탈퇴
```

### 8.5 JIRA Task/Sub-Task 제목 패턴

```
정규식: ^\[(BE|FE|DOCS|INFRA|AI|DB)\]\s.+$

실례:
  1. [BE] 로그인 API 구현
  2. [FE] emotion canvas 개발
  3. [DOCS] api-spec 작성
  (직접 관찰된 실례 아님 — JIRA Convention 문서에서 규칙만 추출)
```

### 8.6 API URL 패턴

```
정규식 (path variable): \{[a-zA-Z]+Id\}  (PK 네이밍: {테이블명}Id)

실례:
  1. /todos/{todoId}
  2. /characters/me/farewell
  3. /characters/me/hatch
  4. /characters/me/name
  5. /auth/login
  6. /users/me
  7. /todos  (목록)
```

### 8.7 BE 패키지 네이밍 (코드 블록 내)

```
정규식:
  Controller: {Domain}Controller
  Service: {Domain}Service
  ServiceImpl: {Domain}ServiceImpl
  Repository: {Domain}Repository
  Request DTO: {Action}{Domain}Req
  Response DTO: {Domain}Resp

실례:
  1. MemberController
  2. MemberService / MemberServiceImpl
  3. MemberRepository
  4. SignupMemberReq
  5. MemberProfileResp
  (주의: 현재 코드는 com.woojudraw 기준 — doitdo로 변경 필요함 페이지 내 메모 있음)
```

---

## 9. 모호하거나 일관성 없는 영역 (사용자 확정 필요)

### 9.1 커밋 메시지 "Type : Subject" vs "Type: Subject" 공백 불일치

- JIRA Convention 페이지 텍스트: `"feat : auth/login 로그인 API 구현"` → **Type과 : 사이에 공백 있음**
- Git 커밋 컨벤션 가이드 설명: "Type과 Subject 사이는 콜론(`:`)과 공백(` `)으로 구분" → **공백 없음**
- 현재 BE 실제 커밋(`e4ae32b feat : tamagotchi/user-character history 로그 테이블 추가`)에서 `feat :` 형식 사용됨 → **공백 있음**
- **확정 필요**: `feat: 내용` vs `feat : 내용` 어느 쪽이 표준인가?

### 9.2 BE 패키지 최상위 패키지명 미반영

- BE 규칙 페이지의 코드 블록은 이전 프로젝트(`com.woojudraw`) 기준으로 작성됨
- 페이지 내 H3 `"doitdo 로 수정 해야함"` 메모가 있으나 코드가 미갱신 상태
- **확정 필요**: 실제 패키지 최상위명 (`com.doitdo`? 또는 다른 이름?) 갱신 필요

### 9.3 에러코드 페이지 내용 미작성

- 에러코드 페이지(`3488ab5f-e9a9-8067-832d-d663e195115e`)가 빈 상태 (paragraph 빈 블록 하나만 존재)
- **확정 필요**: 에러코드 체계(형식, 도메인별 범위 등) 정의 필요

### 9.4 API DB 이중 관리 (구 명세서 vs 신 명세서)

- `API 기본 명세서(구)` 와 `API 기본 명세서` 두 페이지가 공존
- 신 명세서는 DB 기반(엔드포인트 (2)), 구 명세서는 별도 구조
- **확정 필요**: 구 명세서 아카이브/삭제 여부, 신 명세서가 유일한 SSOT인지 확인

---

## 10. 부록: 분석 대상 DB 데이터 소스 ID 목록

| DB 이름 | data_source_id |
|---------|----------------|
| 프로젝트 회의록 | `e2b8ab5f-e9a9-834a-8267-074c42b20ba5` |
| 엔드포인트 (2) | `3428ab5f-e9a9-81fc-b47f-000be0cbe93a` |
| 프로젝트 일정 | `0428ab5f-e9a9-8257-8ba7-8744cb498ba6` |
