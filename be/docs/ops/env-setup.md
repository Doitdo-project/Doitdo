# 환경 셋업 (env-setup)

로컬 개발 환경 준비. 한 번만 하면 된다.

## 1. JDK 21

시스템에 OpenJDK 21이 있어야 한다. 위치 예시:

```bash
/usr/lib/jvm/java-21-openjdk-amd64
```

`JAVA_HOME` 을 셸 rc(`.bashrc`/`.zshrc`)에 영구 등록하거나, 실행 시 inline 으로 지정해도 된다 ([run-local.md](run-local.md) 참고).

## 2. env 파일

DB 접속정보는 git에 올리지 않는다. 템플릿을 복사해 채워 사용한다.

```bash
cp be/env/dev.env.example be/env/dev.env
# 편집기로 열어서 DB 호스트/유저/비밀번호 입력
```

| 파일 | 용도 | git 추적 |
|---|---|---|
| `env/dev.env.example` | 템플릿 (키만, 값 비움) | O |
| `env/dev.env` | 로컬 dev 프로파일 실제 값 | X (gitignore) |
| `env/prod.env.example` | 운영용 템플릿 | O |

로딩 위치: `src/main/resources/application-dev.yml` 의 `spring.config.import` 가 `env/dev.env` 를 읽는다.

## 2-1. 선택 env 키

| 키 | 기본값 | 허용값 | 용도 |
|---|---|---|---|
| `jpa.ddl.auto` | `update` | `validate` / `update` / `create` / `create-drop` / `none` | Hibernate 스키마 전략. 공용 dev DB 에 영향 가므로 개인 환경에선 `validate` 권장. `env/dev.env` 에 지정. |

## 2-2. Firebase (FCM push) 설정

알림 송신(저녁 리마인더, TODO 잠금해제 등)은 Firebase Admin SDK 로 FCM 을 호출한다. `firebase.enabled=false` 면 `NoopFcmService` 가 주입되어 로그만 찍고 실제 발송은 스킵된다.

### 서비스 계정 키 배치

`be/secrets/firebase-service-account-dev.json` 에 Firebase Console 에서 발급한 서비스 계정 JSON 을 놓는다. `be/secrets/` 는 gitignore 에 등록되어 있다.

```bash
mkdir -p be/secrets
# Firebase Console > 프로젝트 설정 > 서비스 계정 > 새 비공개 키 생성
# 다운받은 JSON 을 be/secrets/firebase-service-account-dev.json 로 저장
chmod 600 be/secrets/firebase-service-account-dev.json
```

### env 설정

로컬 (`be/env/dev.env`, kebab-case dot 포맷):

```properties
firebase.enabled=true
firebase.service-account-path=/absolute/path/to/be/secrets/firebase-service-account-dev.json
firebase.project-id=doitdo-c3fcd
```

운영/테스트 서버의 Docker env_file (`/home/ubuntu/app/env/dev.env`, env var 포맷 — relaxed binding 으로 동일 key 에 매핑됨):

```properties
FIREBASE_ENABLED=true
FIREBASE_SERVICE_ACCOUNT_PATH=/app/secrets/firebase-service-account.json
FIREBASE_PROJECT_ID=doitdo-c3fcd
```

Docker 배포 시에는 서비스 계정 JSON 을 호스트 `/home/ubuntu/app/secrets/` 에 두고 `docker-compose.yml` volume 으로 `/app/secrets` 에 읽기 전용 마운트한다.

### 검증

부팅 로그에 아래가 보이면 Firebase 모드 활성:

```
c.d.d.n.a.impl.FirebaseFcmService  : [fcm] FirebaseFcmService is active.
```

비활성(Noop) 상태라면 `NoopFcmService` 초기화 로그가 대신 나온다.

## 2-3. Apple Sign-In 설정

Apple 로그인은 `authorizationCode` 교환과 회원탈퇴 revoke 호출을 위해 Apple `.p8` 개인키가 필요하다.
`AppleClientSecretGenerator`는 부팅 시 설정과 키 파일 존재 여부를 검사하므로, 서버와 Jenkins 테스트 환경에 모두 맞춰 둔다.

### 서버 secret 배치

dev 서버:

```bash
/workspace/extra/app/secrets/apple-signin-key.p8
chmod 600 /workspace/extra/app/secrets/apple-signin-key.p8
```

prod 서버:

```bash
/home/ubuntu/app/secrets/apple-signin-key.p8
chmod 600 /home/ubuntu/app/secrets/apple-signin-key.p8
```

두 서버 모두 컨테이너 내부에서는 `/app/secrets/apple-signin-key.p8`로 보인다.

### Docker env_file 설정

Docker `env_file`에서는 대문자 env var 포맷을 사용한다.

```properties
APPLE_OAUTH_CLIENT_ID=com.d107.doitdo
APPLE_SIGNIN_TEAM_ID=...
APPLE_SIGNIN_KEY_ID=...
APPLE_SIGNIN_KEY_PATH=/app/secrets/apple-signin-key.p8
APPLE_SIGNIN_CLIENT_ID=com.d107.doitdo
```

Spring Boot relaxed binding으로 `APPLE_SIGNIN_KEY_PATH`는 `apple.signin.key-path`에 매핑된다.

### Jenkins 테스트 설정

Jenkins에서 Spring context 테스트를 돌리는 job은 `.p8` secret file도 주입해야 한다.

```text
Credentials ID: apple-signin-key-p8
Kind: Secret file
```

Pipeline에서는 `be/secrets/apple-signin-key.p8`로 복사하고,
Jenkins용 `prod-env-file`에는 아래처럼 둔다.

```properties
APPLE_SIGNIN_KEY_PATH=./secrets/apple-signin-key.p8
```

### 검증

```bash
docker exec doitdo-app printenv | grep APPLE
docker exec doitdo-app test -r /app/secrets/apple-signin-key.p8
curl http://localhost:8080/actuator/health
```

## 3. DB 접근 확인

dev 프로파일은 원격 테스트 DB(`168.107.48.80`)에 붙는다. VPN/방화벽 정책으로 접근이 막혀 있으면 부팅 실패하니 사전에 확인할 것.

## 4. (선택) IDE 코드 스타일

IntelliJ 에서 프로젝트 제공 `code-style.xml` 을 import 한다. 자세한 네이밍/포맷 규칙은 [`../conventions/naming.md`](../conventions/naming.md).
