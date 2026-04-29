# 통합 코드 리뷰 리포트 — dev → main 통합 직전

## 컨텍스트

- **작업**: `be/feat/user-birthdate-age-check` 브랜치 (만 14세 차단 + 단계별 온보딩 API) 머지 직전
- **누적 변경 (main 대비)**: 543 files / 47,880 insertions / 3,220 deletions
- **방식**: 5영역 병렬 리뷰 (Codex 4 + Sonnet 1) — 모든 정적 분석, 빌드/테스트 미실행
- **총 발견**: **HIGH 14건 / MEDIUM 31건 / LOW 17건**

## 영역별 결과 분포

| # | 영역 | 도구 | HIGH | MEDIUM | LOW | 상세 |
|---|---|---|---|---|---|---|
| 1 | BE 코어 | Codex (gpt-5.5 xhigh) | 3 | 12 | 4 | [01-be-core-review.md](./01-be-core-review.md) |
| 2 | BE 테스트 | Codex (gpt-5.5 xhigh) | 2 | 4 | 3 | [02-be-tests-review.md](./02-be-tests-review.md) |
| 3 | FE flutter/lib | Codex (gpt-5.5 xhigh) | 4 | 7 | 3 | [03-fe-lib-review.md](./03-fe-lib-review.md) |
| 4 | FE iOS native | Codex (gpt-5.5 xhigh) | 2 | 4 | 3 | [04-fe-ios-review.md](./04-fe-ios-review.md) |
| 5 | FE Android + 기타 | Sonnet Agent | 3 | 4 | 4 | [05-fe-android-misc-review.md](./05-fe-android-misc-review.md) |
| **합계** | | | **14** | **31** | **17** | |

---

## 🚨 HIGH 14건 통합 — 머지 전 차단 권장

### 카테고리 1: 인증/토큰 보안 (5건) — **가장 시급**

| ID | 영역 | 이슈 | 핵심 위험 |
|---|---|---|---|
| BE-H2 | BE 코어 | `refresh_tokens.user_id` 유니크 제약 누락 | 동시 로그인 race → 500 / refresh 실패 |
| FE-LIB-H2 | FE lib | refresh token 을 위젯 공유 저장소에 복제 | 위젯 저장소 정리 누락 시 토큰 잔존 |
| FE-iOS-H2 | FE iOS | refresh token App Group UserDefaults 평문 저장 | 위젯-앱 동시 401 시 refresh pair 덮어쓰기 |
| FE-AND-H2 | FE Android | OAuth 토큰을 평문 SharedPreferences 저장 | pubspec "SharedPreferences 금지" 정책 자기모순. 루팅 시 탈취 |
| BE-T-H2 | BE 테스트 | `apple-test-key.p8` private key PEM 커밋 | 더미 여부 확인 필요 — 실제 키면 즉시 폐기/회전 |

→ **공통 원인**: refresh token 의 다중 저장소 복제 + secure storage 우회. 위젯 인증 모델 재설계 필요.

### 카테고리 2: 시크릿/빌드 보안 (2건)

| ID | 영역 | 이슈 | 핵심 위험 |
|---|---|---|---|
| FE-AND-H1 | FE Android | `pubspec.yaml` assets 에 `.env` 등록 | APK/AAB/web 산출물에 평문 번들 (apktool 추출 가능) |
| FE-AND-H3 | FE Android | `kakaoNativeAppKey` 빈 폴백 + manifest scheme 등록 | 같은 기기 악성 앱이 OAuth 코드 인터셉트 |

### 카테고리 3: 컴플라이언스/스펙 (1건)

| ID | 영역 | 이슈 | 핵심 위험 |
|---|---|---|---|
| FE-LIB-H3 | FE lib | 만 14세 게이트가 FE 가입/소셜 신규 유저 분기에 없음 | BE 만 막혀있고 FE 우회 가능. 본 브랜치의 핵심 기능과 직결 |

### 카테고리 4: 운영 안정성 / 마이그레이션 (2건)

