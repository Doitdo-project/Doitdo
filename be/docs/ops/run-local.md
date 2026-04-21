# 로컬 실행 (run-local)

## 사전 조건

- JDK 21 + `env/dev.env` 준비 완료 ([env-setup.md](env-setup.md))
- dev DB 접근 가능 (원격 `168.107.48.80`)

## 부팅

`be/` 디렉토리에서:

```bash
JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 \
  PATH=$JAVA_HOME/bin:$PATH \
  ./gradlew bootRun --args='--spring.profiles.active=dev'
```

기본 포트는 `8080`.

## 헬스체크

```bash
curl http://localhost:8080/hello       # 서비스명 + 활성 프로파일
curl http://localhost:8080/db-check    # DB SELECT 1 실행
```

응답 형식은 [`../api/response-format.md`](../api/response-format.md) 의 `GlobalApiResponse<T>`.

## Swagger UI

`dev` / `local` 프로파일에서만 활성화된다.

- UI: <http://localhost:8080/swagger-ui.html>
- OpenAPI 문서: <http://localhost:8080/v3/api-docs>
- 그룹별 OpenAPI 문서: <http://localhost:8080/v3/api-docs/{group}> (예: `auth`, `todo`, …)

작성 가이드: [`../api/swagger.md`](../api/swagger.md).

## 활성 프로파일

| 프로파일 | DB | Swagger | 비고 |
|---|---|---|---|
| `dev` | 원격 테스트 DB | 활성 | 팀 공용 |
| `local` | 개인 설정 | 활성 | 본인 환경 |
| 그 외 | - | 비활성 | 운영 보안 |

## 자주 만나는 문제

- 부팅 즉시 `Failed to determine a suitable driver class` → `env/dev.env` 누락 또는 경로 오타.
- 부팅 즉시 `Communications link failure` → DB 호스트 도달 불가 (VPN/방화벽).
- `/swagger-ui.html` 404 → 활성 프로파일이 `dev` / `local` 이 아님.
