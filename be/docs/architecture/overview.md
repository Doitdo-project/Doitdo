# 시스템 개요 (overview)

## 한 줄 정리

doitdo 백엔드는 **Spring Boot 3.5.x / Java 21 / JPA / MariaDB** 기반의 단일 모놀리스 서버이며, 도메인 단위로 격리된 패키지 구조를 따른다.

## 스택

| 영역 | 사양 |
|---|---|
| 언어 | Java 21 |
| 프레임워크 | Spring Boot 3.5.13, Spring Security, Spring Data JPA |
| API 문서 | springdoc-openapi 2.7.0 (`dev` / `local` 한정) |
| 빌드 | Gradle (Wrapper 포함) |
| DB | MariaDB |
| 인증 | JWT (BearerAuth) |

## 진입점

- 메인 클래스: `com.doitdo.DoitdoApplication`
- 베이스 패키지: `com.doitdo`

## 패키지 계층 (개념)

```
com.doitdo
 ├ DoitdoApplication        # @SpringBootApplication
 ├ domain/{도메인}           # 비즈니스 (auth, user, todo, tamagotchi, …)
 │   ├ api/                  # Controller + DTO
 │   ├ application/          # Service 인터페이스 + Impl
 │   ├ entity/               # JPA Entity
 │   └ repository/           # Spring Data JPA Repository
 └ global/                   # 공통 인프라
     ├ config/               # Security / OpenAPI / JpaAuditing
     ├ entity/               # BaseTimeEntity
     ├ exception/            # ErrorCode + GlobalExceptionHandler
     ├ swagger/              # @ApiErrorCodes + Customizer (be/feat/swagger 머지 후)
     ├ api/response/         # GlobalApiResponse<T>
     ├ util/                 # JwtUtil 등
     └ health/               # HealthController
```

상세 디렉토리 규약은 [`package-layout.md`](package-layout.md).

## 계층 책임

| 계층 | 책임 | 의존 방향 |
|---|---|---|
| `api/controller` | HTTP 입출력 매핑, 검증, 응답 포맷 | → application |
| `api/dto/{req,resp}` | 요청/응답 DTO | (계층 간 데이터 운반체) |
| `application/{Domain}Service` | 트랜잭션 경계, 유스케이스 | → repository, 다른 도메인은 Service 통해서만 |
| `application/impl/{Domain}ServiceImpl` | Service 구현 | → repository |
| `entity/{Domain}` | JPA Entity, 도메인 모델 | (자기 도메인 안에서만) |
| `repository/{Domain}Repository` | Spring Data JPA | → entity |
| `global/*` | 공통 인프라/유틸 | (어디서나 의존 가능) |

## 도메인 격리 원칙

- 도메인 간 직접 엔티티 참조 금지. FK는 **Long ID 필드**로만 보관 (`@ManyToOne` 미사용 원칙).
- 도메인 간 협력은 Service → Service 호출로.

## 응답/에러 표준

- 모든 응답: `GlobalApiResponse<T>` ([`../api/response-format.md`](../api/response-format.md))
- 에러 코드: 9개 도메인 enum + `ErrorCodeRegistry` 인덱스 ([`../api/error-codes.md`](../api/error-codes.md))
- 컨트롤러 작성: [`../api/swagger.md`](../api/swagger.md)

## 데이터 모델

- ERD 원본/도메인 매핑: [`erd.md`](erd.md)

## 환경/실행

- 로컬 부팅: [`../ops/run-local.md`](../ops/run-local.md)
- env 셋업: [`../ops/env-setup.md`](../ops/env-setup.md)
