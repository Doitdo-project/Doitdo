# doitdo (FE) — Claude Onboarding

이 문서는 Claude(또는 새 합류자)가 프론트엔드 작업 전 가장 먼저 읽는 진입점이다.
세부 규칙은 노션이 단일 진실 출처(SSOT)이며, 여기서는 위치와 핵심 요약만 담는다.

Flutter 구현 레벨의 상세 가이드(폴더 규칙 / 공통 레이아웃 / ViewModel 작성법 / 자주 하는 질문)는 `fe/doitdo/DEVELOPMENT_GUIDE.md` 에 별도로 정리되어 있다.

---

## 1. 프로젝트 한눈에

- 서비스: **doitdo** (TODO + 다마고치)
- 스택: Flutter 3.x · Dart ^3.10.8 · Riverpod · go_router · Firebase(FCM)
- 프로젝트 루트: `fe/doitdo/`
- 앱 식별자: `com.d107.doitdo`
- 디자인 기준: **375 × 812** (`flutter_screenutil` 기준점)

### 1.1 빠른 실행

```bash
cd fe/doitdo
flutter pub get
flutter run
```

코드 생성이 필요한 경우(freezed, json_serializable, retrofit 등):

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 1.2 환경 파일

- `fe/doitdo/.env` — 환경변수 (gitignore, 로컬에 직접 복사)
- `fe/doitdo/.env.example` — 템플릿
- 로딩 위치: `lib/core/utils/app_env.dart` + `pubspec.yaml` assets 에 `.env` 등록

### 1.3 Firebase / FCM

