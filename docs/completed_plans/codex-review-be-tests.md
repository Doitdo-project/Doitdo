# Codex Review — BE 테스트

## 컨텍스트
- 프로젝트: doitdo (Spring Boot BE)
- 현재 브랜치: be/feat/user-birthdate-age-check
- 이 작업: **BE 테스트 코드 (be/src/test/**) 의 누적 변경에 대한 품질·신뢰성 검토**

## 스코프
- 검토 대상: `be/src/test/**` 의 main 대비 모든 변경 파일
- 진단 명령 예시:
  - `git diff main...HEAD --stat -- 'be/src/test/'`
  - `git diff main...HEAD -- 'be/src/test/<path>'`
- **제외**: BE main 코드 (별도 리뷰 진행 중), 자동생성

## 임무
다음 5축 위험을 발굴하라.

1. **테스트 신뢰성**: flaky 패턴 (시간 의존, 외부 시스템 의존, 순서 의존, 랜덤성), assertion 누락, given-when-then 명확성
2. **커버리지 사각지대**: happy path 만 있고 edge/실패 경로 누락, exception path 미검증, 음수/null/빈 문자열 미커버
3. **mocking 위생**: 과도한 mock (실제 통합으로 잡혀야 할 게 mock 으로 가려짐), strict mock 누락으로 실제 호출 안 검증, fixture 중복
4. **리소스/격리**: `@Transactional` 누락 → DB 오염, `@DirtiesContext` 남용으로 속도 저하, application context 중복 로드, 임시 파일/스레드 cleanup 누락
5. **회귀 안전망 적합성**: 새 기능에 대한 테스트가 진짜 의도를 보호하는가? 구현 디테일에만 묶여 리팩토링 시 깨질 패턴인가? assertion 이 약해서(예: not-null 만) 회귀를 못 잡는 케이스

## 출력
- 결과를 **`docs/reviews/02-be-tests-review.md`** 한 파일에만 작성
- 형식: 01 리뷰와 동일 (HIGH/MEDIUM/LOW + 파일:줄 + 권장 + 근거 hunk 발췌)

## 제약
- **read-only 사고방식**: 결과 외 어떤 파일도 수정 금지. 결과는 오직 `docs/reviews/02-be-tests-review.md` 한 곳에만
- **스코프 엄수**: BE main, FE, AI 검토 금지. 단, `be/src/test/resources/apple-test-key.p8` 같은 secret 노출 위험은 보안 이슈로 보고
- **빌드/테스트 실행 금지**: 정적 분석만
- **단정 금지**: 불확실하면 "확인 필요"
- **CDP MCP(Chrome DevTools Protocol MCP) 절대 사용 금지**
