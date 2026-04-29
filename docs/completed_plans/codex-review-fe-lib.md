# Codex Review — FE Flutter lib

## 컨텍스트
- 프로젝트: doitdo Flutter FE (Riverpod + Clean Architecture)
- 현재 브랜치: be/feat/user-birthdate-age-check
- 이 작업: **`fe/doitdo/lib/**` 의 누적 변경에 대한 risk surface 발굴**

## 스코프
- 검토 대상: `fe/doitdo/lib/**` 의 main 대비 모든 변경 파일
- 진단 명령:
  - `git diff main...HEAD --stat -- 'fe/doitdo/lib/'`
  - `git diff main...HEAD -- 'fe/doitdo/lib/<path>'`
- **제외**: `*.freezed.dart`, `*.g.dart` (자동생성), `.gitkeep`

## 임무
다음 6축 위험을 발굴하라.

1. **상태관리/Riverpod**: ref.listen 패턴 오용, provider 의존성 순환, dispose 누락, AutoDispose 누락으로 메모리 누수, ref.watch 가 build 외부에서 호출, scope 어긋남
2. **비동기/에러**: Future 누수, `unawaited` 누락, dio error 매핑 빈틈, 재시도 정책 누락, race condition (특히 위젯 sync, FCM 토큰 등록 — 최근 fix 한 영역)
3. **보안/입력 검증**: form 검증 우회, secret 노출, 로컬 토큰 저장 안전성, deep link 처리, 만 14세 차단 로직 우회 가능성
4. **UI 회귀**: navigator stack 오염, modal sheet leak, 리스트 무한 스크롤 cleanup, 다크/라이트 누락, snap scroll physics edge
5. **데이터/네트워킹**: API 응답 매핑 mismatch, freezed nullable 처리, base_repository 에서 에러 swallow, 캐싱 무효화 누락
6. **성능**: 불필요 rebuild, listView builder 누락, image cache 누수, build 메서드 내 heavy 연산

## 출력
- 결과를 **`docs/reviews/03-fe-lib-review.md`** 한 파일에만 작성
- 형식: 01 리뷰와 동일 (HIGH/MEDIUM/LOW + 파일:줄 + 권장 + 근거 hunk 발췌)
- 자동 생성 파일 (`*.freezed.dart`, `*.g.dart`) 은 검토 대상에서 제외

## 제약
- **read-only 사고방식**: 결과 외 어떤 파일도 수정 금지. 결과는 오직 `docs/reviews/03-fe-lib-review.md` 한 곳에만
- **스코프 엄수**: BE, iOS native, Android native, web 검토 금지
- **빌드/테스트 실행 금지**: 정적 분석만
- **단정 금지**: 불확실하면 "확인 필요"
- **CDP MCP(Chrome DevTools Protocol MCP) 절대 사용 금지**: 브라우저 자동화/DOM 접근/스크린샷 등 일체 금지
