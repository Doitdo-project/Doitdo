# JWT 인증 사용자 캐시 성능 개선

## 1. 목표

JWT 기반 인증은 stateless 구조지만, 기존 구현에서는 보호 API 요청마다 `JwtAuthenticationFilter`가 `CustomUserDetailsService.loadUserById()`를 호출했고, 그때마다 `users` 테이블을 조회했다.

이번 작업의 목표는 인증 경로에서 반복되는 `users` SELECT 비용을 줄이고, `none`, `redis`, `caffeine` 3가지 방식을 같은 조건에서 측정한 뒤 수치상 가장 좋은 방식을 최종 채택하는 것이다.

## 2. 비교 대상

| 모드 | 설정값 | 의미 |
| --- | --- | --- |
| 기존 방식 | `AUTH_USER_CACHE_PROVIDER=none` | 매 요청마다 DB에서 사용자 조회 |
| Redis 캐시 | `AUTH_USER_CACHE_PROVIDER=redis` | Redis에 인증 사용자 snapshot 저장 |
| Caffeine 캐시 | `AUTH_USER_CACHE_PROVIDER=caffeine` | 애플리케이션 로컬 메모리에 인증 사용자 snapshot 저장 |

Redis와 Caffeine의 TTL은 모두 60초로 맞췄다.

## 3. 선택 기준

1. 인증 경로의 `users` SELECT 감소율이 90% 이상이어야 한다.
2. k6 측정 결과에서 p95, p99가 가장 낮은 provider를 우선 선택한다.
3. Redis와 Caffeine의 p99 차이가 5% 이내라면 운영 복잡도가 낮은 쪽을 선택한다.

## 4. 측정 시나리오

온보딩 미완료 사용자의 access token으로 다음 엔드포인트를 호출했다.

```text
GET /api/users/me/password
```

이 요청은 실제 컨트롤러 비즈니스 로직까지 가지 않고, `OnboardingRequiredFilter`에서 403으로 차단된다. 따라서 컨트롤러 로직보다 JWT 인증 필터와 인증 사용자 조회 비용을 상대적으로 잘 고립해서 볼 수 있다.

예상 응답은 `403`이며, k6에서는 이를 정상 응답으로 처리했다.

## 5. 실행 방법

백엔드 실행:

```powershell
$env:SPRING_PROFILES_ACTIVE = "dev,perf"
$env:AUTH_USER_CACHE_PROVIDER = "none"
./gradlew bootRun
```

부하 테스트 실행:

```powershell
$env:BASE_URL = "http://localhost:8080"
$env:ACCESS_TOKEN = "<valid access token>"
$env:EXPECTED_STATUS = "403"
New-Item -ItemType Directory -Force build/perf
./perf/bin/k6.exe run --summary-export=build/perf/jwt-auth-cache-none.json scripts/perf/jwt-auth-cache.k6.js
```

같은 방식으로 provider만 바꿔서 반복 측정했다.

```powershell
$env:AUTH_USER_CACHE_PROVIDER = "redis"
```

```powershell
$env:AUTH_USER_CACHE_PROVIDER = "caffeine"
```

## 6. 측정 결과

측정일: 2026-05-15

측정 환경:

- 로컬 Spring Boot 서버
- dev DB/Redis 사용
- 온보딩 미완료 사용자 토큰 사용
- k6 동일 시나리오를 provider별 3회 실행
- `none` 모드는 기존 동작을 재현하는 baseline으로 사용

| Provider | 평균 요청 수 | 평균 users SELECT | SELECT 감소율 | 평균 p50 | 평균 p95 | 평균 p99 | 판단 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| none | 9,980 | 9,984.33 | 0% | 85.92 ms | 368.08 ms | 615.86 ms | 기존 방식 |
| redis | 11,097 | 17.67 | 99.82% | 19.75 ms | 28.34 ms | 37.75 ms | 유효한 개선안 |
| caffeine | 11,311 | 6.00 | 99.94% | 1.61 ms | 2.65 ms | 3.77 ms | 최종 채택 |

## 7. 원자료

| Provider | Run | Exit | Requests | users SELECT | p50 | p95 | p99 | Failed rate |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| none | 1 | 0 | 10,069 | 10,073 | 91.78 ms | 305.36 ms | 475.71 ms | 0% |
| none | 2 | 0 | 10,228 | 10,232 | 77.48 ms | 253.42 ms | 441.06 ms | 0% |
| none | 3 | 99 | 9,644 | 9,648 | 88.51 ms | 545.45 ms | 930.81 ms | 0% |
| redis | 1 | 0 | 11,101 | 25 | 19.32 ms | 28.20 ms | 40.31 ms | 0% |
| redis | 2 | 0 | 11,088 | 14 | 20.40 ms | 30.10 ms | 39.75 ms | 0% |
| redis | 3 | 0 | 11,103 | 14 | 19.52 ms | 26.71 ms | 33.18 ms | 0% |
| caffeine | 1 | 0 | 11,309 | 6 | 1.73 ms | 2.87 ms | 4.77 ms | 0% |
| caffeine | 2 | 0 | 11,312 | 6 | 1.67 ms | 2.54 ms | 3.26 ms | 0% |
| caffeine | 3 | 0 | 11,311 | 6 | 1.42 ms | 2.55 ms | 3.28 ms | 0% |

