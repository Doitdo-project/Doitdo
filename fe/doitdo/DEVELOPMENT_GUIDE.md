# doitdo 개발 가이드

이 문서는 **화면 작업을 시작하는 팀원을 위한 실전 가이드**다.
"파일을 어디에 만들지, 공통 컴포넌트는 언제 분리할지, 로직은 어디에 둘지"에 대한 규칙을 담았다.

> API/네트워킹/Repository 작업은 이후에 다룬다. 지금은 **UI 레이어만** 다룬다.

---

## 목차

1. [아키텍처 3줄 요약](#1-아키텍처-3줄-요약)
2. [폴더 구조 한눈에](#2-폴더-구조-한눈에)
3. [화면 하나를 만드는 순서](#3-화면-하나를-만드는-순서)
4. [레이아웃 3단 구조: Scaffold / Layout / TopBar](#4-레이아웃-3단-구조-scaffold--layout--topbar)
5. [공통 컴포넌트는 어디에? 분리 기준](#5-공통-컴포넌트는-어디에-분리-기준)
6. [ViewModel과 상태 관리](#6-viewmodel과-상태-관리)
7. [테마 · 컬러 · 텍스트 스타일 사용법](#7-테마--컬러--텍스트-스타일-사용법)
8. [다이얼로그 / 바텀시트 / 로딩 오버레이](#8-다이얼로그--바텀시트--로딩-오버레이)
9. [네비게이션 (페이지 이동)](#9-네비게이션-페이지-이동)
10. [네이밍 · 임포트 · 주석 컨벤션](#10-네이밍--임포트--주석-컨벤션)
11. [자주 나오는 질문](#11-자주-나오는-질문)
12. [API 연동 가이드](#12-api-연동-가이드)

---

## 1. 아키텍처 3줄 요약

- **Clean Architecture + MVVM**: 레이어를 `presentation / domain / data / core` 로 나눈다.
- **화면 단위는 `presentation/pages/<feature>/`** 에 두고, 그 안에 View(페이지), ViewModel, 화면 전용 위젯을 모은다.
- **재사용되는 UI는 `presentation/widgets/` 로 승격**. 같은 화면에서만 쓰는 위젯은 해당 feature 폴더 안에 둔다.

도메인/데이터 레이어는 API 작업 시작하면 그때 채운다. 지금은 **건드리지 않아도 된다.**

---

## 2. 폴더 구조 한눈에

```
lib/
├─ main.dart                       # 앱 엔트리포인트 (Firebase/Hive/Prefs 초기화)
├─ app.dart                        # MaterialApp 세팅 (theme/router 연결)
│
├─ core/                           # 앱 전역에서 공유되는 "순수 유틸/설정"
│  ├─ theme/
│  │  ├─ app_colors.dart           # 원본 컬러 팔레트 (raw hex) — 직접 쓰지 말 것
│  │  ├─ app_text_styles.dart      # 폰트/사이즈 정의 (색상 없음)
│  │  ├─ doitdo_colors.dart        # 시맨틱 컬러 토큰 (라이트/다크) ★ 위젯에서 실제로 쓰는 것
│  │  └─ app_theme.dart            # ThemeData 조립 (여길 직접 수정할 일은 거의 없음)
│  ├─ constants/                   # 앱 전역 상수
│  ├─ errors/                      # 공통 예외/실패 타입
│  ├─ network/                     # Dio/ApiClient (API 작업 시 사용)
│  ├─ notifications/               # FCM 초기화
│  └─ utils/                       # 환경변수, 로거 등 유틸
│
├─ data/                           # (API 작업 시) 모델, DataSource, Repository 구현
├─ domain/                         # (API 작업 시) Entity, Repository 인터페이스
│
└─ presentation/
   ├─ navigation/
   │  └─ app_router.dart           # go_router 라우트 정의
   ├─ pages/                       # ★ 화면 단위 feature 폴더 — 작업의 중심
   │  ├─ splash/
   │  │  └─ splash_page.dart
   │  ├─ todo/
   │  │  ├─ todo_page.dart
   │  │  ├─ todo_view_model.dart       # (예정) 상태/로직
   │  │  └─ widgets/                   # (예정) 이 화면에서만 쓰는 위젯
   │  ├─ tamagochi/
   │  └─ setting/
   ├─ providers/                   # 앱 전역 Riverpod provider
   │  ├─ app_data_providers.dart       # DI 컨테이너 (Dio, SharedPrefs 등)
   │  ├─ theme_mode_provider.dart      # 테마 모드 전환
   │  └─ loading_overlay_provider.dart # 전역 로딩 오버레이
   └─ widgets/                     # ★ 여러 화면에서 재사용하는 UI
      ├─ common/                   # 범용 위젯 (버튼, TopBar, Dialog 등)
      ├─ layouts/                  # 레이아웃 위젯 (Scaffold, PaddingLayout 등)
      └─ shell/                    # 탭 셸 (BottomNav 래퍼)
```

**핵심 규칙**

- **`pages/<feature>/` 가 우리의 작업 단위**다. 새 화면 만들면 여기에 폴더 하나.
- **`widgets/common/` 은 "재사용 가능해서 여기 왔다" 는 증거**. 1곳에서만 쓰이면 여기 두지 않는다.
- **`core/` 는 UI가 아닌 것들.** 컬러 팔레트, 유틸 함수, Dio 설정 같은 것만.

---

## 3. 화면 하나를 만드는 순서

"로그인 화면을 추가한다" 같은 상황에서 따라하는 **체크리스트**.

### Step 1. feature 폴더 만들기

```
lib/presentation/pages/login/
└─ login_page.dart
```

### Step 2. 페이지 껍데기 작성

```dart
// lib/presentation/pages/login/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_top_bar.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_padding_layout.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_scaffold.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DoitdoScaffold(
      topBar: const DoitdoTopBar(title: '로그인'),
      body: DoitdoPaddingLayout(
        top: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('이메일', style: AppTextStyles.bodyMedium.copyWith(
              color: context.colors.textSecondary,
            )),
            // ...
          ],
        ),
      ),
    );
  }
}
```

**규칙**

- 페이지 클래스는 `ConsumerWidget` 또는 `ConsumerStatefulWidget` 으로 만든다 (Riverpod 접근용).
- Scaffold는 반드시 `DoitdoScaffold` 사용. 순정 `Scaffold` 직접 쓰지 말 것.
- 색상/텍스트 스타일은 `context.colors.xxx`, `AppTextStyles.xxx` 만 쓴다.

### Step 3. 라우트 등록

`lib/presentation/navigation/app_router.dart` 에 추가.

```dart
class AppRoutes {
  static const String login = '/login';
}

// routes 리스트에 추가
GoRoute(
  path: AppRoutes.login,
  builder: (context, state) => const LoginPage(),
),
```

메인 탭 내부 화면이면 해당 `StatefulShellBranch` 의 하위 라우트로, 탭 바깥의 전체화면이면 최상위 라우트로.

### Step 4. 화면 이동 연결

```dart
context.push(AppRoutes.login);  // 스택에 쌓기 (뒤로가기 가능)
context.go(AppRoutes.login);    // 스택 교체 (뒤로가기 불가)
```

### Step 5. 상태·로직이 생기면 ViewModel 추가

→ [6. ViewModel과 상태 관리](#6-viewmodel과-상태-관리)

---

## 4. 레이아웃 3단 구조: Scaffold / Layout / TopBar

우리 화면은 **3단 샌드위치**다. 순서를 외워 두자.

```
DoitdoScaffold                 ← 시스템 동작 (배경, 키보드 닫기, 로딩 오버레이)
  └─ DoitdoPaddingLayout       ← 여백 규칙 (또는 DoitdoFullLayout)
       └─ (화면 콘텐츠)
```

### `DoitdoScaffold` — 항상 사용

- 배경색(테마)
- 빈 영역 탭 시 키보드 자동 닫기
- 전역 로딩 오버레이 자동 구독
- SafeArea 기본 적용

**파라미터**

| 파라미터 | 용도 |
|---|---|
| `body` (필수) | 본문 |
| `topBar` | `DoitdoTopBar` 를 넣는다. 메인 탭에서는 생략 |
| `bottomNavigationBar` | **대부분 쓰지 않는다.** BottomNav는 셸이 담당 |
| `useSafeArea` | SafeArea 끄려면 false |
| `extendBodyBehindAppBar` | 헤더 뒤까지 콘텐츠가 비칠 때 |

### `DoitdoPaddingLayout` vs `DoitdoFullLayout`

- **`DoitdoPaddingLayout`** → 입력 폼, 리스트, 설정처럼 **좌우 24px 여백이 필요한 화면**.
- **`DoitdoFullLayout`** → 다마고치 캐릭터, 지도, 전체 일러스트처럼 **화면 끝까지 써야 하는 화면**.

두 위젯을 섞어 쓰지 말자. 한 페이지는 하나만 선택.

### `DoitdoTopBar` — 상세/하위 화면에서만

- 메인 3탭(할 일/홈/설정)에서는 **안 씀** (topBar 자리에 아무것도 넣지 말 것).
- 디테일 화면, 설정 하위 화면처럼 **뒤로가기(undo)가 필요한 곳에서만** 사용.
- `Navigator.canPop` 이면 자동으로 back 버튼이 생긴다. 별도 설정 불필요.

```dart
DoitdoScaffold(
  topBar: const DoitdoTopBar(title: '카테고리 추가'),
  body: DoitdoPaddingLayout(child: ...),
)
```

---

## 5. 공통 컴포넌트는 어디에? 분리 기준

### 위치 기준 (flowchart)

```
새 위젯이 필요하다
  │
  ├─ 이 화면에서만 쓸 것 같다
  │     → lib/presentation/pages/<feature>/widgets/ 에 둔다
  │
  └─ 다른 화면에서도 쓸 것 같거나, 이미 쓰고 있다
        → lib/presentation/widgets/common/ 로 승격
```

### "언제 쪼개나" — 위젯 분리 기준

팀이 플러터를 처음이면 **과도하게 쪼개는 것보다, 너무 안 쪼개서 한 파일이 500줄 넘는 게 더 자주 일어난다.** 다음 중 하나라도 해당되면 위젯을 분리한다.

1. **한 화면에서 build 메서드가 200줄을 넘는다** → 섹션 단위로 쪼갠다.
2. **같은 블록(예: 투두 카드 UI)이 2번 이상 등장한다** → 위젯으로 뽑는다.
3. **setState/상태가 국소적으로만 필요한 블록이 있다** → `StatefulWidget` 로 분리해 상태를 가둔다.
4. **디자이너가 "이건 OO 컴포넌트야" 라고 이름을 부여한다** → 같은 이름의 위젯을 만든다.

### "너무 쪼개지 말 것"

- 딱 한 번만 쓰는 `Text` + `Padding` 조합을 굳이 `_SectionLabel` 위젯으로 뽑지 말자. 가독성 손해.
- "혹시 나중에 쓸 수도 있어서" 미리 공용화하지 말자. 두 번째로 필요해진 시점에 옮긴다.

### 공통 컴포넌트 네이밍

- 전부 **`Doitdo`** prefix: `DoitdoPrimaryButton`, `DoitdoDialog`, `DoitdoChip` 등.
- 파일명은 `doitdo_primary_button.dart` 형태.
- 이 prefix 때문에 import 해서 들어온 위젯이 "우리가 만든 공통 것"인지 한눈에 구분된다.

### 이미 만들어진 공통 위젯 목록

| 위젯 | 용도 |
|---|---|
| `DoitdoScaffold` | 모든 화면의 베이스 Scaffold |
| `DoitdoPaddingLayout` / `DoitdoFullLayout` | 본문 래퍼 |
| `DoitdoTopBar` | 상단 바 (뒤로가기 자동) |
| `DoitdoBottomNav` | 하단 탭 바 (셸이 사용) |
| `DoitdoPrimaryButton` | 기본 버튼 (radius 12) |
| `DoitdoDialog` / `showDoitdoDialog()` | 다이얼로그 (radius 24) |
| `DoitdoBottomSheet` / `showDoitdoBottomSheet()` | 바텀시트 |

---

## 6. ViewModel과 상태 관리

### 규칙

- **상태와 로직은 페이지 클래스(View)에 쓰지 않는다.** View는 "그리기"만.
- feature 폴더 안에 **`<feature>_view_model.dart`** 파일을 만들고, `StateNotifier` 또는 `AsyncNotifier` 로 구현한다.
- 상태 타입은 가능하면 **`freezed` sealed class**로 `Loading/Success/Error` 분리.

### 최소 템플릿 (간단한 상태)

```dart
// lib/presentation/pages/todo/todo_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TodoState {
  const TodoState({this.items = const [], this.isLoading = false});
  final List<String> items;
  final bool isLoading;

  TodoState copyWith({List<String>? items, bool? isLoading}) =>
      TodoState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
      );
}

class TodoViewModel extends StateNotifier<TodoState> {
  TodoViewModel() : super(const TodoState());

  void add(String title) {
    state = state.copyWith(items: [...state.items, title]);
  }
}

final todoViewModelProvider =
    StateNotifierProvider.autoDispose<TodoViewModel, TodoState>(
  (ref) => TodoViewModel(),
);
```

### View에서 쓰기

```dart
class TodoPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todoViewModelProvider);
    final vm = ref.read(todoViewModelProvider.notifier);

    return DoitdoScaffold(
      body: DoitdoPaddingLayout(
        child: Column(
          children: [
            for (final item in state.items) Text(item),
            DoitdoPrimaryButton(
              label: '추가',
              onPressed: () => vm.add('새 할 일'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 로직을 어디에 쓸지 헷갈릴 때

| 종류 | 위치 |
|---|---|
| 서버 호출, DB 저장, 복잡한 계산 | ViewModel |
| 화면 상태(입력값, 선택된 탭 등) | ViewModel |
| "버튼 눌렀을 때 다른 페이지로 이동" | View (단순 navigation 한 줄이면 OK) |
| "A를 저장한 뒤 B 화면으로 이동" | ViewModel이 저장하고, View가 성공 상태를 `ref.listen` 으로 감지해 이동 |
| 포맷팅/문자열 조합 (UI 전용) | View 내부에서 해도 OK |

### `ref.watch` vs `ref.read` vs `ref.listen`

- `ref.watch(provider)` → 값이 바뀌면 **rebuild**. build 메서드 안에서 사용.
- `ref.read(provider)` → **한 번만** 읽기. 콜백(onPressed 등) 안에서 사용.
- `ref.listen(provider, (prev, next) {})` → 값 변화에 **부수효과**(스낵바, 페이지 이동)만 수행. 리빌드 안 함.

### Provider 위치

- **화면 전용 ViewModel** → 해당 feature 폴더 안 (`todo_view_model.dart`).
- **앱 전역 상태**(테마 모드, 전역 로딩 등) → `presentation/providers/`.
- **DI**(Dio, SharedPreferences 등) → `presentation/providers/app_data_providers.dart` 한 곳에 모은다.

---

## 7. 테마 · 컬러 · 텍스트 스타일 사용법

### 컬러

**3종류의 컬러 소스가 있다. 반드시 구분할 것.**

1. **`AppColors` (원본 팔레트)** — `lib/core/theme/app_colors.dart`
   직접 쓰지 말 것. 디자인 팔레트 원본일 뿐.
2. **`DoitdoColors` (시맨틱 토큰)** — 위젯에서 **실제로 쓰는 것**.
   라이트/다크에 따라 자동으로 바뀐다.
3. **`Theme.of(context).colorScheme`** — Material 위젯이 내부적으로 참조.
   굳이 직접 쓸 일 없음.

```dart
// ✅ GOOD
Container(color: context.colors.surface)
Text('hi', style: TextStyle(color: context.colors.textPrimary))

// ❌ BAD — 다크모드에서 깨짐
Container(color: Colors.white)
Container(color: AppColors.textDefault)
```

**`DoitdoColors` 에 있는 토큰**

| 토큰 | 의미 |
|---|---|
| `background` | 페이지 기본 배경 |
| `surface` | 카드, 다이얼로그 등 "떠 있는" 표면 |
| `surfaceAlt` | 보조 배경 (섹션 구분, 비활성 칩) |
| `primary` / `onPrimary` | 브랜드 컬러 / 그 위의 텍스트 색 |
| `textPrimary` / `textSecondary` / `textHint` | 텍스트 3단계 |
| `border` / `divider` | 테두리 / 구분선 |
| `topBarBg` / `bottomNavBg` | 상단/하단 바 배경 |
| `scrim` | 모달 뒤 어두운 오버레이 |

**카테고리 컬러처럼 "의미가 특화된" 색**은 아직 `AppColors.category1~8` 을 그대로 참조한다. 다크모드에서 따로 대응이 필요해지면 `DoitdoColors` 로 옮긴다.

### 텍스트 스타일

- `AppTextStyles` 에서 가져와 사용. **색상은 이미 `ThemeData.textTheme` 을 통해 자동 주입되므로 대개는 그대로 써도 된다**.
- 하지만 **특정 역할에서는 텍스트 색이 기본과 달라야 할 때** (예: hint, secondary) 아래처럼 `copyWith` 로 덮는다.

```dart
Text('이메일', style: AppTextStyles.bodyMedium)                          // 기본 textPrimary
Text('선택사항', style: AppTextStyles.bodySmall.copyWith(
  color: context.colors.textSecondary,
))
```

**사이즈 고정 원칙**

- 디자인상 정의된 것 이외의 사이즈/weight 를 **코드에서 임의로 만들지 말 것**.
- 필요하면 `AppTextStyles` 에 새 스타일을 추가하고, 주석으로 "어느 화면에서 쓰이는지" 표기.

### 다크모드 테스트

설정 화면 → 테마 토글 → "다크"를 선택해서 **무조건 한 번씩 보고 넘어간다.**
새 화면을 만들면 PR 올리기 전에 라이트/다크 둘 다 스크린샷.

---

## 8. 다이얼로그 / 바텀시트 / 로딩 오버레이

### 다이얼로그

```dart
final ok = await showDoitdoDialog(
  context: context,
  title: '삭제하시겠어요?',
  message: '이 할 일은 되돌릴 수 없어요.',
  confirmLabel: '삭제',
  cancelLabel: '취소',
);
if (ok == true) {
  // 삭제 로직
}
```

- `cancelLabel` 을 주지 않으면 **확인 버튼만** 있는 다이얼로그.
- 복잡한 본문(입력 폼 등)이 필요하면 `content: MyCustomWidget()` 를 넘긴다.

### 바텀시트

```dart
await showDoitdoBottomSheet<void>(
  context: context,
  title: '반복 설정',
  child: Column(
    children: [ /* 내용 */ ],
  ),
);
```

키보드가 올라와도 내용이 안 가려지게 자동으로 padding 조정된다.

### 로딩 오버레이

```dart
// 로직 시작
ref.read(loadingOverlayProvider.notifier).state = true;
try {
  await doSomethingSlow();
} finally {
  ref.read(loadingOverlayProvider.notifier).state = false;
}
```

`DoitdoScaffold` 가 구독하고 있기 때문에 **어떤 화면에 있든** 반투명 오버레이 + 스피너가 뜬다.

---

## 9. 네비게이션 (페이지 이동)

### 경로 상수

`app_router.dart` 의 `AppRoutes` 에 이미 정의돼 있다.

```dart
context.push(AppRoutes.setting);   // 스택에 쌓기
context.go(AppRoutes.tamagochi);   // 스택 교체
context.pop();                     // 뒤로가기
```

### 탭 간 이동

BottomNav를 통한 탭 전환은 자동이다. 별도 코드 필요 없음.
탭을 코드로 바꿔야 하는 경우만:

```dart
// 탭별로 go 호출
context.go(AppRoutes.todo);       // 할 일 탭으로
context.go(AppRoutes.tamagochi);  // 홈 탭으로
context.go(AppRoutes.setting);    // 설정 탭으로
```

### 탭 내부의 상세 화면

각 탭은 **독립된 스택**을 가진다. 할 일 탭에서 상세로 들어가면, 다른 탭으로 이동했다 돌아와도 상세 화면이 유지된다.

상세 화면 라우트는 해당 탭의 `StatefulShellBranch` 안에 중첩 라우트로 추가한다:

```dart
StatefulShellBranch(
  navigatorKey: _todoNavigatorKey,
  routes: [
    GoRoute(
      path: AppRoutes.todo,
      builder: (context, state) => const TodoPage(),
      routes: [
        GoRoute(
          path: 'detail/:id',     // /todo/detail/123
          builder: (context, state) =>
              TodoDetailPage(id: state.pathParameters['id']!),
        ),
      ],
    ),
  ],
),
```

이동:

```dart
context.push('${AppRoutes.todo}/detail/$todoId');
```

---

## 10. 네이밍 · 임포트 · 주석 컨벤션

### 네이밍

| 대상 | 규칙 | 예 |
|---|---|---|
| 페이지 | `*_page.dart` / `XxxPage` | `todo_page.dart` / `TodoPage` |
| ViewModel | `*_view_model.dart` / `XxxViewModel` | `todo_view_model.dart` |
| 공통 위젯 | `doitdo_*.dart` / `DoitdoXxx` | `doitdo_dialog.dart` |
| Provider | 파일명은 기능 중심, 식별자는 `xxxProvider` | `themeModeProvider` |
| 폴더 | 소문자 단수 명사 | `todo/`, `setting/` |

### 임포트 순서

```dart
// 1. dart:
import 'dart:async';

// 2. package: — 외부 패키지
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 3. package: — 우리 프로젝트 (package:doitdo/...)
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_scaffold.dart';
```

- **상대 경로(`../`) 는 금지**. 전부 `package:doitdo/...` 로 쓴다.
- 블록 사이는 빈 줄로 분리.

### 주석

- **WHAT(이 코드가 뭘 하는지)은 쓰지 않는다.** 코드가 말해준다.
- **WHY(왜 이렇게 했는지)만 쓴다.** 특히 다음의 경우:
  - 외부 제약(패키지 버그 회피, 디자인 결정)
  - 겉으로 잘 안 보이는 불변조건
  - "이거 왜 이렇게 짰지?" 싶어질 만한 부분
- 클래스 상단에 **1~3줄 짜리 의도 설명**은 권장. 예:

```dart
/// 메인 홈(다마고치) 탭.
/// 캐릭터가 화면 전체를 채워야 하므로 DoitdoFullLayout 을 쓰고,
/// TopBar 는 의도적으로 두지 않는다.
class TamagochiPage extends ConsumerWidget { ... }
```

---

## 11. 자주 나오는 질문

### Q1. `Scaffold` 를 직접 써도 되나?
**원칙적으로 안 된다.** `DoitdoScaffold` 를 써야 배경색/키보드/로딩 오버레이가 일관되게 적용된다.
예외: 스플래시처럼 완전히 독립적인 화면.

### Q2. `const` 는 언제 붙이나?
**가능한 모든 곳에.** 위젯 트리 리빌드 비용이 크게 줄어든다.
린트가 `prefer_const_constructors` 로 알려준다.

### Q3. 상태가 하나뿐인데 ViewModel을 만들어야 하나?
아니. 로컬 상태만 있고 다른 곳에서 쓸 일 없으면 `StatefulWidget` 의 `setState` 로 충분하다.
**서버 호출, 여러 화면에서 공유되는 값, 복잡한 파생 상태** 가 생기면 그때 ViewModel로 뽑는다.

### Q4. 같은 위젯을 살짝 다른 스타일로 여러 곳에서 쓰고 싶다
파라미터로 받을 수 있게 위젯을 설계한다. 스타일 전용 파라미터(`variant`, `size` 같은 enum)를 받는 게 일반적.

### Q5. 값 포맷팅(날짜, 숫자) 은 어디에?
`intl` 패키지를 쓴다. 자주 쓰는 포맷은 `core/utils/formatters.dart` 같은 곳에 모아 둘 것.

### Q6. 이미지/아이콘 에셋은?
- 이미지: `assets/images/`
- 아이콘: `assets/icons/`
- 애니메이션(Lottie 등): `assets/animations/`
- 코드에서: `Image.asset('assets/images/foo.png')` — `pubspec.yaml` 에 이미 폴더 등록돼 있음.

### Q7. 폰트는 어떻게 바꾸나?
폰트 패밀리는 `app_text_styles.dart` 상단의 `_light / _medium / _bold` 상수에 모여 있다.
바꾸려면 여기만 고치면 전 앱에 적용된다.
(주의: 폰트 파일은 `pubspec.yaml` 에 `fonts:` 섹션으로 등록돼 있어야 한다.)

### Q8. 빌드가 안 돼요
1. `flutter clean && flutter pub get`
2. `flutter analyze` 로 에러 메시지 확인
3. 그래도 안 되면 팀원에게 에러 로그 전체 공유

---

## 12. API 연동 가이드

서버 붙는 순간부터 전 화면이 이 절차를 따라야 한다. 한 엔드포인트 당 **5 파일 + Provider 2개 + 코드젠 1번**이 기본 단위.

### 12.1 전체 구조

```
data/datasources/{feature}_api.dart        # retrofit 인터페이스 (@RestApi)
data/datasources/{feature}_api.g.dart      # ← build_runner 산출물
data/models/{xxx}_dto.dart                 # JSON ↔ DTO (수동 fromJson)
domain/repositories/{feature}_repository.dart        # abstract
data/repositories/{feature}_repository_impl.dart     # BaseRepository 상속
```

공통 인프라는 전부 `core/network/` 아래에 이미 있다 (**건드리지 말 것**):
- `api_response.dart` — `{status, message, data}` envelope 제네릭
- `dio_error_mapper.dart` — `DioException` → 타입드 예외 매핑
- `logging_interceptor.dart` — 디버그 빌드 요청/응답 로깅
- `base_repository.dart` — `safeApiCall<T>` / `safeApiCallNoData`
- `api_client.dart` — Dio 팩토리

레퍼런스 구현: `/api/users/check-email` (이메일 중복 체크). 아래 예시는 이 파일들을 보면서 읽는다.

### 12.2 Retrofit 인터페이스

응답은 **무조건 `Future<ApiResponse<XxxDto>>`** 로 선언한다. envelope 을 수동으로 까지 않는다.

```dart
// data/datasources/user_api.dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:doitdo/core/network/api_response.dart';
import 'package:doitdo/data/models/check_email_response_dto.dart';

part 'user_api.g.dart';

@RestApi()
abstract class UserApi {
  factory UserApi(Dio dio, {String baseUrl}) = _UserApi;

  @GET('/api/users/check-email')
  Future<ApiResponse<CheckEmailResponseDto>> checkEmail(
    @Query('email') String email,
  );
}
```

새 파일을 만들거나 엔드포인트를 추가한 뒤에는 **반드시**:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 12.3 DTO

지금은 수동 `fromJson` 스타일 (auth DTO 와 동일). freezed 전환은 팀 합의 후 일괄로.

```dart
// data/models/check_email_response_dto.dart
class CheckEmailResponseDto {
  const CheckEmailResponseDto({required this.available});

  final bool available;

  factory CheckEmailResponseDto.fromJson(Map<String, dynamic> json) =>
      CheckEmailResponseDto(available: json['available'] as bool);
}
```

도메인 엔티티 매핑이 필요하면 DTO 에 `toEntity()` 메서드를 달아서 RepositoryImpl 에서 호출한다.

### 12.4 Repository (domain 인터페이스 + data 구현)

**추상 인터페이스는 `domain/`, 구현은 `data/`.** 구현체는 **반드시 `BaseRepository` 상속 + `safeApiCall` 로 감싸기.**

```dart
// domain/repositories/user_repository.dart
abstract class UserRepository {
  Future<bool> isEmailAvailable(String email);
}

// data/repositories/user_repository_impl.dart
class UserRepositoryImpl extends BaseRepository implements UserRepository {
  UserRepositoryImpl(this._api);
  final UserApi _api;

  @override
  Future<bool> isEmailAvailable(String email) =>
      safeApiCall(() => _api.checkEmail(email)).then((dto) => dto.available);
}
```

여기서 `safeApiCall` 이 해주는 일:
- `DioException` → `NetworkException / RequestTimeoutException / UnauthorizedException / ServerException / UnknownException` 변환
- envelope `status != 2xx` → `ServerException` throw (BE 가 보내준 `message` 포함)
- `data == null` → `ServerException` throw (삭제/로그아웃 등 본문 없는 엔드포인트는 `safeApiCallNoData` 사용)

**RepositoryImpl 에 try/catch 금지.** 추가 처리가 필요하면 그건 ViewModel 이나 공통 처리 훅에서 한다.

### 12.5 DI (Provider)

`presentation/providers/app_data_providers.dart` 에 2개 추가. 다른 파일에 분산 금지 — DI 는 한 곳에서 본다.

```dart
final userApiProvider = Provider<UserApi>(
  (ref) => UserApi(ref.watch(dioProvider)),
);

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepositoryImpl(ref.watch(userApiProvider)),
);
```

### 12.6 ViewModel — API 붙을 땐 `AsyncNotifier` 를 쓴다

mock 만 보여주는 화면은 기존 `StateNotifier<XxxState>` 로도 충분하지만, **서버를 호출하는 화면은 반드시 `AsyncNotifier` / `AsyncNotifierProvider`** 로 간다. Riverpod 이 loading/data/error 3상태를 자동 관리하고, Repository 가 던진 타입드 예외가 그대로 `AsyncValue.error` 로 흘러들어온다.

```dart
// presentation/pages/auth/register/email_check_view_model.dart
class EmailCheckViewModel extends AsyncNotifier<bool?> {
  @override
  Future<bool?> build() async => null; // 초기: 아직 검사 안 함

  Future<void> check(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(userRepositoryProvider).isEmailAvailable(email),
    );
  }
}

final emailCheckViewModelProvider =
    AsyncNotifierProvider<EmailCheckViewModel, bool?>(EmailCheckViewModel.new);
```

View 에서는 `when` 한 번으로 끝:

```dart
final state = ref.watch(emailCheckViewModelProvider);
state.when(
  loading: () => const CircularProgressIndicator(),
  error: (e, _) => Text(_mapErrorMessage(e)),
  data: (available) => Text(
    available == null ? '' : (available ? '사용 가능' : '이미 사용 중'),
  ),
);

// 에러 메시지 변환은 화면마다 반복되지 않도록 공용 헬퍼로 추출할 것.
String _mapErrorMessage(Object e) => switch (e) {
      UnauthorizedException _ => '다시 로그인해 주세요.',
      NetworkException _ => '네트워크 연결을 확인해 주세요.',
      RequestTimeoutException _ => '응답이 지연되고 있어요. 잠시 후 다시 시도해 주세요.',
      ServerException se => se.message,
      _ => '알 수 없는 오류가 발생했어요.',
    };
```

### 12.7 체크리스트 (한 줄 규칙)

- [ ] `RepositoryImpl` 은 `BaseRepository` 상속 + `safeApiCall` 로 감쌌다
- [ ] `RepositoryImpl` 안에 `try/catch` 없다
- [ ] API 호출하는 ViewModel 은 `AsyncNotifier` 다 (StateNotifier 금지)
- [ ] ViewModel 안에 `try/catch` 없다 — `AsyncValue.guard` 가 대신 잡는다
- [ ] View 에서 `DioException` 을 import 하지 않았다 (타입드 예외만 본다)
- [ ] 새 Retrofit 엔드포인트 추가 후 `dart run build_runner build --delete-conflicting-outputs` 실행했다
- [ ] `.g.dart` 산출물을 함께 커밋했다 (gitignore 에서 제외되지 않은 프로젝트 정책)

---

## 부록: 치트시트

```dart
// 새 화면 만들기 최소 템플릿
class XxxPage extends ConsumerWidget {
  const XxxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DoitdoScaffold(
      topBar: const DoitdoTopBar(title: 'XXX'),
      body: DoitdoPaddingLayout(
        top: 16,
        child: ...,
      ),
    );
  }
}
```

```dart
// 자주 쓰는 access
context.colors.primary                        // 시맨틱 컬러
AppTextStyles.titleMedium                     // 텍스트 스타일
ref.watch(myProvider)                         // 상태 구독
ref.read(myProvider.notifier).doSomething()   // 메서드 호출
context.push(AppRoutes.xxx)                   // 페이지 이동
showDoitdoDialog(context: context, ...)       // 다이얼로그
showDoitdoBottomSheet(context: context, ...)  // 바텀시트
```