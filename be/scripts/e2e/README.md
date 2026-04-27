# Doitdo E2E Script

## 목적

Swagger에 노출된 주요 API를 사용자 흐름 순서로 호출하고, 생성 리소스를 역순으로 정리하는 Python3 stdlib-only 전수조사 스크립트입니다.

## 사용법

기본 dev 서버:

```bash
python3 be/scripts/e2e/run.py
```

로컬 서버:

```bash
python3 be/scripts/e2e/run.py --local
```

상세 request/response 출력:

```bash
python3 be/scripts/e2e/run.py -v
```

임의 서버:

```bash
python3 be/scripts/e2e/run.py --base-url http://localhost:8080
```

dev 서버는 self-signed 인증서라 SSL verify 끄는 플래그 필요:

```bash
python3 be/scripts/e2e/run.py --insecure
```

## 요구사항

Python 3.9+와 표준 라이브러리만 사용합니다. 대상 Spring Boot 서버와 DB가 먼저 실행 중이어야 합니다.

## 주의

dev 서버(`https://168.107.48.80`)는 self-signed 인증서이므로 `--insecure` 플래그 없이 실행하면 SSL verify 실패로 전 단계 중단됨.

dev 서버 대상 실행 시 실제 DB에 회원, 기본 카테고리, 설정, 토큰 등 테스트 데이터가 생성됩니다.

## 테스트 계정 격리

스크립트는 `e2e_{ts}` prefix와 `@e2e.local` 도메인으로 매 실행마다 고유 테스트 계정을 생성합니다.

스크립트 마지막 단계에서 `DELETE /api/users/me` (회원탈퇴) 를 실행합니다. 탈퇴 후 DB 상 잔여 row 는 `cleanup.py` 로 정리하세요.

## 테스트 데이터 정리 스크립트

e2e 테스트로 DB 에 남은 계정·연관 데이터를 일괄 삭제.

```bash
python3 be/scripts/e2e/cleanup.py              # dry-run (영향 범위만 보고)
python3 be/scripts/e2e/cleanup.py --yes        # 실제 삭제
python3 be/scripts/e2e/cleanup.py --env-file be/env/.env.dev --yes
```

로컬 Docker 환경 (포트 3307, `be/env/local.env`):

```bash
python3 be/scripts/e2e/cleanup.py --env-file be/env/local.env --port 3307 --yes
```

요구: `mysql` 클라이언트 (`sudo apt install mysql-client`), env 파일에 DB 접속정보.  
env 파일은 `DB_HOST=...` (UPPERCASE) 형식과 `db.host=...` (dotted) 형식 모두 지원합니다.

## Phase 목차

Phase 0: `/db-check` preflight로 서버와 DB 연결 확인.

Phase 1: 회원가입, 이메일/닉네임 중복 및 사용 가능 검증.

Phase 2: 로그인, 내 정보 조회, 비밀번호 변경, 재로그인, 토큰 재발급.

Phase 3: FCM 디바이스 토큰 등록, 설정 조회와 부분 수정.

Phase 4: 카테고리 생성, 목록 검증, 부분 수정.

Phase 5: 도감 조회, **도감 상세 조회** (species/baby/teen/adult 검증), 알 받기, 현재 캐릭터 조회, 이름 변경, 부화.

Phase 6: TODO 생성, 목록/상세/검색/캘린더 조회, 수정, 상태/우선순위 변경, 미루기.

Phase 6b: **스트릭 조회** (첫 TODO DONE 이후 row 생성; currentStreakCount >= 1 검증).

Phase 6c: **exp seed** — 진화에 필요한 exp(BABY→TEEN: 100) 를 TODO 반복 생성·DONE 으로 충전.  
**진화** — exp 충전 후 BABY→TEEN 진화 호출.

Phase 7: 인벤토리 조회, 보유 아이템이 있으면 장착 후 해제.

Phase 8: 알림 목록 조회, 첫 알림 읽음 처리, 전체 읽음 처리.

Phase 9: 알림, TODO, 카테고리, 캐릭터 farewell, 디바이스 토큰, 로그아웃 cleanup.

Phase 10: **회원탈퇴** (`DELETE /api/users/me`, 204 확인). 탈퇴 후 잔여 토큰 차단 검증은 known bug 수정 후 추가 예정 (`docs/plans/e2e-withdraw-token-bug.md` 참조).

## 종료 코드

모든 실패 없는 실행은 `0`, 실패 step이 하나라도 있으면 `1`로 종료합니다. Skip은 실패로 보지 않습니다.
