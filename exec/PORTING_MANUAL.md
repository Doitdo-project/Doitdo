# 포팅 매뉴얼

> GitLab 소스 클론 이후 Doitdo 서비스를 빌드 및 배포할 수 있도록 정리한 문서입니다.

---

## 1. 프로젝트 개요

| 항목 | 내용 |
|------|------|
| 프로젝트명 | Doitdo |
| 설명 | 다마고치를 키우는 TODO 앱 |
| GitLab | https://lab.ssafy.com/s14-final/S14P31D107.git |
| 주요 구성 | Backend(Spring Boot), Frontend(Flutter), AI, Monitoring |
| 운영 API 도메인 | https://api.doitdo.site |
| 운영 CORS 허용 | https://doitdo.site, https://*.doitdo.site |

---

## 2. 개발 환경 및 사용 기술 버전

### 2.1 Backend

| 항목 | 종류/버전 |
|------|-----------|
| Language | Java 21 |
| JDK | Eclipse Temurin 21 |
| Framework | Spring Boot 3.5.13 |
| Build Tool | Gradle Wrapper |
| ORM | Spring Data JPA + Hibernate |
| DB | MariaDB 11 |
| Cache | Redis 7 |
| 인증 | JWT (`jjwt` 0.12.6), Spring Security |
| API 문서 | SpringDoc OpenAPI 2.7.0 |
| Push | Firebase Admin SDK 9.2.0 |
| Monitoring | Spring Actuator, Micrometer Prometheus |
| IDE 권장 | IntelliJ IDEA |

### 2.2 Frontend

| 항목 | 종류/버전 |
|------|-----------|
| Framework | Flutter |
| Dart SDK | ^3.10.8 |
| App Version | 1.2.0+4 |
| Architecture | Clean Architecture + MVVM |
| 상태 관리 | flutter_riverpod 2.6.1 |
| 라우팅 | go_router 14.8.1 |
| 네트워킹 | dio 5.7.0, retrofit 4.9.0 |
| 로컬 저장 | Hive, SharedPreferences, Flutter Secure Storage |
| Push | firebase_core 4.1.1, firebase_messaging 16.0.1 |
| OAuth | Google Sign-In, Kakao Login, Apple Sign In |
| IDE 권장 | Android Studio 또는 VS Code |

### 2.3 AI

| 항목 | 내용 |
|------|------|
| 위치 | `S14P31D107/ai` |
| 비고 | 현재 저장소에는 AI 디렉터리 골격만 포함되어 있으며, 별도 실행 산출물은 배포 대상에서 제외 |

### 2.4 Infra

| 항목 | 종류/버전 |
|------|-----------|
| CI/CD | Jenkins |
| Container | Docker, Docker Compose |
| Web Server | Nginx |
| 배포 서버 | OCI VM |
| 운영 서버 IP | 140.245.72.85 |
| 운영 배포 경로 | `/home/ubuntu/app` |
| Timezone | Asia/Seoul |

---

## 3. 빌드 시 환경 변수

### 3.1 Backend 운영 환경 파일

운영 서버와 Jenkins Credential에 `prod.env`를 준비합니다. 실제 시크릿 값은 문서에 기록하지 않습니다.

```properties
spring.profiles.active=prod
db.host=mariadb
db.port=3306
db.name=doitdo_prod
db.username=<DB 사용자명>
db.password=<DB 비밀번호>

JPA_DDL_AUTO=validate
JWT_SECRET=<운영 JWT 시크릿>

FIREBASE_ENABLED=true
FIREBASE_SERVICE_ACCOUNT_PATH=/app/secrets/firebase-service-account.json
FIREBASE_PROJECT_ID=doitdo-c3fcd

GOOGLE_OAUTH_CLIENT_ID=<Google Web Client ID>
APPLE_OAUTH_CLIENT_ID=com.d107.doitdo

APPLE_SIGNIN_TEAM_ID=<Apple Team ID>
APPLE_SIGNIN_KEY_ID=<Apple Key ID>
APPLE_SIGNIN_KEY_PATH=/app/secrets/apple-signin-key.p8
APPLE_SIGNIN_CLIENT_ID=com.d107.doitdo

REDIS_HOST=redis
REDIS_PORT=6379
SPRING_DATA_REDIS_HOST=redis
SPRING_DATA_REDIS_PORT=6379

MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=<Gmail 계정>
MAIL_PASSWORD=<Gmail 앱 비밀번호>
MAIL_FROM_ADDRESS=<발신 메일 주소>
MAIL_FROM_NAME=doitdo
```

### 3.2 Frontend 환경 변수

`S14P31D107/fe/doitdo/.env` 파일을 생성합니다.

```properties
API_BASE_URL=https://api.doitdo.site
GOOGLE_SERVER_CLIENT_ID=<Google Web Client ID>
KAKAO_NATIVE_APP_KEY=<Kakao Native App Key>
```

운영 빌드용 dart define 파일:

```json
{
  "FLAVOR": "prod",
  "API_BASE_URL": "https://api.doitdo.site"
}
```

### 3.3 주요 Credential