`none` 3회차의 exit code가 99인 이유는 k6 threshold인 `p95 < 500 ms`를 초과했기 때문이다. HTTP check는 모두 성공했고, `http_req_failed`도 0%였으므로 지연 시간 비교 데이터로는 유효하게 포함했다.

## 8. 최종 선택

최종 provider는 Caffeine으로 선택했다.

근거:

- Redis와 Caffeine 모두 인증 경로의 `users` SELECT를 90% 이상 줄였다.
- Caffeine은 SELECT 감소율이 99.94%로 가장 높았다.
- Caffeine은 평균 p95를 368.08 ms에서 2.65 ms로 줄였다.
- Caffeine은 평균 p99를 615.86 ms에서 3.77 ms로 줄였다.
- Redis도 효과적이지만, cache hit마다 네트워크 왕복과 JSON 직렬화/역직렬화 비용이 남았다.
- 현재 단일 인스턴스 또는 포트폴리오 측정 환경에서는 로컬 메모리 캐시인 Caffeine이 더 적합하다.
- Redis provider는 추후 멀티 인스턴스 운영 환경을 위한 선택지로 유지한다.

최종 기본 설정:

```yaml
auth:
  user-cache:
    provider: ${AUTH_USER_CACHE_PROVIDER:caffeine}
```

## 9. 구현 요약

기존에는 `CustomUserDetailsService.loadUserById()`가 직접 `UserRepository.findById()`를 호출했다.

개선 후에는 다음 구조로 분리했다.

```text
JwtAuthenticationFilter
  -> CustomUserDetailsService.loadUserById()
  -> AuthUserCacheService
  -> AuthUserCacheProvider
     - none
     - redis
     - caffeine
```

캐시에 저장하는 값은 JPA 엔티티 자체가 아니라 인증에 필요한 최소 snapshot이다.

snapshot 필드:

- `userId`
- `username`
- `password`
- `isDeleted`
- `birthDate`
- `termsAgreedAt`
- `privacyAgreedAt`
- `termsVersion`

`CustomUserDetails` 타입은 유지해서 기존 `@AuthenticationPrincipal CustomUserDetails`와 `OnboardingRequiredFilter` 호환성을 깨지 않도록 했다.

## 10. 캐시 무효화

인증 사용자 snapshot이 stale 상태로 남으면 보안 또는 온보딩 흐름에 문제가 생길 수 있다. 따라서 사용자 상태가 바뀌는 경로에서는 트랜잭션 커밋 이후 캐시를 evict한다.

evict 대상:

- 비밀번호 변경
- 회원탈퇴
- 생년월일 등록
- 약관 동의 등록
- 미성년자 hard delete

트랜잭션이 rollback된 경우 캐시만 먼저 삭제되는 상황을 피하기 위해 `AuthUserCacheEvictHelper.evictAfterCommit()`에서 after-commit hook으로 처리했다.

## 11. 검증

테스트:

- snapshot에서 `CustomUserDetails` 변환 시 보안/온보딩 필드 유지 검증
- `provider=none`에서 동일 사용자 2회 조회 시 DB 조회가 반복되는지 검증
- `provider=caffeine`에서 두 번째 조회 시 DB 조회가 발생하지 않는지 검증
- `provider=redis`에서 두 번째 조회 시 DB 조회가 발생하지 않는지 검증
- 탈퇴 후 evict되어 cached token이 삭제 사용자 상태를 stale하게 보지 않는지 검증
- 생년월일/약관 등록 후 evict되어 온보딩 필터가 stale 상태를 보지 않는지 검증

실행 결과:

```text
./gradlew.bat test
BUILD SUCCESSFUL
```

## 12. 한계와 추가 보강

이번 측정에서는 Hikari active/pending max를 별도로 샘플링하지 않았다. 서버 로그상 Hikari pending 또는 acquire timeout 문제는 없었지만, 포트폴리오에서 DB pool 지표까지 보여주려면 Prometheus/Grafana 또는 별도 sampler를 붙여 같은 시나리오를 한 번 더 측정하면 좋다.

## 13. 포트폴리오용 요약

JWT는 stateless 인증 방식이지만 기존 서버는 보호 API 요청마다 `users` 테이블을 조회해 `CustomUserDetails`를 재구성하고 있었다. Hibernate SQL 로그와 k6 부하 테스트로 요청당 1회 사용자 조회가 발생함을 확인했고, `none`, `redis`, `caffeine` 3가지 방식을 같은 조건에서 비교했다.

측정 결과 Caffeine은 인증 경로의 `users` SELECT를 99.94% 줄였고, p95는 368.08 ms에서 2.65 ms로, p99는 615.86 ms에서 3.77 ms로 개선했다. 사용자 상태 변경 시 after-commit 기반 evict를 적용해 비밀번호 변경, 회원탈퇴, 온보딩 상태 변경에서 stale snapshot이 남지 않도록 했다.