현재 FCM 초기화는 일시 비활성화 상태. 활성화는 `lib/main.dart` 상단 주석 참조.
사전 작업:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
# → lib/firebase_options.dart
# → android/app/google-services.json
# → ios/Runner/GoogleService-Info.plist   가 자동 생성된다
```

생성 후 `main.dart` 의 Firebase import / init 블록 주석 해제.

---

## 2. 팀 규칙 (노션 SSOT)

작업 전 반드시 확인. 변경된 컨벤션은 항상 노션이 우선이다.

| 영역 | 노션 페이지 | 핵심 요약 |
|---|---|---|
| 팀 규칙 (허브) | https://www.notion.so/e158ab5fe9a983ab9e2d014ea5209a51 | Git / JIRA / BE / FE 컨벤션 모음 |
| **Git Convention** | https://www.notion.so/3448ab5fe9a98068bf77d1f7a8164045 | §3 참조 |
| **JIRA Convention** | https://www.notion.so/3448ab5fe9a980ff9da9ff5bc5094ec4 | §4 참조 |
| API 기본 명세서 | https://www.notion.so/3428ab5fe9a980c790a6f9161a900f22 | 도메인별 엔드포인트 + 카테고리 |

---

## 3. Git Convention (요약)

### 3.1 브랜치 전략

- `main` (운영) ← `dev` (개발 통합) ← feature 브랜치
- **`dev` 브랜치 직접 push 금지** — 모든 작업은 feature 브랜치에서 진행 후 MR로 병합
- 코드 리뷰 후 머지

### 3.2 브랜치 네이밍

```
fe/feat/{기능명}    # 예: fe/feat/tamagochi-ui
fe/fix/{이슈명}     # 예: fe/fix/keyboard-overflow
hotfix/{내용}
docs/{내용}         # 예: docs/fe-onboarding
```

### 3.3 커밋 메시지

형식: `type : (위치/기능) + 설명`

| type | 용도 |
|---|---|
| feat | 새 기능 |
| fix | 버그 수정 |
| add | 클래스/파일 추가 (기능 외) |
| refactor | 리팩토링 |
| docs | 문서 |
| style | 포맷팅/린트 등 |
| comment | 주석 |
| chore | 빌드/설정/잡일 |

예시:

```
feat : tamagochi/home 메인 홈 레이아웃 및 ViewModel 구현
fix : router/splash 스플래시 뒤로가기 중복 진입 수정
add : widgets/common DoitdoDialog 컴포넌트 추가
refactor : theme DoitdoColors ThemeExtension 으로 분리
docs : DEVELOPMENT_GUIDE 공통 레이아웃 가이드 업데이트
```

### 3.4 Merge Request

- 제목 형식: `[FE : feat] 작업 내용` (한글 권장, 기술 용어는 영어 가능)
- 템플릿 필수 사용 (Part / 변경사항 / 상세 / 체크리스트)
- 대상 브랜치: feature → **dev**

---

## 4. JIRA Convention (요약)

### 4.1 일감 종류

| 단위 | 의미 |
|---|---|
| Epic | 도메인 단위 |
| Story | 사용자 가치 (서술형: "사용자는 ~ 하고 싶다") |
| Task | 기술/관리 업무 |
| Sub-Task | 화면/컴포넌트 단위 (또는 커밋 단위) |

### 4.2 작업 제목

서두에 파트 prefix: `[FE]`, `[BE]`, `[DOCS]`, `[INFRA]`, `[AI]`, `[DB]`

### 4.3 도메인 구분 기준

**트리거 기준**으로 판정.
> 예: 다마고치 성장은 TODO 완료가 트리거 → `[FE] TODO ...`

### 4.4 도메인 담당 (FE)

TODO: 노션에서 확인 후 채움.

### 4.5 스토리 포인트 (피보나치: 1, 2, 3, 5, 8 위주)

- 1 매우 단순 / 2 단순 / 3 명확 / 5 표준 / 8 고난도 / 9 대규모 / 10 매우 위험

---

## 5. FE Convention (요약)

상세는 `fe/doitdo/DEVELOPMENT_GUIDE.md` 참조. 핵심:

### 5.1 아키텍처

Clean Architecture + MVVM:

```
fe/doitdo/lib/
 ├ core/              # theme, utils, network, errors, notifications (UI 아님)
 ├ domain/            # entities, repositories(추상), usecases (API 연동 단계에서 채움)
 ├ data/              # datasources(local/remote), models(dto), repositories(impl)
 └ presentation/
    ├ navigation/       # go_router 라우트
    ├ pages/{feature}/  # 화면 단위 폴더 (작업의 중심)
    ├ providers/        # 전역 Riverpod provider
    ├ models/           # 프레젠테이션 레이어 공용 모델
    └ widgets/
       ├ common/        # DoitdoXxx 재사용 위젯
       ├ layouts/       # Scaffold, PaddingLayout, FullLayout
       └ shell/         # StatefulShellRoute 셸