| 위치 | 항목 |
|------|------|
| Jenkins Credential `prod-env-file` | 운영 `prod.env` 파일 |
| Jenkins Credential `apple-signin-key.p8` | Apple Sign In private key |
| Jenkins Credential `oci-ssh` | 운영 서버 SSH private key |
| 서버 `/home/ubuntu/app/secrets` | `firebase-service-account.json`, `apple-signin-key.p8` |

---

## 4. 빌드 방법

### 4.1 Backend 로컬 빌드

```bash
cd S14P31D107/be
chmod +x gradlew
./gradlew clean test
./gradlew bootJar
```

빌드 결과:

```text
S14P31D107/be/build/libs/*.jar
```

### 4.2 Frontend 로컬 실행

```bash
cd S14P31D107/fe/doitdo
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### 4.3 Frontend 운영 빌드 예시

```bash
cd S14P31D107/fe/doitdo
flutter pub get
flutter build apk --release --dart-define-from-file=dart_defines/prod.json
```

### 4.4 Docker 이미지 빌드

운영 서버 배포 기준으로 JAR 파일명을 `app.jar`로 맞춘 뒤 Docker 이미지를 생성합니다.

```bash
cp S14P31D107/be/build/libs/*.jar automation/app.jar
cd automation
docker compose -f docker-compose.prod.yml up -d --build
```

---

## 5. 배포 방법

### 5.1 Jenkins 자동 배포

운영 배포는 `S14P31D107/.jenkins/Jenkinsfile.prod-release` 기준입니다.

1. GitLab 소스 Checkout
2. Jenkins Credential에서 `prod.env`, Apple `.p8` 키 주입
3. `be` 디렉터리에서 `./gradlew bootJar`
4. 운영 서버 `/home/ubuntu/app`으로 `app.jar`, `env/prod.env`, `secrets/apple-signin-key.p8` 전송
5. 운영 서버에서 `sudo ./deploy-bluegreen.sh` 실행
6. `/hello` 및 `https://api.doitdo.site/hello` 헬스체크
7. 비활성 컨테이너 종료

### 5.2 수동 배포

운영 서버 구조:

```text
/home/ubuntu/app
├── app.jar
├── Dockerfile
├── docker-compose.prod.yml
├── deploy-bluegreen.sh
├── env
│   └── prod.env
├── nginx
│   └── prod.conf
└── secrets
    ├── firebase-service-account.json
    └── apple-signin-key.p8
```

수동 실행:

```bash
cd /home/ubuntu/app
sudo docker compose -f docker-compose.prod.yml up -d --build
sudo docker compose -f docker-compose.prod.yml ps
curl -fsS http://127.0.0.1:8080/hello
```

### 5.3 배포 시 특이사항

- 운영 환경은 `application-prod.yml`에서 `./env/prod.env`를 필수로 import합니다.
- `prod.env`가 없으면 운영 서버는 부팅 실패하도록 구성되어 있습니다.
- 운영 DB 스키마 변경은 `JPA_DDL_AUTO=validate`를 권장합니다.
- Blue/Green 배포 시 활성 포트는 8080 또는 8082이며, Nginx가 활성 포트로 프록시합니다.
- `FIREBASE_SERVICE_ACCOUNT_PATH`, `APPLE_SIGNIN_KEY_PATH`는 컨테이너 내부 경로 기준입니다.
- Redis는 캐시/인증 사용자 캐시/알림 관련 기능에 사용됩니다.

---

## 6. 운영 서비스 구성

| 서비스 | 이미지/런타임 | 포트 | 설명 |
|--------|---------------|------|------|
| app | Eclipse Temurin 21 + Spring Boot JAR | 8080 내부 | Backend API |
| mariadb | mariadb:11 | 3306 내부 | 운영 DB |
| redis | redis:7-alpine | 6379 내부 | 캐시 |
| nginx | nginx:1.27-alpine 또는 호스트 Nginx | 80/443 | API 프록시 |

---

## 7. 주요 프로퍼티/설정 파일 목록

| 파일 경로 | 설명 |
|-----------|------|
| `S14P31D107/be/build.gradle` | Backend 의존성 및 Java 21 설정 |
| `S14P31D107/be/settings.gradle` | Gradle 프로젝트명 |
| `S14P31D107/be/src/main/resources/application.yml` | Backend 공통 설정 |
| `S14P31D107/be/src/main/resources/application-prod.yml` | 운영 DB, Actuator, CORS 설정 |
| `S14P31D107/be/env/.env.prod.example` | 운영 환경 변수 예시 |
| `S14P31D107/.jenkins/Jenkinsfile.main-build-check` | main 빌드/테스트 검증 |
| `S14P31D107/.jenkins/Jenkinsfile.prod-release` | 운영 배포 파이프라인 |
| `S14P31D107/fe/doitdo/pubspec.yaml` | Flutter 의존성 및 asset/font 설정 |
| `S14P31D107/fe/doitdo/.env.example` | 앱 클라이언트 환경 변수 예시 |
| `S14P31D107/fe/doitdo/dart_defines/prod.json` | 운영 앱 빌드 설정 |
| `automation/Dockerfile` | Backend JAR 컨테이너 이미지 |
| `automation/docker-compose.prod.yml` | 운영 Docker Compose 예시 |
| `automation/nginx/prod.conf` | Nginx reverse proxy 설정 |
| `monitoring/docker-compose.yml` | Prometheus/Grafana/Loki/Alloy 모니터링 구성 |

