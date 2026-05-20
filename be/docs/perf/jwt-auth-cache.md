# JWT auth user cache performance log

## Goal

Reduce the database cost of the JWT authentication path. Before this work, every protected request with a valid access token called `CustomUserDetailsService.loadUserById()` and executed one `users` table select.

This experiment compares:

| Mode | Config |
| --- | --- |
| Baseline/current behavior | `AUTH_USER_CACHE_PROVIDER=none` |
| Redis cache | `AUTH_USER_CACHE_PROVIDER=redis` |
| Caffeine local cache | `AUTH_USER_CACHE_PROVIDER=caffeine` |

TTL is fixed at 60 seconds for Redis and Caffeine.

## Selection rule

1. The selected provider must reduce authentication-path `users` selects by at least 90%.
2. Pick the provider with the best k6 p95/p99.
3. If Redis and Caffeine p99 differ by 5% or less, prefer the option with lower operational complexity for this service.

## Scenario

Use a valid access token for an onboarding-incomplete user and call:

```text
GET /api/users/me/password
```

Expected status is `403`. This endpoint/path is useful for isolating the JWT filter because `OnboardingRequiredFilter` stops the request before controller business logic runs.

## Run commands

From `be/`:

```powershell
$env:SPRING_PROFILES_ACTIVE = "dev,perf"
$env:AUTH_USER_CACHE_PROVIDER = "none"
./gradlew bootRun
```

In another terminal:

```powershell
$env:BASE_URL = "http://localhost:8080"
$env:ACCESS_TOKEN = "<valid access token>"
$env:EXPECTED_STATUS = "403"
New-Item -ItemType Directory -Force build/perf
./perf/bin/k6.exe run --summary-export=build/perf/jwt-auth-cache-none.json scripts/perf/jwt-auth-cache.k6.js
```

Repeat the same run with:

```powershell
$env:AUTH_USER_CACHE_PROVIDER = "redis"
```

and:

```powershell
$env:AUTH_USER_CACHE_PROVIDER = "caffeine"
```

## Measured result

Measured on 2026-05-15 with local Spring Boot, dev DB/Redis, and the onboarding-incomplete user scenario above. Each provider was measured 3 times with the same k6 stages. The `none` mode is the baseline that preserves the pre-cache behavior.

| Provider | Avg requests | Avg users SELECT | SELECT reduction | Avg p50 | Avg p95 | Avg p99 | Decision |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| none | 9,980 | 9,984.33 | 0% | 85.92 ms | 368.08 ms | 615.86 ms | Baseline |
| redis | 11,097 | 17.67 | 99.82% | 19.75 ms | 28.34 ms | 37.75 ms | Valid comparison option |
| caffeine | 11,311 | 6.00 | 99.94% | 1.61 ms | 2.65 ms | 3.77 ms | Selected |

Per-run raw values:

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

`none` run 3 exited with code 99 because the configured p95 threshold (`p95 < 500 ms`) was crossed. The HTTP checks still all passed and `http_req_failed` was 0%, so the run is included as valid latency data.

Hikari active/pending max was not sampled in this local run. No Hikari pending/acquire errors appeared in the server logs. If a portfolio screenshot requires pool saturation data, run the same scenario with a small Prometheus sampler during k6 execution.

## Selection

Caffeine is selected as the default provider.

- Both Redis and Caffeine reduced authentication-path `users` SELECTs by more than 90%.
- Caffeine had the best latency: p95 improved from 368.08 ms to 2.65 ms, and p99 improved from 615.86 ms to 3.77 ms.
- Redis was also effective, but it still paid network and serialization cost on every cache hit. Caffeine kept the auth snapshot in process memory and was about 10x faster than Redis on p99 in this local/dev topology.
- Redis remains available as a config option for future multi-instance deployments.

Final default:

```yaml
auth:
  user-cache:
    provider: ${AUTH_USER_CACHE_PROVIDER:caffeine}
```

## Portfolio narrative

Context: JWT was stateless, but the server still queried `users` on every protected request to rebuild `CustomUserDetails`.

Diagnosis: Hibernate statistics and SQL logs showed one `users` select per authenticated request.

Solution: Introduced an auth-only user snapshot cache with `none`, `redis`, and `caffeine` providers. User state changes evict the auth cache after commit.

Verification: Under the same k6 scenario, Caffeine reduced auth-path `users` selects by 99.94%, p95 by 99.28%, and p99 by 99.39% compared with `none`.

Trade-off: Cached auth snapshots may be stale for up to 60 seconds for fields that do not explicitly evict. Security-sensitive changes such as password changes, withdrawal, and onboarding state changes evict immediately after commit.
