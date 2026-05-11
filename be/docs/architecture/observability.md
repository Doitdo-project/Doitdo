# 관측성 (Observability)

doitdo 백엔드의 운영 가시성 확보를 위한 로깅/계측 구성.

## 1. 액세스 로그 (AccessLogInterceptor)

**위치**: `com.doitdo.global.log.AccessLogInterceptor`
**등록**: `com.doitdo.global.config.WebMvcConfig` — `/api/**` 경로에 적용

모든 API 요청의 메타데이터를 구조화 로그로 기록한다.

### 로그 포맷

```
event=ACCESS method=GET uri=/api/todos status=200 userId=42 durMs=38
```

| 필드 | 설명 |
|---|---|
| `event=ACCESS` | 구분자 (grep 용) |
| `method` | HTTP 메서드 |
| `uri` | 요청 URI |
| `status` | HTTP 응답 상태 코드 |
| `userId` | SecurityContext 에서 추출한 인증 유저 ID (비인증 요청이면 `null`) |
| `durMs` | 요청 처리 시간 (milliseconds, preHandle ~ afterCompletion) |

### 활성 조건

- 인터셉터는 모든 프로파일에서 활성화됨 (`@Component`).
- 비인증 요청 (로그인 전 `/api/auth/**` 등)은 `userId=null` 로 기록된다.

---

## 2. 트랜잭션 타이밍 AOP (TransactionTimingAspect)

**위치**: `com.doitdo.global.bench.TransactionTimingAspect`
**활성 프로파일**: `dev`, `local` 한정 (`@Profile`)

`@Transactional` 메서드의 실행 시간을 측정한다. Spring 트랜잭션 aspect 보다 바깥에서 감싸므로 tx begin ~ commit/rollback 시간이 모두 포함된다.

### 측정 범위

| 도메인 | 패키지 |
|---|---|
| 인증 | `com.doitdo.domain.auth.application..*` |
| TODO | `com.doitdo.domain.todo.application..*` |
| 다마고치 | `com.doitdo.domain.tamagotchi.application..*` |

### 로그 포맷

```
[tx-bench] method=TodoServiceImpl.createTodo(..) duration=52ms outcome=OK
```

| 필드 | 설명 |
|---|---|
| `method` | 클래스명.메서드명(파라미터 생략) |
| `duration` | 트랜잭션 홀딩 시간 (ms) |
| `outcome` | `OK` / `THROWN` |

---

## 3. SQL 로깅 토글

운영 환경에서는 SQL 로그를 기본 off 로 두고, 디버깅이 필요할 때만 환경변수로 활성화한다.

### 환경변수

| 변수 | 기본값 | 설명 |
|---|---|---|
| `JPA_SHOW_SQL` | `false` | `spring.jpa.show-sql` 토글 |
| `JPA_FORMAT_SQL` | `false` | `spring.jpa.properties.hibernate.format_sql` 토글 |
| `LOG_HIBERNATE_SQL` | `INFO` | `org.hibernate.SQL` 로거 레벨 |
| `LOG_HIBERNATE_BIND` | `WARN` | `org.hibernate.orm.jdbc.bind` 로거 레벨 (바인딩 파라미터) |

### SQL 로그 전체 활성화 방법

`env/.env.dev` (또는 배포 환경변수)에 아래를 추가:

```properties
JPA_SHOW_SQL=true
JPA_FORMAT_SQL=true
LOG_HIBERNATE_SQL=DEBUG
LOG_HIBERNATE_BIND=TRACE
```

### 주의

- `application-prod.yml` 과 `application-test.yml` 은 `show-sql: false`, `format_sql: false` 를 명시적으로 선언해 ENV 변수 실수를 이중으로 방지한다.
- `application-dev.yml` / `application-local.yml` 은 ENV 변수에 위임한다 (명시 값 없음).
