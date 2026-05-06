# Redis 캐싱

## 범위

홈 화면의 반복 조회 비용을 줄이기 위해 TODO 목록, TODO 단건, 현재 다마고치, 카테고리 목록을 Redis cache로 저장한다. Mutation은 트랜잭션 커밋 이후 사용자 단위로 evict해 stale data 노출을 막는다.

## Cache Names

| Cache name | Key | TTL |
|---|---|---|
| `todos:list` | `{userId}:{view}:{type}:{status}:{category}:{sort}:{qHash}:{effectiveDate}` | 1h |
| `todos:item` | `{userId}:{todoId}` | 5min |
| `tamagotchi:current` | `{userId}` | 30min |
| `categories` | `{userId}` | 1h |

Redis key prefix는 cache name 기준으로 붙는다. 예: `todos:list::123:today:X:X:X:X:X:2026-05-04`.

TODO 목록 키에는 요청 `date`가 있으면 그 날짜, 없으면 Asia/Seoul 기준 오늘이 포함된다. 자정 이후에는 새 날짜 키가 생성되므로 SOMEDAY DONE 자동 만료 정책은 별도 전역 evict 없이 새 조회에서 자연 반영된다. 이전 날짜 키는 TTL 뒤 만료된다.

## Serialization

- Key: `StringRedisSerializer`
- Value: `GenericJackson2JsonRedisSerializer`
- Java time: `JavaTimeModule`
- Null caching: disabled
- Prefix: `cacheName::`

## Evict

사용자 간 cache 격리를 위해 `@CacheEvict(allEntries = true)`는 사용하지 않는다. `CacheEvictHelper`가 `StringRedisTemplate`의 SCAN으로 사용자 prefix만 삭제한다.

| Mutation | Evict |
|---|---|
| TODO create | `todos:list::{userId}:*` |
| TODO update/delete/changePriority/snooze | `todos:list::{userId}:*`, `todos:item::{userId}:{todoId}` |
| TODO changeStatus | TODO evict + `tamagotchi:current::{userId}` |
| Category create/update/delete | `categories::{userId}`, `todos:list::{userId}:*` |
| Tamagotchi updateName/hatch/evolve/farewell | `tamagotchi:current::{userId}` |
| RecurrenceMaterializeScheduler | created instance owners' `todos:list::{userId}:*` |
| TodoCompletionExpListener | `tamagotchi:current::{userId}` after EXP commit |

Mutation 서비스는 `TransactionSynchronizationManager`로 AFTER_COMMIT evict를 예약한다. 커밋 전에 cache miss가 발생해 미커밋 DB 상태를 다시 캐싱하는 상황을 피하기 위한 규칙이다.

## 운영 점검

개발 환경에서 키를 빠르게 볼 때:

```bash
redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" KEYS 'todos:*'
redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" TTL 'todos:list::123:today:X:X:X:X:X:2026-05-04'
```

운영에서 대량 키 확인은 `KEYS` 대신 `SCAN`을 사용한다.

```bash
redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" --scan --pattern 'todos:list::123:*'
```
