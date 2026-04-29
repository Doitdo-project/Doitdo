# Codex Review — BE 코어 (Spring Boot)

## 컨텍스트
- 프로젝트: doitdo (Spring Boot BE + Flutter FE, todo + 다마고치)
- 현재 브랜치: be/feat/user-birthdate-age-check
- 누적 변경: dev 가 main 대비 543 files / 47,880 줄 변경 (dev → main 통합 직전 종합 리뷰)
- 이 작업: **BE 메인 코드 (테스트 제외) 의 모든 누적 변경에 대한 risk surface 발굴**

## 스코프
- 검토 대상: `be/src/main/**` 의 main 대비 모든 변경 파일
- 진단 명령 예시:
  - `git diff main...HEAD --stat -- 'be/src/main/'`
  - `git diff main...HEAD -- 'be/src/main/<path>'`
- **제외**: `be/src/test/**`, build artifacts, `.gitkeep`

## 임무
다음 6축 위험을 발굴하라.

1. **보안**: 인증/인가/JWT/refresh token/Apple OAuth/입력 검증/SQL injection/secret 노출/권한 우회/CSRF/CORS/onboarding filter bypass
2. **회귀**: 기존 동작 깨질 가능성/엔티티 스키마 변경의 마이그레이션 안정성/API 응답 호환성/이벤트 리스너 순서 변경
3. **성능**: N+1/JPA fetch 전략/불필요한 round-trip/캐시 누락/heavy IO/페이지네이션 누락/transaction 범위 비대화
4. **동시성**: race condition/스레드 안전성/트랜잭션 경계/락/이벤트 비동기 처리/scheduler 중복 실행/FCM 발송 중복
5. **리소스**: 메모리 누수/connection 누적/cleanup 누락/limit 없음/log flooding 위험
6. **에러 처리**: catch swallow/잘못된 fallback/ErrorCode 일관성/예외 변환 누락/transaction rollback 조건/global exception handler

## 출력
- 결과를 **`docs/reviews/01-be-core-review.md`** 한 파일에만 작성
- 형식:
  ```markdown
  # BE 코어 리뷰 결과

  ## 검토 요약
  - 검토 파일 수: N
  - HIGH: x건 / MEDIUM: y건 / LOW: z건
  - 6축 커버리지: 보안 ✓ / 회귀 ✓ / 성능 ✓ / 동시성 ✓ / 리소스 ✓ / 에러 처리 ✓

  ## HIGH (반드시 머지 전 수정)
  ### [HIGH-1] 제목
  - 파일: be/src/main/.../File.java:123
  - 문제: 한 줄 설명
  - 영향: 어떤 시나리오에서 어떻게 깨지는지
  - 권장: 어떻게 고칠지 (코드 수정 금지 — 권장만)
  - 근거: git diff hunk 발췌 (5~15줄)

  ## MEDIUM
  ...

  ## LOW
  ...

  ## 검토한 주요 파일 (Top 30, 변경량 순)
  - path/to/File.java (+120/-30)
  - ...
  ```
- HIGH 이슈가 없으면 "HIGH 없음" 명시
- 자동생성/getter/.gitkeep 등은 무시. 비즈니스 로직 위주 검토

## 제약
- **read-only 사고방식**: 다른 파일은 수정하지 말 것. 결과는 오직 `docs/reviews/01-be-core-review.md` 한 곳에만
- **스코프 엄수**: BE 테스트, FE, AI 디렉토리 검토 금지
- **빌드/테스트 실행 금지**: 정적 분석만
- **단정 금지**: 불확실하면 "확인 필요"로 표기, 거짓 양성 줄일 것
- **CDP MCP(Chrome DevTools Protocol MCP) 절대 사용 금지**: 브라우저 자동화/DOM 접근/스크린샷 등 CDP 관련 도구 일체 금지
