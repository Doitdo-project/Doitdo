# 외부 서비스 정보

> 프로젝트에서 사용하는 외부 서비스 가입 및 활용에 필요한 정보를 정리한 문서입니다.

---

## 1. GitLab SSAFY

| 항목 | 내용 |
|------|------|
| 용도 | 소스코드 관리, Merge Request, Jenkins Webhook |
| URL | https://lab.ssafy.com/s14-final/S14P31D107.git |
| 필요 정보 | GitLab 계정, 저장소 접근 권한, Jenkins용 HTTP Token |
| 설정 위치 | Jenkins Credential `gitlab-http-token`, Jenkins GitLab Connection `ssafy-gitlab` |

---

## 2. Jenkins

| 항목 | 내용 |
|------|------|
| 용도 | Backend 빌드 검증 및 운영 배포 자동화 |
| 주요 Job | `doitdo-main-build-check`, `doitdo-prod-release` |
| 필요 Credential | `gitlab-http-token`, `prod-env-file`, `apple-signin-key.p8`, `oci-ssh` |
| 주요 파일 | `S14P31D107/.jenkins/Jenkinsfile.main-build-check`, `S14P31D107/.jenkins/Jenkinsfile.prod-release` |
| 비고 | main push 성공 시 운영 배포 Job을 비동기로 실행 |

---

## 3. OCI VM

| 항목 | 내용 |
|------|------|
| 용도 | 운영 서버 |
| 운영 서버 IP | 140.245.72.85 |
| SSH 사용자 | ubuntu |
| 배포 경로 | `/home/ubuntu/app` |
| 필요 정보 | SSH private key, 보안그룹/방화벽 80/443 허용 |
| 비고 | 운영 배포 시 `app.jar`, `prod.env`, Apple `.p8` 키를 서버에 전송 |

---

## 4. Firebase Cloud Messaging

| 항목 | 내용 |
|------|------|
| 용도 | 모바일 푸시 알림 |
| 프로젝트 ID | `doitdo-c3fcd` |
| 필요 정보 | Firebase service account JSON, Flutter Firebase 설정 파일 |
| Backend 설정 | `FIREBASE_ENABLED`, `FIREBASE_SERVICE_ACCOUNT_PATH`, `FIREBASE_PROJECT_ID` |
| 파일 위치 | 서버 `/home/ubuntu/app/secrets/firebase-service-account.json` |
| Frontend 관련 | `firebase_options.dart`, Android/iOS Firebase 설정 |

---

## 5. Google OAuth

| 항목 | 내용 |
|------|------|
| 용도 | Google 소셜 로그인 |
| 필요 정보 | Google Web Client ID |
| Backend 설정 | `GOOGLE_OAUTH_CLIENT_ID` |
| Frontend 설정 | `GOOGLE_SERVER_CLIENT_ID` |
| 비고 | Frontend와 Backend의 Client ID audience가 일치해야 로그인 검증 가능 |

---

## 6. Kakao Developers

| 항목 | 내용 |
|------|------|
| 용도 | Kakao 소셜 로그인 |
| 필요 정보 | Kakao Native App Key |
| Frontend 설정 | `KAKAO_NATIVE_APP_KEY` |
| 참고 문서 | `S14P31D107/fe/doitdo/docs/KAKAO_SETUP.md` |
| 비고 | Android redirect scheme, iOS URL Scheme 설정 필요 |

---

## 7. Apple Developer

| 항목 | 내용 |
|------|------|
| 용도 | iOS Sign in with Apple, 회원탈퇴 revoke |
| 필요 정보 | Team ID, Key ID, `.p8` private key, Bundle ID |
| Bundle ID | `com.d107.doitdo` |
| Backend 설정 | `APPLE_OAUTH_CLIENT_ID`, `APPLE_SIGNIN_TEAM_ID`, `APPLE_SIGNIN_KEY_ID`, `APPLE_SIGNIN_KEY_PATH`, `APPLE_SIGNIN_CLIENT_ID` |
| Jenkins Credential | `apple-signin-key.p8` |
| 참고 문서 | `S14P31D107/fe/doitdo/docs/APPLE_SIGN_IN_SETUP.md` |

---

## 8. Gmail SMTP

| 항목 | 내용 |
|------|------|
| 용도 | 비밀번호 재설정 OTP 메일 발송 |
| SMTP Host | `smtp.gmail.com` |
| SMTP Port | `587` |
| 필요 정보 | Gmail 계정, Gmail 앱 비밀번호 |
| Backend 설정 | `MAIL_HOST`, `MAIL_PORT`, `MAIL_USERNAME`, `MAIL_PASSWORD`, `MAIL_FROM_ADDRESS`, `MAIL_FROM_NAME` |
| 비고 | Gmail 2단계 인증 활성화 후 앱 비밀번호 발급 필요 |

---

## 9. 도메인/DNS/SSL

| 항목 | 내용 |
|------|------|
| 용도 | 운영 API 도메인 및 HTTPS |
| 운영 API | https://api.doitdo.site |
| 앱 API 설정 | `API_BASE_URL=https://api.doitdo.site` |
| Backend CORS | `https://doitdo.site`, `https://*.doitdo.site` |
| 필요 정보 | DNS A/CNAME 레코드, SSL 인증서 또는 서버 Nginx TLS 설정 |

---

## 10. MariaDB

| 항목 | 내용 |
|------|------|
| 용도 | 서비스 운영 DB |
| 버전 | MariaDB 11 |
| DB명 | `doitdo_prod` |
| 필요 정보 | DB 사용자명, DB 비밀번호 |
| 설정 위치 | `prod.env`, `docker-compose.prod.yml` |
| 비고 | DB 덤프 최신본은 `exec/demo-character-ready.sql` 참조 |

---

## 11. Redis

| 항목 | 내용 |
|------|------|
| 용도 | Cache, Redis 기반 기능 |
| 버전 | redis:7-alpine |
| Backend 설정 | `REDIS_HOST`, `REDIS_PORT`, `SPRING_DATA_REDIS_HOST`, `SPRING_DATA_REDIS_PORT` |
| 비고 | Docker Compose 내부 네트워크에서 `redis:6379`로 접근 |

