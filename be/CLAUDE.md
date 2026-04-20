# doitdo (BE) — Claude Onboarding

이 문서는 Claude(또는 새 합류자)가 백엔드 작업 전 가장 먼저 읽는 진입점이다.
세부 규칙은 노션이 단일 진실 출처(SSOT)이며, 여기서는 위치와 핵심 요약만 담는다.

---

## 1. 프로젝트 한눈에

- 서비스: **doitdo** (TODO + 다마고치)
- 스택: Spring Boot 3.5.x · Java 21 · Gradle · MariaDB · JPA
- 패키지 루트: `com.doitdo`
- 진입점: `com.doitdo.DoitdoApplication`
- 활성 프로파일: `dev` (원격 테스트 DB 168.107.48.80)

### 1.1 빠른 실행

```bash
# JDK 21이 시스템에 있어야 함
JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 \
  PATH=$JAVA_HOME/bin:$PATH \
  ./gradlew bootRun --args='--spring.profiles.active=dev'

# 헬스체크
curl http://localhost:8080/hello
curl http://localhost:8080/db-check
```

### 1.2 환경 파일

- `env/dev.env` — DB 접속정보 (gitignore, 로컬에 직접 복사)
- `env/dev.env.example` — 템플릿
- 로딩 위치: `src/main/resources/application-dev.properties` 의 `spring.config.import`

---

## 2. 팀 규칙 (노션 SSOT)

작업 전 반드시 확인. 변경된 컨벤션은 항상 노션이 우선이다.

| 영역 | 노션 페이지 | 핵심 요약 |
|---|---|---|
| 팀 규칙 (허브) | https://www.notion.so/e158ab5fe9a983ab9e2d014ea5209a51 | Git / JIRA / BE / FE 컨벤션 모음 |
| **Git Convention** | https://www.notion.so/3448ab5fe9a98068bf77d1f7a8164045 | §3 참조 |
| **JIRA Convention** | https://www.notion.so/3448ab5fe9a980ff9da9ff5bc5094ec4 | §4 참조 |
| **BE Convention (패키지/네이밍)** | https://www.notion.so/3458ab5fe9a980b7a026f4652db8b2c8 | §5 참조 |
| API 기본 명세서 | https://www.notion.so/3428ab5fe9a980c790a6f9161a900f22 | 도메인별 엔드포인트 + 카테고리 |

---

## 3. Git Convention (요약)

### 3.1 브랜치 전략

- `main` (운영) ← `dev` (개발 통합) ← feature 브랜치
- **`dev` 브랜치 직접 push 금지** — 모든 작업은 feature 브랜치에서 진행 후 MR로 병합
- 코드 리뷰 후 머지

### 3.2 브랜치 네이밍

```
be/feat/{기능명}     # 예: be/feat/auth-login
be/fix/{이슈명}      # 예: be/fix/jwt-refresh-error
fe/feat/{기능명}
fe/fix/{이슈명}
hotfix/{내용}
docs/{내용}          # 예: docs/api-spec
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
| style | 포맷팅/세미콜론 등 |
| comment | 주석 |
| chore | 빌드/설정/잡일 |

예시:
```
feat : auth/login 로그인 API 구현
fix : auth/jwt 토큰 만료 처리 오류 수정
add : common/exception 전역 예외 처리 클래스 추가
docs : API 명세서 업데이트
```

### 3.4 Merge Request

- 제목 형식: `[BE : feat] 작업 내용` (한글 권장, 기술 용어는 영어 가능)
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
| Sub-Task | API 단위 (또는 커밋 단위) |

### 4.2 작업 제목

서두에 파트 prefix: `[BE]`, `[FE]`, `[DOCS]`, `[INFRA]`, `[AI]`, `[DB]`

### 4.3 도메인 구분 기준

**트리거 기준**으로 판정.
> 예: 다마고치 성장은 TODO 완료가 트리거 → `[BE] TODO ...`

### 4.4 도메인 담당

- 인증 / 유저 — 황예찬
- 다마고치 — 전상훈
- TODO — 김재환

### 4.5 스토리 포인트 (피보나치: 1, 2, 3, 5, 8 위주)

- 1 매우 단순 / 2 단순 / 3 명확 / 5 표준 / 8 고난도 / 9 대규모 / 10 매우 위험

---

## 5. BE Convention (요약)

상세는 노션 BE 페이지. 핵심:

### 5.1 베이스 패키지

```
com.doitdo
 ├ DoitdoApplication.java
 ├ domain/{도메인}/...
 └ global/...