```

### 5.2 폴더 위치 규칙

| 종류 | 위치 |
|---|---|
| 페이지 (View) | `presentation/pages/{feature}/{feature}_page.dart` |
| ViewModel | `presentation/pages/{feature}/{feature}_view_model.dart` |
| 화면 상태 | `presentation/pages/{feature}/{feature}_state.dart` |
| 화면 전용 위젯 | `presentation/pages/{feature}/widgets/` |
| 공통 위젯 | `presentation/widgets/common/doitdo_*.dart` |
| 공통 레이아웃 | `presentation/widgets/layouts/` |
| 전역 provider (DI, 테마, 로딩) | `presentation/providers/` |

**승격 기준**: 2개 이상 feature 에서 사용되면 `widgets/common/` 으로 이동.

### 5.3 네이밍 규칙

| 컴포넌트 | 규칙 | 예 |
|---|---|---|
| 페이지 | `*_page.dart` / `XxxPage` | `todo_page.dart` / `TodoPage` |
| ViewModel | `*_view_model.dart` / `XxxViewModel` | `todo_view_model.dart` |
| State | `*_state.dart` / `XxxState` | `todo_state.dart` |
| 공통 위젯 | `doitdo_*.dart` / `DoitdoXxx` | `doitdo_dialog.dart` |
| Provider 식별자 | `xxxProvider` (camelCase) | `themeModeProvider` |
| 폴더 | 소문자 단수 명사 | `todo/`, `setting/` |

### 5.4 공통 기반 위젯

반드시 사용 (순정 Scaffold 직접 사용 금지):

- `DoitdoScaffold` — 모든 페이지 베이스 (배경/키보드 자동 닫기/로딩 오버레이)
- `DoitdoPaddingLayout` (24px) / `DoitdoFullLayout` — 본문 래퍼
- `DoitdoTopBar` — 상세 페이지 상단바 (뒤로가기 자동)
- `DoitdoPrimaryButton` — 기본 버튼 (radius 12)
- `DoitdoDialog` / `showDoitdoDialog()` — 다이얼로그 (radius 24)
- `DoitdoBottomSheet` / `showDoitdoBottomSheet()` — 바텀시트

### 5.5 테마 · 컬러 · 폰트

- **원본 팔레트**: `core/theme/app_colors.dart` (raw hex) — 위젯에서 직접 참조 금지
- **시맨틱 토큰**: `core/theme/doitdo_colors.dart` (`ThemeExtension<DoitdoColors>`) — 위젯에서 이것만 사용
- 접근: `context.colors.primary` / `context.colors.textPrimary` 등
- 텍스트 스타일: `AppTextStyles.xxx` (색상은 `copyWith` 로 보정)
- 폰트: GmarketSans (Light / Medium / Bold) — `assets/fonts/`
- 라이트/다크 모드 자동 전환. 새 화면은 양쪽 확인 필수.

### 5.6 반응형 크기 (`flutter_screenutil`)

디자인(375×812) 값을 그대로 적되 단위 붙임:

- `.w` 가로 / `.h` 세로 / `.r` 반지름 / `.sp` 폰트·아이콘 크기
- **`MediaQuery` 비율 사용 금지** (디바이스별로 디자인 의도 깨짐)
- 예: `height: 220.h`, `padding: EdgeInsets.all(16.w)`, `BorderRadius.circular(12.r)`, `fontSize: 14.sp`

### 5.7 라우팅

`go_router` + `StatefulShellRoute.indexedStack`:

- 메인 탭(할 일 / 홈 / 설정)은 각자 독립 스택 보존
- 라우트 정의: `presentation/navigation/app_router.dart`
- 이동: `context.push(AppRoutes.xxx)` / `context.go(...)` / `context.pop()`

### 5.8 상태 관리

Riverpod — `StateNotifier` + `StateNotifierProvider`. 리포지토리 붙는 시점부터 비동기 로딩은 `AsyncNotifier` 로 확장.

- `ref.watch(provider)` = 구독 (rebuild 유발)
- `ref.read(provider)` = 1회 읽기 (콜백 안에서)
- `ref.listen(provider, ...)` = 부수효과 (스낵바/페이지 이동 등)

### 5.9 DI / 전역 의존성

`presentation/providers/app_data_providers.dart` 한 파일에 수동 선언:

- `dioProvider`, `sharedPreferencesProvider` 등
- 외부 의존성(`SharedPreferences`) 은 `main.dart` 에서 `override` 로 주입.

---

## 6. Claude 작업을 위한 보조 메모

- 작업 시작 전 **§2 노션 링크 확인**.
- 네이밍·폴더 위치는 §5, 커밋·브랜치는 §3, 티켓은 §4 기준.
- 노션이 변경되면 이 문서 §3~§5 요약도 갱신.
- 새 화면을 추가할 때:
  1. `presentation/pages/{feature}/` 폴더 생성
  2. `{feature}_page.dart`, `{feature}_view_model.dart`, `{feature}_state.dart` 순으로 작성
  3. `presentation/navigation/app_router.dart` 에 라우트 등록
  4. 세부 체크리스트는 `fe/doitdo/DEVELOPMENT_GUIDE.md §3` 참조
- 새 공통 위젯을 만들 때:
  1. 우선 해당 feature 폴더 안(`pages/{feature}/widgets/`) 에 둔다
  2. 두 번째 사용처가 생기는 시점에 `widgets/common/` 로 승격
- Firebase 설정 / 에셋 추가 / 폰트 변경은 `pubspec.yaml` 수정 필수 → PR 설명에 명시.