| ID | 영역 | 이슈 | 핵심 위험 |
|---|---|---|---|
| BE-H1 | BE 코어 | `application.yml` 의 `JPA_DDL_AUTO:update` 기본값 | prod 에서 `JPA_DDL_AUTO` 미주입 시 Hibernate 가 prod 스키마 자동 변경 |
| BE-H3 | BE 코어 | 회원가입이 `characters` EGG seed 데이터 의존 | 신규/초기화 운영 DB 에 EGG seed 없으면 가입이 `U00_005` 로 실패 |

### 카테고리 5: 회귀/UX (4건)

| ID | 영역 | 이슈 | 핵심 위험 |
|---|---|---|---|
| BE-T-H1 | BE 테스트 | 만 14세 경계 테스트가 `2026-04-27` 하드코딩 | **2026-04-28부터** 의미가 뒤집혀 false-positive/negative 발생 |
| FE-LIB-H1 | FE lib | `WidgetSyncService` 초기화 인스턴스 ≠ provider 인스턴스 | App Group 적용이 임시 객체에만 → 실제 sync 실패 가능 |
| FE-LIB-H4 | FE lib | `GET /api/characters/me` 의 모든 ServerException 을 "미수령" 해석 | 500/403/도메인 오류에서도 자동 `POST /me/egg` mutation 발생 |
| FE-iOS-H1 | FE iOS | 위젯 토글이 detached PATCH fire-and-forget | 실패/순서 역전에도 성공 UI 확정. 빠른 멀티탭 시 상태 깨짐 |

---

## ⚠️ MEDIUM 31건 — 머지 후 fast-follow 권장

영역별 핵심 카테고리만 (전체는 영역 리포트):

- **BE 코어 (12)**: 반복 TODO 중복 방지 유니크 누락 (M1), 알림 스케줄러 멱등성 없음 (M2), exp 지급 race (M3), 활성 캐릭터 race (M4), TODO 페이지네이션 누락 (M5, M11), 캘린더 무한 occurrence (M6), Apple OAuth 응답 토큰 로그 노출 (M7), `/actuator/prometheus` 인증 없음 (M8), 바인딩 오류 500 처리 (M9), 소셜 가입 EGG 자동 생성 누락 (M10), SOMEDAY snooze NPE (M12)
- **BE 테스트 (4)**: `@Transactional` cleanup 누락 (M1), 컨트롤러 테스트가 MVC 우회 (M2), 서비스 호출 verify 누락 (M3), listener mock 미연결 false-positive (M4)
- **FE lib (7)**: Apple 로그인 후 FCM 등록 누락 (M1), Todo 삭제 에러 swallow (M2), Todo 토글 PATCH 결과 무시 (M3), 모든 state 변경마다 위젯 sync (M4), 이메일/아이디 중복 확인 race (M5), 보호 라우트 auth guard 없음 (M6), debug 로그 body 평문 (M7)
- **FE iOS (4)**: APNs 등록이 `super.application` 보다 먼저 (M1), Widget extension iOS 17.6 고정 (M2), Kakao xcconfig optional → Release 빈 scheme (M3), `PERMISSION_NOTIFICATIONS` 매크로 조건부 (M4)
- **FE Android+기타 (4)**: goAsync 한도 초과 위험 (M1), PendingIntent pre-S mutable (M2), `google-services.json` 커밋 + oauth_client 미등록 (M3), `WidgetSharedStore` 다중 쓰기 동시성 (M4)

→ **운영 인스턴스 ≥ 2** 시 BE-MEDIUM-1~4 (반복 TODO 중복, 알림 중복 발송, exp 지급 race, 활성 캐릭터 race) 는 즉시 위험.

---

## 📋 LOW 17건 — backlog

영역별 분포만:
- BE 코어 (4): 인벤토리 N+1, 카테고리 유니크 누락, PERIOD endDate 정책 분기, FCM noop 로그
- BE 테스트 (3): ExpCalculator 비결정, 가입 random egg 단일 fixture, listener fixture 잡음
- FE lib (3): SnapScrollPhysics clamp 누락, FCM listener cancel 부재, autoDispose 누락
- FE iOS (3): WidgetBackground colorset 빈 값, GeneratedPluginRegistrant gitignore + pbxproj 참조, Profile 빌드 development APNs
- FE Android+기타 (4): web CSP 부재, manifest.json 기본값, analysis_options 강화 부재, 위젯 updatePeriodMillis=0

