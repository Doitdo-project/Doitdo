# 배포 (deployment)

> **상태: placeholder.** INFRA 팀 자료 정리 후 본 문서를 채운다.

## 결정 대기 항목

- 배포 파이프라인 (GitLab CI / GitHub Actions / 수동)
- 운영 프로파일 (`prod`) 의 DDL 정책 — `validate` vs Flyway/Liquibase 도입
- 시크릿 주입 방식 (`env/prod.env` vs Vault/Parameter Store)
- 환경별 도메인/엔드포인트 매핑

## 임시 가이드

- 운영 빌드: `./gradlew clean build` 산출물 `be/build/libs/*.jar`
- 운영 실행: `java -jar -Dspring.profiles.active=prod *.jar` (env 외부 주입 필요)
- 운영에서 Swagger UI 는 비활성 ([`OpenApiConfig`](../../src/main/java/com/doitdo/global/config/OpenApiConfig.java) 가 `dev` / `local` 프로파일에서만 등록)

INFRA 담당자가 정리되는 대로 위 항목을 본 문서로 옮긴다.
