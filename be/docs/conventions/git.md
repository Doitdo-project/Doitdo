# Git Convention

노션 SSOT: <https://www.notion.so/3448ab5fe9a98068bf77d1f7a8164045>

## 1. 브랜치 전략

- `main` (운영) ← `dev` (개발 통합) ← feature 브랜치
- **`dev` 브랜치 직접 push 금지.** 모든 작업은 feature 브랜치에서 진행 후 MR로 병합.
- 코드 리뷰 후 머지.

## 2. 브랜치 네이밍

```
be/feat/{기능명}     # 예: be/feat/auth-login
be/fix/{이슈명}      # 예: be/fix/jwt-refresh-error
fe/feat/{기능명}
fe/fix/{이슈명}
hotfix/{내용}
docs/{내용}          # 예: docs/api-spec
```

## 3. 커밋 메시지

형식: `type : (위치/기능) + 설명`

| type | 용도 |
|---|---|
| `feat` | 새 기능 |
| `fix` | 버그 수정 |
| `add` | 클래스/파일 추가 (기능 외) |
| `refactor` | 리팩토링 |
| `docs` | 문서 |
| `style` | 포맷팅 / 세미콜론 등 |
| `comment` | 주석 |
| `chore` | 빌드 / 설정 / 잡일 |

예시:

```
feat : auth/login 로그인 API 구현
fix  : auth/jwt 토큰 만료 처리 오류 수정
add  : common/exception 전역 예외 처리 클래스 추가
docs : API 명세서 업데이트
```

## 4. Merge Request

- 제목 형식: `[BE : feat] 작업 내용` (한글 권장, 기술 용어는 영어 가능)
- 템플릿 필수 사용 (Part / 변경사항 / 상세 / 체크리스트)
- 대상 브랜치: feature → **dev**

## 5. 자주 빠뜨리는 항목

- 브랜치 prefix (`be/feat/...`) 누락 → 자동 분류 안 됨.
- 커밋 type 과 설명 사이 콜론 한 칸씩 (` : `) 누락 → 컨벤션 위반.
- 작업 단위가 너무 크면 commit 분할.