---

## 권장 액션 (우선순위)

### P0 — 머지 전 필수 (HIGH 14건)
모두 차단. 특히 위 카테고리 1·2·3 의 **8건은 보안/컴플라이언스 직결**.

### P1 — 머지 후 1주 내 (MEDIUM 일부)
- BE 동시성 4종 (M1~M4): 운영 멀티 인스턴스 시 즉시 위험
- BE 보안 2종 (M7 Apple 토큰 로그, M8 actuator 노출)
- FE-lib-M2 / M3 (Todo 삭제·토글 에러 swallow)

### P2 — backlog (남은 MEDIUM + LOW 전부)

---

## 6축 커버리지 (모든 영역 ✓)

| 축 | 커버리지 |
|---|---|
| 보안 | ✓ 전 영역 |
| 회귀 | ✓ 전 영역 |
| 성능 | ✓ 전 영역 |
| 동시성 | ✓ 전 영역 |
| 리소스 | ✓ 전 영역 |
| 에러 처리 | ✓ 전 영역 |

---

## 🔄 재검증 (2026-04-28) — HIGH 14건 전체

`dev` 최신 (HEAD `56c3019`) 기준으로 HIGH 14건 전체를 Explore 서브 에이전트 read-only 로 재검증. **구현 코드 미수정.**

### 결과 요약 (14건)

| 우선순위 | ID | 영역 | 결론 | 한 줄 |
|---|---|---|---|---|
| **P0** | FE-LIB-H4 | 다마고치 | 성립 유지 | catch 분기 미수정. 500/403/envelope 실패 모두 미수령 오인 → POST `/me/egg` 자동 발화 |
| **P0** | FE-AND-H1 | 빌드 보안 | 부분 성립 유지 | `.env.example` 경고 주석만 추가. `pubspec.yaml:127` `- .env` 그대로 |
| **P1** | BE-H1 | DDL | (변경됨) 미성립 | `.env.prod.example` 만 가드. yml hard fix 권장 |
| **P1** | BE-H2 | refresh_tokens | 성립 유지 | UNIQUE 제약·race 방어 미수정. `auto_providers` 만 hotfix |
| **P1** | BE-H3 | EGG seed | 부분 성립 | seed SQL 추가됐으나 수동 실행 전용. 자동 적용 없음 |
| **P1** | BE-T-H2 | apple key PEM | 성립 유지 | 더미 추정. `git rm` + Apple 포털 확인 + `.gitignore` 권장 |
| **P1** | FE-LIB-H2 | 위젯 token 복제 | 성립 유지 (부분 완화) | signOut clearAll 추가, AuthInterceptor 401 경로 미정리 |
| **P1** | FE-iOS-H1 | iOS 위젯 토글 | 성립 (의도적 설계) | 시각 race 3건 fix. fire-and-forget 은 주석으로 명시 |
| **P1** | FE-iOS-H2 | iOS UserDefaults | 성립 유지 | 변화 없음. 앱·위젯 동시 401 race |
| **P1** | FE-AND-H2 | OAuth SP | 성립 유지 | 정책-구현 모순 지속. EncryptedSharedPreferences 미적용 |
| **P1** | FE-AND-H3 | Kakao scheme | 부분 성립 유지 | release keystore 분리만, 빈 폴백·`autoVerify` 부재 그대로 |
| **P2** | FE-LIB-H1 | WidgetSync 인스턴스 | 부분 성립 유지 | `home_widget` static API 덕에 무해. 1줄 override 로 해결 |
| **DONE** | FE-LIB-H3 | 가입/온보딩 | **(변경됨) 미성립** ✅ | 온보딩 2단계 신설 + `resolvePostAuthDestination` 4 진입점 적용 |
| **DONE** | BE-T-H1 | 14세 테스트 날짜 | **(변경됨) 미성립** ✅ | `c55493e` fix. `LocalDate.now().minusYears(14)` 로 전환 |