```

### 5.2 도메인 패키지 (Layered + DDD)

```
domain/{domain}/
 ├ api/
 │   ├ controller/
 │   └ dto/{req, resp}/
 ├ application/
 │   ├ {Domain}Service          # interface
 │   └ impl/{Domain}ServiceImpl
 ├ entity/
 └ repository/
```

### 5.3 등록된 도메인

`auth, user, todo, tamagotchi, inventory, shop, notification, setting`
(노션 「엔드포인트」 카테고리 직역. 검색 기능은 todo 도메인 내부에서 처리.)

### 5.4 global 패키지

```
global/
 ├ config/        # SecurityConfig, JpaAuditingConfig 등
 ├ entity/        # BaseTimeEntity (공통 Auditing)
 ├ exception/     # GlobalExceptionHandler, BusinessException, ErrorCode
 ├ api/response/  # ApiResponse<T>
 ├ util/          # JwtUtil 등
 └ health/        # HealthController
```

### 5.5 네이밍 규칙

| 컴포넌트 | 규칙 |
|---|---|
| Controller | `{Domain}Controller` |
| Service | `{Domain}Service` (interface) + `{Domain}ServiceImpl` |
| Repository | `{Domain}Repository` |
| Entity | `{Domain}` (테이블명 단수형) |
| Request DTO | `{Action}{Domain}Req` |
| Response DTO | `{Domain}Resp` |

### 5.6 엔티티 규칙

- `@Getter`, `@NoArgsConstructor(access = PROTECTED)`, `@Builder`, `@AllArgsConstructor(access = PRIVATE)` (Lombok)
- 생성/수정 시각이 둘 다 있는 엔티티는 `BaseTimeEntity` 상속 (`global/entity/BaseTimeEntity.java`)
- `@EnableJpaAuditing`은 `global/config/JpaAuditingConfig` 에서 활성화
- FK는 도메인 격리 위해 **Long ID 필드**로 보관 (`@ManyToOne` 미사용 원칙)

### 5.7 코드 포맷

- IntelliJ Code Style (프로젝트 제공 `code-style.xml` import)
- 단축키: `Ctrl+Alt+L` (포맷), `Ctrl+Alt+O` (import 정리)
- 저장 시 자동 포맷 권장 (`Settings → Tools → Actions on Save`)

---

## 6. ERD / 스키마

- 원본: `docs/imgs/erd.png`
- 테이블별 분할: `docs/imgs/tables/{테이블명}.png` (17장)
- DDL 자동 생성: `application.properties` 의 `spring.jpa.hibernate.ddl-auto=update` (개발용; 운영은 `validate` 또는 마이그레이션 도구 사용 결정 필요)

### 6.1 도메인 ↔ 테이블 매핑

| 도메인 | 테이블 |
|---|---|
| auth | refresh_tokens, auto_providers |
| user | users, user_wallets |
| todo | todos, categories, palettes, palette_colors |
| tamagotchi | characters, character_actions, character_unlocks, user_character |
| inventory | items, user_items |
| shop | purchase_logs |
| notification | device_tokens |
| setting | user_settings |

---

## 7. Claude를 위한 보조 메모

- 작업 시작 전 **§2 표의 노션 링크를 먼저 확인**해 최신 컨벤션과 일치하는지 점검.
- 네이밍·패키지 위치는 §5 / 커밋·브랜치는 §3 / 티켓은 §4 강제.
- 노션이 변경되면 이 문서 §3~§5 요약도 갱신.
- 새 도메인을 추가할 때:
  1. 노션 「엔드포인트」 DB의 카테고리에 신규 추가가 합의됐는지 확인
  2. `domain/{새도메인}/` 골격 5종 디렉토리 생성 (`api/{controller,dto/{req,resp}}, application/impl, entity, repository`)
  3. §6.1 매핑 표 업데이트