→ **머지 전 차단 (P0)**: 2건 / **다음 스프린트 (P1)**: 9건 / **기술 부채 (P2)**: 1건 / **해소 (DONE)**: 2건

상세는 각 영역 리뷰 문서(`01-be-core-review.md`, `02-be-tests-review.md`, `03-fe-lib-review.md`, `04-fe-ios-review.md`, `05-fe-android-misc-review.md`)의 해당 카드 끝의 "🔄 재검증" 섹션 참조.

### 작업 분배 제안

| 묶음 | 이슈 | 사유 |
|---|---|---|
| **PR-1 (P0)** | FE-LIB-H4 | 운영 데이터 무결성. 단독 PR. catch 분기 1줄로 빠르게 머지 |
| **PR-2 (P0)** | FE-AND-H1 + FE-AND-H3 빌드 가드 | `app_env.dart` 의 `optional → get` / `dart_defines/secrets.json` 도입을 묶으면 충돌 ↓ |
| **PR-3 (P1, BE 보안)** | BE-H1 + BE-H2 + BE-T-H2 | DDL 가드 (yml 1줄) + refresh_tokens UNIQUE + apple-key 삭제 — 인프라 단일 PR |
| **PR-4 (P1, BE 운영)** | BE-H3 | DataInitializer 에 EGG seed 자동 적용 또는 fail-fast |
| **PR-5 (P1, FE 인증)** | FE-LIB-H2 + FE-iOS-H2 + FE-AND-H2 | refresh token 위젯 복제 제거를 3 플랫폼 일괄 — AuthInterceptor 정리 + iOS Keychain Access Group + Android refresh 제거 |
| **PR-6 (P1)** | FE-iOS-H1 | iOS 단독, Swift. `inFlightTodoIds` + 롤백 ~30 LoC |
| **PR-7 (P1, 선택)** | FE-AND-H3 App Links 강화 | Kakao SDK 지원 확인 후 별도 |
| **PR-8 (P2)** | FE-LIB-H1 | 1줄 수정. 다른 작업 사이드로 끼워넣어도 됨 |

### 공통 체크리스트

- [ ] 각 PR 본문에 본 핸드오프 ID(BE-H2, FE-LIB-H4 등) 명시
- [ ] 회귀 테스트 추가 (특히 H4 statusCode 분기, BE-H2 동시 로그인 race, FE-LIB-H2 401 경로)
- [ ] PR-2 머지 전 모든 개발자에게 빌드 명령 변경 (`--dart-define-from-file=dart_defines/secrets.json` 추가) 공지
- [ ] PR-3 의 BE-T-H2: `git rm` 전에 Apple 개발자 포털 Key ID 무관함을 팀 내 확인. 확인 불가 시 즉시 revoke
- [ ] PR-3 머지 후 운영 DB 에 `2026-04-mvp-character-seed.sql` 적용 여부 확인 (BE-H3 와 연관)
- [ ] PR-5 머지 후 다음 시나리오 회귀: 강제 로그아웃 후 위젯 토큰 잔존 X, 앱·위젯 동시 401, 루팅/탈옥 환경 토큰 추출 시도
- [ ] PR-6 머지 후 다마고치 자동 알 발급 동작 회귀 (FE-LIB-H4 와 영역이 다르지만 위젯 sync 와 얽힘)

---

## 부록: 사용한 위임 모델/방식

- **BE 코어 / BE 테스트 / FE lib / FE iOS**: Codex (`gpt-5.5` + `model_reasoning_effort=xhigh`, `--write` 권한 / docs/reviews/ 한정)
- **FE Android + 기타**: Sonnet Agent (background, read-only 사고방식)
- **Codex 4건 동시 제출** — 큐 분산으로 시작 시간 0~37초 차이, 모두 ~4~7분 내 완료
- 통합 시간: 약 8~10분 (제출~완료)
